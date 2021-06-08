#' OAuth authentication
#'
#' This is a low-level helper for automatically authenticating a request with
#' an OAuth flow, caching the access token and refreshing it where possible.
#' You should only need to use this function if you're implementing your own
#' OAuth flow.
#'
#' @inheritParams req_fetch
#' @param cache An object that controls how the token is cached. This should
#'   be a list containing three functions:
#'   * `get()` retrieves the token from the cache, returning `NULL` if not
#'     cached yet.
#'   * `set()` saves the token to the cache.
#'   * `clear()` removes the token from the cache
#' @param flow Function used to generate the access token.
#' @param flow_params List of parameters to call `flow` with.
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

  cache <- req$policies$auth_oauth$cache
  flow <- req$policies$auth_oauth$flow
  flow_params <- req$policies$auth_oauth$flow_params

  token <- cache$get()
  if (reauth || is.null(token)) {
    token <- exec(flow, !!!flow_params)
  } else {
    if (token_has_expired(token)) {
      cache$clear()
      if (is.null(token$refresh_token)) {
        token <- exec(flow, !!!flow_params)
      } else {
        token <- token_refresh(flow$params$app, token)
      }
    }
  }
  cache$set(token)
  req_auth_bearer_token(req, token$access_token)
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

cache_choose <- function(app, cache_disk = FALSE, cache_key = NULL) {
  if (cache_disk) {
    cache_disk(app, cache_key)
  } else {
    cache_mem(app, cache_key)
  }
}

cache_mem <- function(app, key) {
  key <- hash(c(oauth_app_name(app), key))
  list(
    get = function() env_get(the$token_cache, key, default = NULL),
    set = function(token) env_poke(the$token_cache, key, token),
    clear = function() env_unbind(the$token_cache, key)
  )
}
cache_disk <- function(app, key) {
  app_path <- file.path(rappdirs::user_cache_dir("httr2"), oauth_app_name(app))
  dir.create(app_path, showWarnings = FALSE, recursive = TRUE)

  path <- file.path(app_path, paste0(hash(key), ".rds"))
  list(
    get = function() if (file.exists(path)) readRDS(path) else NULL,
    set = function(token) saveRDS(token, path),
    clear = function() if (file.exists(path)) file.remove(path)
  )
}
