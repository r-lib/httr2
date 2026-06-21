#' OAuth authentication
#'
#' This is a low-level helper for automatically authenticating a request with
#' an OAuth flow, caching the access token and refreshing it where possible.
#' You should only need to use this function if you're implementing your own
#' OAuth flow.
#'
#' @inheritParams req_perform
#' @param cache An object that controls how the token is cached. This should
#'   be a list containing three functions:
#'   * `get()` retrieves the token from the cache, returning `NULL` if not
#'     cached yet.
#'   * `set()` saves the token to the cache.
#'   * `clear()` removes the token from the cache
#' @param flow An `oauth_flow_` function used to generate the access token.
#' @param flow_params Parameters for the flow. This should be a named list
#'   whose names match the argument names of `flow`.
#' @returns An [oauth_token].
#' @keywords internal
#' @export
req_oauth <- function(req, flow, flow_params, cache) {
  # Want req object to contain meaningful objects, not just a closure
  req <- req_auth_sign(
    req,
    fun = auth_oauth_sign,
    params = list(flow = flow, flow_params = flow_params),
    cache = cache
  )
  req <- req_policies(req, auth_oauth = TRUE)
  req
}

auth_oauth_sign <- function(req, cache, flow, flow_params) {
  token <- auth_oauth_token_get(
    cache = cache,
    flow = flow,
    flow_params = flow_params
  )
  req_auth_bearer_token(req, token$access_token)
}

auth_oauth_token_get <- function(cache, flow, flow_params = list()) {
  token <- cache$get()
  if (is.null(token)) {
    token <- exec(flow, !!!flow_params)
    cache$set(token)
  } else if (token_has_expired(token)) {
    cache$clear()
    if (is.null(token$refresh_token)) {
      token <- exec(flow, !!!flow_params)
    } else {
      token <- tryCatch(
        token_refresh(
          flow_params$client,
          token$refresh_token,
          token_params = flow_params$token_params %||% list()
        ),
        httr2_oauth = function(cnd) {
          # If refresh fails, try to auth from scratch
          exec(flow, !!!flow_params)
        }
      )
    }
    cache$set(token)
  }

  token
}

#' Retrieve an OAuth token using the cache
#'
#' This function wraps around a `oauth_flow_` function to retrieve a token
#' from the cache, or to generate and cache a token if needed. Use this for
#' manual token management that still takes advantage of httr2's caching
#' system. You should only need to use this function if you're passing
#' the token
#'
#' @keywords internal
#' @inheritParams req_oauth
#' @inheritParams req_oauth_auth_code
#' @param reauth Set to `TRUE` to force re-authentication via flow, regardless
#'   of whether or not token is expired.
#' @export
#' @examples
#' \dontrun{
#' token <- oauth_token_cached(
#'   client = example_github_client(),
#'   flow = oauth_flow_auth_code,
#'   flow_params = list(
#'     auth_url = "https://github.com/login/oauth/authorize"
#'   ),
#'   cache_disk = TRUE
#' )
#' token
#' }
oauth_token_cached <- function(
  client,
  flow,
  flow_params = list(),
  cache_disk = FALSE,
  cache_key = NULL,
  reauth = FALSE
) {
  check_bool(reauth)
  cache <- cache_choose(client, cache_disk, cache_key)
  if (reauth) {
    cache$clear()
  }

  flow_params$client <- client
  auth_oauth_token_get(
    cache = cache,
    flow = flow,
    flow_params = flow_params
  )
}

resp_is_invalid_oauth_token <- function(req, resp) {
  if (!req_policy_exists(req, "auth_oauth")) {
    return(FALSE)
  }

  if (is_error(resp) || resp_status(resp) != 401) {
    return(FALSE)
  }

  auth <- resp_header(resp, "WWW-Authenticate")
  if (is.null(auth)) {
    return(FALSE)
  }

  # https://datatracker.ietf.org/doc/html/rfc6750#section-3.1
  # invalid_token:
  #   The access token provided is expired, revoked, malformed, or
  #   invalid for other reasons.  The resource SHOULD respond with
  #   the HTTP 401 (Unauthorized) status code.  The client MAY
  #   request a new access token and retry the protected resource
  #   request.
  grepl('error="invalid_token"', auth, fixed = TRUE)
}

# Caches -------------------------------------------------------------------

cache_choose <- function(client, cache_disk = FALSE, cache_key = NULL) {
  if (cache_disk) {
    cache_disk(client, cache_key)
  } else {
    cache_mem(client, cache_key)
  }
}

