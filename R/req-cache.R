#' Automatically cache requests
#'
#' @description
#' Use `req_perform()` to automatically cache HTTP requests. Most API requests
#' are not cacheable, but static files often are.
#'
#' `req_cache()` caches responses to GET requests that have status code 200 and
#' at least one of the standard caching headers (e.g. `Expires`,
#' `Etag`, `Last-Modified`, `Cache-Control`), unless caching has been expressly
#' prohibited with `Cache-Control: no-store`. Typically, a request will still
#' be sent to the server to check that the cached value is still up-to-date,
#' but it will not need to re-download the body value.
#'
#' To learn more about HTTP caching, I recommend the MDN article
#' [HTTP caching](https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching).
#'
#' @inheritParams req_perform
#' @param path Path to cache directory.
#'
#'   httr2 doesn't provide helpers to manage the cache, but if you want to
#'   empty it, you can use something like
#'   `unlink(dir(cache_path, full.names = TRUE))`.
#' @param use_on_error If the request errors, and there's a cache response,
#'   should `req_perform()` return that instead of generating an error?
#' @param debug When `TRUE` will emit useful messages telling you about
#'   cache hits and misses. This can be helpful to understand whether or
#'   not caching is actually doing anything for your use case.
#' @param max_n,max_age,max_size Automatically prune the cache by specifying
#'   one or more of:
#'
#'   * `max_age`: to delete files older than this number of seconds.
#'   * `max_n`: to delete files (from oldest to newest) to preserve at
#'      most this many files.
#'   * `max_size`: to delete files (from oldest to newest) to preserve at
#'      most this many bytes.
#'
#'   The cache pruning is performed at most once per minute.
#' @returns A modified HTTP [request].
#' @export
#' @examples
#' # GitHub uses HTTP caching for all raw files.
#' url <- paste0(
#'   "https://raw.githubusercontent.com/allisonhorst/palmerpenguins/",
#'   "master/inst/extdata/penguins.csv"
#' )
#' # Here I set debug = TRUE so you can see what's happening
#' req <- request(url) |> req_cache(tempdir(), debug = TRUE)
#'
#' # First request downloads the data
#' resp <- req |> req_perform()
#'
#' # Second request retrieves it from the cache
#' resp <- req |> req_perform()
req_cache <- function(req,
                      path,
                      use_on_error = FALSE,
                      debug = getOption("httr2_cache_debug", FALSE),
                      max_age = Inf,
                      max_n = Inf,
                      max_size = 1024^3) {

  check_number_whole(max_age, min = 0, allow_infinite = TRUE)
  check_number_whole(max_n, min = 0, allow_infinite = TRUE)
  check_number_decimal(max_size, min = 1, allow_infinite = TRUE)

  dir.create(path, showWarnings = FALSE, recursive = TRUE)
  req_policies(req,
    cache_path = path,
    cache_use_on_error = use_on_error,
    cache_debug = debug,
    cache_max = list(age = max_age, n = max_n, size = max_size)
  )
}

# Do I need to worry about hash collisions?
# No - even if the user stores a billion urls, the probably of a collision
# is ~ 1e-20: https://preshing.com/20110504/hash-collision-probabilities/
req_cache_path <- function(req, ext = ".rds") {
  file.path(req$policies$cache_path, paste0(hash(req$url), ext))
}
cache_use_on_error <- function(req) {
  req$policies$cache_use_on_error %||% FALSE
}
cache_debug <- function(req) {
  req$policies$cache_debug %||% FALSE
}

# Cache management --------------------------------------------------------

cache_active <- function(req) {
  req_policy_exists(req, "cache_path")
}

cache_get <- function(req) {
  # This check should be redudant but we keep it in for safety
  if (!cache_active(req)) {
    return(req)
  }

  path <- req_cache_path(req)
  if (!file.exists(path)) {
    return(NULL)
  }

  tryCatch(
    {
      rds <- readRDS(path)
      # Update file time if read successfully
      Sys.setFileTime(path, Sys.time())
      rds
    },
    error = function(e) NULL
  )
}

cache_set <- function(req, resp) {
  if (is_path(resp$body)) {
    body_path <- req_cache_path(req, ".body")
    file.copy(resp$body, body_path, overwrite = TRUE)
    resp$body <- new_path(body_path)
  }

  saveRDS(resp, req_cache_path(req, ".rds"))
  invisible()
}

