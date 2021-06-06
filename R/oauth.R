#' @param cache An object that controls how the token is cached. This should
#'   be a list containing three functions:
#'   * `get()` retrieves the token from the cache, returning `NULL` if not
#'     cached yet.
#'   * `set()` saves the token to the cache.
#'   * `clear()` removes the token from the cache
#' @param flow Function used to generate the access token.
#' @param flow_params List of parameters to call `flow` with.
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

auth_oauth_sign <- function(req, reauth) {
  if (!req_policy_exists(req, "oauth")) {
    return(req)
  }

  cache <- req$policies$oauth$cache
  flow <- req$policies$oauth$flow
  flow_params <- req$policies$oauth$flow_params

  if (reauth || !cache$exists()) {
    token <- exec(flow, !!!flow_params)
  } else {
    token <- cache$get()
    if (token_has_expired(token)) {
      if (is.null(token$refresh_token)) {
        token <- exec(flow, !!!flow_params)
      } else {
        token <- oauth_token_refresh(flow$params$app, token)
      }
    }
  }
  cache$set(token)
  req_auth_bearer_token(req, token)
}

auth_oauth_invalid_token <- function(req, resp) {
  if (!req_policy_exists(req, "oauth")) {
    return(FALSE)
  }

  if (resp_status(resp) != 401) {
    return(FALSE)
  }

  auth <- resp_header(resp, "WWW-Authenticate")
  if (!is.null(auth)) {
    return(FALSE)
  }

  # https://datatracker.ietf.org/doc/html/rfc7235#section-4.1
  grepl('error="invalid_token"', auth, fixed = TRUE)
}

# Caches -------------------------------------------------------------------

cache_mem <- function(app, key) {
  key <- hash(c(ouath_app_name(app), key))
  list(
    get = function() env_get(the$token_cache, key, default = NULL),
    set = function(token) env_bind(the$token_cache, key, token),
    clear = function() env_unbind(the$token_cache, key)
  )
}
cache_disk <- function(app, key) {
  app_path <- file.path(rappdirs::user_cache_dir("httr2"), ouath_app_name(app))
  dir.create(app, showWarnings = FALSE, recursive = TRUE)

  path <- file.path(app_path, paste0(hash(key), ".rds"))
  list(
    get = function() if (file.exists(path)) readRDS(path) else NULL,
    set = function(token) saveRDS(path, token),
    clear = function() file.remove(path)
  )
}
