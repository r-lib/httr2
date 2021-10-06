#' Automatically cache requests
#'
#' @description
#' Use `req_perform()` to automatically cache HTTP requests. Most API requests
#' are not cacheable, but when possible (often when downloading larger files)
#' it can make a big difference. `req_cache()` caches responses to GET requests
#' that have status code 200 and at least one of the standard caching headers
#' (e.g. `Expires`, `Etag`, `Last-Modified`, `Cache-Control`), unless caching
#' has been expressly prohibited with `Cache-Control: no-store`. Typically,
#' a request will still be sent to the server to check that the cached value
#' is still up-to-date, but it will not need to re-download the body value.
#'
#' To learn more about HTTP caching, I recommend the MDN article
#' [HTTP caching](https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching).
#'
#' @inheritParams req_perform
#' @param path Path to cache directory
#' @param use_on_error If the request errors, and there's a cache response,
#'   should `req_perform()` return that instead of generating an error?
#' @param debug When `TRUE` will emit useful messages telling you about
#'   cache hits and misses. This can be helpful to understand whether or
#'   not caching is actually doing anything for your use case.
#' @export
req_cache <- function(req, path, use_on_error = FALSE, debug = FALSE) {
  dir.create(path, showWarnings = FALSE, recursive = TRUE)
  req_policies(req,
    cache_path = path,
    cache_use_on_error = use_on_error,
    cache_debug = debug
  )
}

# Do I need to worry about hash collisions?
# No - even if the user stores a billion urls, the probably of a collision
# is ~ 1e-20: https://preshing.com/20110504/hash-collision-probabilities/
cache_path <- function(req, ext = ".rds") {
  file.path(req$policies$cache_path, paste0(hash(req$url), ext))
}
cache_use_on_error <- function(req) {
  req$policies$cache_use_on_error %||% FALSE
}
cache_debug <- function(req) {
  req$policies$cache_debug %||% FALSE
}

# Cache management --------------------------------------------------------

cache_exists <- function(req) {
  if (!req_policy_exists(req, "cache_path")) {
    FALSE
  } else {
    file.exists(cache_path(req))
  }
}

# Callers responsibility to check that cache exists
cache_get <- function(req) {
  path <- cache_path(req)

  touch(path)
  readRDS(path)
}

cache_set <- function(req, resp) {
  if (is_path(resp$body)) {
    body_path <- cache_path(req, ".body")
    file.copy(resp$body, body_path, overwrite = TRUE)
    resp$body <- new_path(body_path)
  }

  saveRDS(resp, cache_path(req, ".rds"))
  invisible()
}

# Hooks for req_perform -----------------------------------------------------

# Can return request or response
cache_pre_fetch <- function(req) {
  if (!cache_exists(req)) {
    return(req)
  }
  debug <- cache_debug(req)

  info <- resp_cache_info(cache_get(req))
  if (debug) cli::cli_text("Found url in cache {.val {hash(req$url)}}")

  if (!is.na(info$expires) && info$expires >= Sys.time()) {
    signal("", "httr2_cache_cached")
    if (debug) cli::cli_text("Cached value is fresh; retrieving response from cache")
    cache_get(req)
  } else {
    if (debug) cli::cli_text("Cached value is stale; checking for updates")
    req_headers(req,
      `If-Modified-Since` = info$last_modified,
      `If-None-Match` = info$etag
    )
  }
}

cache_post_fetch <- function(req, resp, path = NULL) {
  if (!req_policy_exists(req, "cache_path")) {
    return(resp)
  }
  debug <- cache_debug(req)

  if (is_error(resp)) {
    if (cache_use_on_error(req) && cache_exists(req)) {
      if (debug) cli::cli_text("Request errored; retrieving response from cache")
      cache_get(req)
    } else {
      resp
    }
  } else if (resp_status(resp) == 304 && cache_exists(req)) {
    signal("", "httr2_cache_not_modified")
    if (debug) cli::cli_text("Cached value still ok; retrieving body from cache")

    # Replace body with cached result
    resp$body <- cache_body(req, path)
    resp
  } else if (resp_is_cacheable(resp)) {
    if (debug) cli::cli_text("Saving response to cache {.val {hash(req$url)}}")
    cache_set(req, resp)
    resp
  } else {
    resp
  }
}

cache_body <- function(req, path = NULL) {
  body <- cache_get(req)$body
  if (is.null(path)) {
    return(body)
  }

  if (is_path(body)) {
    file.copy(body, path, overwrite = TRUE)
  } else {
    writeBin(body, path)
  }
  new_path(path)
}

# Caching headers ---------------------------------------------------------

resp_is_cacheable <- function(resp, control = NULL) {
  if (resp$method != "GET") {
    return(FALSE)
  }

  if (resp_status(resp) != 200L) {
    return(FALSE)
  }

  control <- control %||% resp_cache_control(resp)
  if ("no-store" %in% control$flags) {
    return(FALSE)
  }
  if (has_name(control, "max-age")) {
    return(TRUE)
  }

  if (!any(resp_header_exists(resp, c("Etag", "Last-Modified", "Expires")))) {
    return(FALSE)
  }

  TRUE
}

resp_cache_info <- function(resp, control = NULL) {
  list(
    expires = resp_cache_expires(resp, control),
    last_modified = resp_header(resp, "Last-Modified"),
    etag = resp_header(resp, "Etag")
  )
}

resp_cache_expires <- function(resp, control = NULL) {
  control <- control %||% resp_cache_control(resp)

  # Prefer max-age parameter if it exists, otherwise use Expires header
  if (has_name(control, "max-age") && resp_header_exists(resp, "Date")) {
    resp_date(resp) + as.integer(control[["max-age"]])
  } else if (resp_header_exists(resp, "Expires")) {
    parse_http_date(resp_header(resp, "Expires"))
  } else {
    NA
  }
}

# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control
resp_cache_control <- function(resp) {
  x <- resp_header(resp, "Cache-Control")
  if (is.null(x)) {
    return(NULL)
  }

  pieces <- strsplit(x, ",")[[1]]
  pieces <- gsub("^\\s+|\\s+$", "", pieces)
  pieces <- tolower(pieces)

  is_value <- grepl("=", pieces)
  flags <- pieces[!is_value]

  keyvalues <- strsplit(pieces[is_value], "\\s*=\\s*")
  keys <- c(rep("flags", length(flags)), lapply(keyvalues, "[[", 1))
  values <- c(flags, lapply(keyvalues, "[[", 2))

  stats::setNames(values, keys)
}
