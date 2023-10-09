#' Perform multiple requests in parallel
#'
#' @description
#' This variation on [req_perform()] performs multiple requests in parallel.
#' Unlike `req_perform()` it always succeeds; it will never throw an error.
#' Instead it will return error objects, which are your responsibility to
#' handle.
#'
#' Exercise caution when using this function; it's easy to pummel a server
#' with many simultaneous requests. Only use it with hosts designed to serve
#' many files at once.
#'
#' # Limitations
#'
#' * Will not retrieve a new OAuth token if it expires part way through
#'   the requests.
#' * Does not perform throttling with [req_throttle()].
#' * Does not attempt retries as described by [req_retry()].
#' * Consults the cache set by [req_cache()] before/after all requests.
#'
#' In general, where [req_perform()] might make multiple requests due to retries
#' or OAuth failures, `req_perform_multi()` will make only make 1.
#'
#' @param reqs A list of [request]s.
#' @param paths An optional list of paths, if you want to download the request
#'   bodies to disks. If supplied, must be the same length as `reqs`.
#' @param pool Optionally, a curl pool made by [curl::new_pool()]. Supply
#'   this if you want to override the defaults for total concurrent connections
#'   (100) or concurrent connections per host (6).
#' @param cancel_on_error Should all pending requests be cancelled when you
#'   hit an error. Set this to `TRUE` to stop all requests as soon as you
#'   hit an error. Responses that were never performed will have class
#'   `httr2_cancelled` in the result.
#' @returns A list the same length as `reqs` where each element is either a
#'   [response] or an `error`.
#' @export
#' @examples
#' # Requesting these 4 pages one at a time would take 2 seconds:
#' request_base <- request(example_url())
#' reqs <- list(
#'   request_base %>% req_url_path("/delay/0.5"),
#'   request_base %>% req_url_path("/delay/0.5"),
#'   request_base %>% req_url_path("/delay/0.5"),
#'   request_base %>% req_url_path("/delay/0.5")
#' )
#' # But it's much faster if you request in parallel
#' system.time(resps <- req_perform_multi(reqs))
#'
#' reqs <- list(
#'   request_base %>% req_url_path("/status/200"),
#'   request_base %>% req_url_path("/status/400"),
#'   request("FAILURE")
#' )
#' # req_perform_multi() will always succeed
#' resps <- req_perform_multi(reqs)
#' # you'll need to inspect the results to figure out which requests fails
#' fail <- vapply(resps, inherits, "error", FUN.VALUE = logical(1))
#' resps[fail]
req_perform_multi <- function(reqs, paths = NULL, pool = NULL, cancel_on_error = FALSE) {
  if (!is.null(paths)) {
    if (length(reqs) != length(paths)) {
      cli::cli_abort("If supplied, {.arg paths} must be the same length as {.arg req}.")
    }
  }

  perfs <- vector("list", length(reqs))
  for (i in seq_along(reqs)) {
    perfs[[i]] <- Performance$new(req = reqs[[i]], path = paths[[i]])
    perfs[[i]]$submit(pool)
  }

  pool_run(pool, perfs, cancel_on_error = cancel_on_error)
  map(perfs, ~ .$resp)
}

#' @export
#' @rdname req_perform_multi
#' @usage NULL
multi_req_perform <- function(reqs, paths = NULL, pool = NULL, cancel_on_error = FALSE) {
  lifecycle::deprecate_warn(
    "0.3.0",
    "multi_req_perform()",
    "req_perform_multi()"
  )

  req_perform_multi(
    reqs = reqs,
    paths = paths,
    pool = pool,
    cancel_on_error = cancel_on_error
  )
}

pool_run <- function(pool, perfs, cancel_on_error = FALSE) {
  poll_until_done <- function(pool) {
    repeat({
      # TODO: progress bar
      run <- curl::multi_run(0.1, pool = pool, poll = TRUE)
      if (run$pending == 0) {
        break
      }
    })
  }

  cancel <- function(cnd) pool_cancel(pool, perfs)
  if (!cancel_on_error) {
    tryCatch(poll_until_done(pool), interrupt = cancel)
  } else {
    tryCatch(poll_until_done(pool), interrupt = cancel, `httr2:::failed` = cancel)
  }

  # Ensuring any pending handles are still completed
  curl::multi_run(pool = pool)

  invisible()
}

# Wrap up all components of request -> response in a single object
Performance <- R6Class("Performance", public = list(
  req = NULL,
  path = NULL,

  handle = NULL,
  resp = NULL,
  pool = NULL,

  initialize = function(req, path = NULL) {
    self$req <- req
    self$path <- path

    req <- auth_oauth_sign(req)
    req <- cache_pre_fetch(req)
    if (is_response(req)) {
      self$resp <- req
    } else {
      self$handle <- req_handle(req)
      curl::handle_setopt(self$handle, url = req$url)
    }
  },

  submit = function(pool = NULL) {
    if (!is.null(self$resp)) {
      return()
    }

    self$pool <- pool
    self$resp <- error_cnd("httr2_cancelled", message = "Request cancelled")
    curl::multi_add(self$handle,
      pool = self$pool,
      data = self$path,
      done = self$succeed,
      fail = self$fail
    )
    invisible(self)
  },

  succeed = function(res) {
    body <- if (is.null(self$path)) res$content else new_path(self$path)
    resp <- new_response(
      method = req_method_get(self$req),
      url = res$url,
      status_code = res$status_code,
      headers = as_headers(res$headers),
      body = body
    )
    resp <- cache_post_fetch(self$reqs, resp, path = self$paths)

    self$resp <- tryCatch(resp_check_status(resp), error = identity)
    if (is_error(self$resp)) {
      signal("", class = "httr2:::failed")
    }
  },

  fail = function(msg) {
    self$resp <- error_cnd("httr2_failure", message = msg)
    signal("", class = "httr2:::failed")
  },

  cancel = function() {
    if (!is.null(self$handle)) {
      curl::multi_cancel(self$handle)
    }
  }
))

pool_cancel <- function(pool, perfs) {
  walk(perfs, ~ .x$cancel())
}
