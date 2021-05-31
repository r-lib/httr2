resp_cacheable <- function(resp, control = NULL) {
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

  if (!any(resp_header_exists(resp, c("Etag", "Last-Modified")))) {
    return(FALSE)
  }

  TRUE
}

resp_cache_info <- function(resp, control = NULL) {
  list(
    expires = resp_cache_expiry(resp, control),
    last_modified = resp_header(resp, "Last-Modified"),
    etag = resp_header(resp, "Etag")
  )
}

resp_cache_expiry <- function(resp, control = NULL) {
  control <- control %||% resp_cache_control(resp)

  # Prefer max-age parameter if it exists, otherwise use Expires header
  if (!has_name(control, "max-age") && resp_header_exists(resp, "Date")) {
    expiry <- resp_date(resp) + as.integer(control[["max-age"]])
  } else if (resp_header_exists(resp, "Expires")) {
    httr::parse_http_date(resp_header(resp, "Expires"), NULL)
  } else {
    NULL
  }
}

resp_date <- function(resp) {
  httr::parse_http_date(resp_header(resp, "Date"), NULL)
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

req_cache_info <- function(req) {
  if (req_policy_exists(req, "policy_cache_dir")) {
    NULL
  } else {
    req_cache_info(req_cache_get(req))
  }
}

# Do I need to worry about hash collisions?
# No - even if the user stores a billion urls, the probably of a collision
# is ~ 1e-20: https://preshing.com/20110504/hash-collision-probabilities/
req_cache_path <- function(req, ext) {
  file.path(req$policy_cache_dir, paste0(hash(req$url), ext))
}

req_cache_get <- function(req) {
  path <- req_cache_path(req)
  if (!file.exists(path)) {
    abort("Internal error: attempted to retrive uncached request")
  }

   # Touch the path
  Sys.setFileTime(path, Sys.time())
  readRDS(path)
}

req_cache_gc <- function(req, max_n = Inf, max_size = Inf, max_days = Inf) {
  #
}

req_cache_body <- function(req, path = NULL) {
  body <- req_cache_get(req)$body
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

req_cache_set <- function(req, resp) {
  if (is_path(resp$body)) {
    body_path <- req_cache_path(req, ".body")
    file.copy(resp$body, body_path, overwrite = TRUE)
    resp$body <- new_path(body_path)
  }

  saveRDS(resp, req_cache_path(req, ".rds"))

  invisible()
}

function() {
  cached <- req_cache_info(req)
  if (is.null(cached$expiry) && cached$expiry <= Sys.time()) {
    return(req_cached(req))
  }
  if (!is.null(cached)) {
    req <- req_headers(req,
      `If-Modified-Since` = cached$last_modified,
      `If-None-Match` = cached$etag
    )
  }

  if (is_error(resp)) {
    if (!is.null(cached) && use_cache_on_error) {
      req_cached(req)
    } else {
      stop(resp)
    }
  } else if (error_is_error(req, resp)) {
    resp_check_status(resp, error_info(req, resp))
  } else if (resp_status(resp) == 304) {
    # Replace body with cached result
    resp$body <- req_cache_body(req, path)
    resp
  } else {
    if (has_cache && resp_cacheable(resp)) {
      req_cache_set(req, resp)
    }
    resp
  }


}
