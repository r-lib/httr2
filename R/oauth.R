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
  req_policies(req,
    auth_oauth = list(
      cache = cache,
      flow = flow,
      flow_params = flow_params
    )
  )
}

auth_oauth_sign <- function(req, reauth = FALSE) {
  if (!req_policy_exists(req, "auth_oauth")) {
    return(req)
  }

  token <- auth_oauth_token_get(
    cache = req$policies$auth_oauth$cache,
    flow = req$policies$auth_oauth$flow,
    flow_params = req$policies$auth_oauth$flow_params,
    reauth = reauth
  )

  req_auth_bearer_token(req, token$access_token)
}

auth_oauth_token_get <- function(cache, flow, flow_params = list(), reauth = FALSE) {
  token <- cache$get()
  if (reauth || is.null(token)) {
    token <- exec(flow, !!!flow_params)
    cache$set(token)
  } else if (token_has_expired(token)) {
    cache$clear()
    if (is.null(token$refresh_token)) {
      token <- exec(flow, !!!flow_params)
    } else {
      token <- tryCatch(
        token_refresh(flow_params$client, token$refresh_token),
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
oauth_token_cached <- function(client,
                               flow,
                               flow_params = list(),
                               cache_disk = FALSE,
                               cache_key = NULL,
                               reauth = FALSE) {
  check_bool(reauth)
  cache <- cache_choose(client, cache_disk, cache_key)

  flow_params$client <- client
  auth_oauth_token_get(
    cache = cache,
    flow = flow,
    flow_params = flow_params,
    reauth = reauth
  )
}

resp_is_invalid_oauth_token <- function(req, resp) {
  if (!req_policy_exists(req, "auth_oauth")) {
    return(FALSE)
  }

  if (resp_status(resp) != 401) {
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

cache_mem <- function(client, key = NULL) {
  key <- hash(c(client$name, key))
  list(
    get = function() env_get(the$token_cache, key, default = NULL),
    set = function(token) env_poke(the$token_cache, key, token),
    clear = function() env_unbind(the$token_cache, key)
  )
}
cache_disk <- function(client, key = NULL) {
  app_path <- file.path(oauth_cache_path(), client$name)
  dir.create(app_path, showWarnings = FALSE, recursive = TRUE)

  path <- file.path(app_path, paste0(hash(key), "-token.rds.enc"))
  list(
    get = function() if (file.exists(path)) secret_read_rds(path, obfuscate_key()) else NULL,
    set = function(token) {
      cli::cli_inform("Caching httr2 token in {.path {path}}.")
      secret_write_rds(token, path, obfuscate_key())
    },
    clear = function() if (file.exists(path)) file.remove(path)
  )
}

# Update req_oauth_auth_code() docs if change default from 30
cache_disk_prune <- function(days = 30, path = oauth_cache_path()) {
  files <- dir(path, recursive = TRUE, full.names = TRUE, pattern = "-token\\.rds$")
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
  path <- Sys.getenv("HTTR2_OAUTH_CACHE")
  if (path != "") {
    return(path)
  }

  rappdirs::user_cache_dir("httr2")
}
