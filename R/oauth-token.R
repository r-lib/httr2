new_token <- function(access_token,
                      token_type = "bearer",
                      expires_in = NULL,
                      refresh_token = NULL,
                      ...,
                      .date = NULL) {

  check_string(access_token, "`access_token`")
  check_string(token_type, "`token_type`")
  # TODO: should tokens always store their scope

  if (!is.null(expires_in) && !is.null(.date)) {
    # Store as unix time to avoid worrying about type coercions in cache
    expires_at <- as.numeric(.date) + expires_in
  } else {
    expires_at <- NULL
  }

  structure(
    compact(list2(
      access_token = access_token,
      token_type = token_type,
      expires_at = expires_at,
      refresh_token = refresh_token,
      ...
    )),
    class = "httr2_token"
  )
}

check_token <- function(x) {
  if (!inherits(x, "httr2_token")) {
    abort("`token` must be an OAuth2 token")
  }
}

token_has_expired <- function(token, delay = 5) {
  if (is.null(token$expires_at)) {
    FALSE
  } else {
    token$expires_at > (unix_time() + delay)
  }
}

token_refresh <- function(token, app, scope = NULL) {
  check_token(token)
  if (is.null(token$refresh_token)) {
    abort("Token must have `$refresh_token` field in order to be refreshed")
  }
  oauth_flow_refresh(app, token$refresh_token, scope = scope)
}


cache_mem <- function(app, key) {
  key <- hash(c(oauth_app_id(app), key))
  list(
    get = function() env_get(the$token_cache, key, default = NULL),
    set = function(token) env_bind(the$token_cache, key, token),
    clear = function() env_unbind(the$token_cache, key)
  )
}
cache_disk <- function(app, key) {
  path <- ouath_token_cache_path(app, key)
  list(
    get = function() if (file.exists(path)) readRDS(path) else NULL,
    set = function(token) saveRDS(path, token),
    clear = function() file.remove(path)
  )
}