cache_prune_if_needed <- function(req, threshold = 60, debug = FALSE) {
  path <- req$policies$cache_path

  last_prune <- the$cache_throttle[[path]]
  if (is.null(last_prune) || last_prune + threshold <= Sys.time()) {
    if (debug) cli::cli_text("Pruning cache")
    cache_prune(path, max = req$policies$cache_max, debug = debug)
    the$cache_throttle[[path]] <- Sys.time()

    invisible(TRUE)
  } else {
    invisible(FALSE)
  }
}

# Adapted from
# https://github.com/r-lib/cachem/blob/main/R/cache-disk.R#L396-L467
cache_prune <- function(path, max, debug = TRUE) {
  info <- cache_info(path)

  info <- cache_prune_files(info, info$mtime + max$age < Sys.time(), "too old", debug)
  info <- cache_prune_files(info, seq_len(nrow(info)) > max$n, "too numerous", debug)
  info <- cache_prune_files(info, cumsum(info$size) > max$size, "too big", debug)

  invisible()
}

cache_info <- function(path, pattern = "\\.rds$") {
  filenames <- dir(path, pattern, full.names = TRUE)
  info <- file.info(filenames, extra_cols = FALSE)
  info <- info[info$isdir == FALSE, ]
  info$name <- rownames(info)
  rownames(info) <- NULL
  info[order(info$mtime, decreasing = TRUE), c("name", "size", "mtime")]
}

cache_prune_files <- function(info, to_remove, why, debug = TRUE) {
  if (any(to_remove)) {
    if (debug) cli::cli_text("Deleted {sum(to_remove)} file{?s} that {?is/are} {why}")

    file.remove(info$name[to_remove])
    info[!to_remove, ]
  } else {
    info
  }
}

# Hooks for req_perform -----------------------------------------------------

# Can return request or response
cache_pre_fetch <- function(req) {
  if (!cache_active(req)) {
    return(req)
  }

  debug <- cache_debug(req)
  cache_prune_if_needed(req, debug = debug)

  cached_resp <- cache_get(req)
  if (is.null(cached_resp)) {
    return(req)
  }
  if (debug) cli::cli_text("Found url in cache {.val {hash(req$url)}}")

  info <- resp_cache_info(cached_resp)
  if (!is.na(info$expires) && info$expires >= Sys.time()) {
    signal("", "httr2_cache_cached")
    if (debug) cli::cli_text("Cached value is fresh; using response from cache")
    cached_resp
  } else {
    if (debug) cli::cli_text("Cached value is stale; checking for updates")
    req_headers(req,
      `If-Modified-Since` = info$last_modified,
      `If-None-Match` = info$etag
    )
  }
}

# Always returns response
cache_post_fetch <- function(req, resp, path = NULL) {
  if (!cache_active(req)) {
    return(resp)
  }

  debug <- cache_debug(req)
  cached_resp <- cache_get(req)

  if (is_error(resp)) {
    if (cache_use_on_error(req) && !is.null(cached_resp)) {
      if (debug) cli::cli_text("Request errored; retrieving response from cache")
      cached_resp
    } else {
      resp
    }
  } else if (resp_status(resp) == 304 && !is.null(cached_resp)) {
    signal("", "httr2_cache_not_modified")
    if (debug) cli::cli_text("Cached value still ok; retrieving body from cache")

    # Replace body with cached result
    resp$body <- cache_body(cached_resp, path)
    # Combine headers
    resp$headers <- cache_headers(cached_resp, resp)
    resp
  } else if (resp_is_cacheable(resp)) {
    signal("", "httr2_cache_save")
    if (debug) cli::cli_text("Saving response to cache {.val {hash(req$url)}}")
    cache_set(req, resp)
    resp
  } else {
    resp
  }
}

cache_body <- function(cached_resp, path = NULL) {
  check_response(cached_resp)

  body <- cached_resp$body

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

# https://www.rfc-editor.org/rfc/rfc7232#section-4.1
cache_headers <- function(cached_resp, resp) {
  check_response(cached_resp)
  as_headers(modify_list(cached_resp$headers, !!!resp$headers))
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