# Used for auth endoints that don't have a cache
cache_noop <- function() {
  list(
    get = function() {
      abort("get() was called on cache_noop")
      invisible()
    },
    set = function(token) {
      abort("set() was called on cache_noop")
      invisible()
    },
    clear = function() {}
  )
}
cache_mem <- function(client, key = NULL) {
  key <- hash(c(client$name, key))
  list(
    get = function() env_get(the$token_cache, key, default = NULL),
    set = function(token) env_poke(the$token_cache, key, token),
    clear = function() env_unbind(the$token_cache, key)
  )
}
cache_disk <- function(client, key = NULL) {
  token_path <- file.path(client$name, paste0(hash(key), "-token.rds.enc"))
  modern_path <- file.path(oauth_cache_path(), token_path)
  dir.create(dirname(modern_path), showWarnings = FALSE, recursive = TRUE)

  # Read from legacy path, but never write to it
  legacy_path <- file.path(oauth_cache_path_legacy(), token_path)
  has_legacy_token <-
    !oauth_cache_is_manual() &&
    !file.exists(modern_path) &&
    file.exists(legacy_path)
  read_path <- if (has_legacy_token) legacy_path else modern_path

  list(
    get = function() {
      if (file.exists(read_path)) {
        secret_read_rds(read_path, obfuscate_key())
      } else {
        NULL
      }
    },
    set = function(token) {
      cli::cli_inform("Caching httr2 token in {.path {modern_path}}.")
      secret_write_rds(token, modern_path, obfuscate_key())

      # Migrate a legacy token by deleting the old copy
      if (has_legacy_token) {
        unlink(read_path)
        has_legacy_token <<- FALSE
        read_path <<- modern_path
      }
    },
    clear = function() unlink(unique(c(modern_path, read_path)))
  )
}

# Update req_oauth_auth_code() docs if change default from 30
cache_disk_prune <- function(days = 30, paths = oauth_cache_paths()) {
  files <- dir(
    paths,
    recursive = TRUE,
    full.names = TRUE,
    pattern = "-token\\.rds$"
  )
  mtime <- file.mtime(files)

  old <- mtime < (Sys.time() - days * 86400)
  unlink(files[old])
}

#' httr2 OAuth cache location
#'
#' When opted-in to, httr2 caches OAuth tokens in this directory. By default,
#' it uses a OS-standard cache directory, but, if needed, you can override the
#' location by setting the `HTTR2_OAUTH_CACHE` env var.
#'
#' @export
oauth_cache_path <- function() {
  if (oauth_cache_is_manual()) {
    oauth_cache_path_manual()
  } else {
    oauth_cache_path_modern()
  }
}
oauth_cache_is_manual <- function() {
  nzchar(Sys.getenv("HTTR2_OAUTH_CACHE"))
}

oauth_cache_path_manual <- function() {
  Sys.getenv("HTTR2_OAUTH_CACHE")
}
oauth_cache_path_modern <- function() {
  tools::R_user_dir("httr2", which = "cache")
}
# Equivalent to rappdirs::user_cache_dir("httr2"), inlined so httr2 doesn't
# depend on rappdirs solely to find tokens cached by older versions. The
# appname is nested twice and gains a "Cache" subdir on Windows because that's
# what rappdirs did with its default `appauthor` and `opinion` arguments.
oauth_cache_path_legacy <- function() {
  if (.Platform$OS.type == "windows") {
    base <- Sys.getenv("LOCALAPPDATA", Sys.getenv("APPDATA"))
    file.path(base, "httr2", "httr2", "Cache")
  } else if (Sys.info()[["sysname"]] == "Darwin") {
    "~/Library/Caches/httr2"
  } else {
    file.path(Sys.getenv("XDG_CACHE_HOME", "~/.cache"), "httr2")
  }
}

# All locations that might contain cached tokens, newest first. The legacy
# location is dropped when the user sets an explicit path, which has no legacy.
oauth_cache_paths <- function() {
  if (oauth_cache_is_manual()) {
    oauth_cache_path_manual()
  } else {
    c(oauth_cache_path_modern(), oauth_cache_path_legacy())
  }
}


#' Clear OAuth cache
#'
#' Use this function to clear cached credentials.
#'
#' @export
#' @inheritParams req_oauth_auth_code
oauth_cache_clear <- function(client, cache_disk = FALSE, cache_key = NULL) {
  cache <- cache_choose(client, cache_disk, cache_key)
  cache$clear()
  invisible()
}
