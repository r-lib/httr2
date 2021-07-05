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
#' or OAuth failures, `multi_req_perform()` will make only make 1.
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
#' @return A list the same length as `reqs` where each element is either a
#'   [response] or an `error`.
#' @export
#' @examples
#' # Requesting these 4 pages one at a time would take four seconds:
#' reqs <- list(
#'   request("https://httpbin.org/delay/1"),
#'   request("https://httpbin.org/delay/1"),
#'   request("https://httpbin.org/delay/1"),
#'   request("https://httpbin.org/delay/1")
#' )
#' # But it's much faster if you request in parallel
#' system.time(resps <- multi_req_perform(reqs))
#'
#' reqs <- list(
#'   request("https://httpbin.org/status/200"),
#'   request("https://httpbin.org/status/400"),
#'   request("FAILURE")
#' )
#' # multi_req_perform() will always succeed
#' resps <- multi_req_perform(reqs)
#' # you'll need to inspect the results to figure out which requests fails
#' fail <- vapply(resps, inherits, "error", FUN.VALUE = logical(1))
#' resps[fail]
multi_req_perform <- function(reqs, paths = NULL, pool = NULL, cancel_on_error = FALSE) {
  mq <- MultiRequest$new(pool = pool, cancel_on_error = cancel_on_error)
  mq$add_requests(reqs, paths)
  mq$perform()
  mq$resps
}

MultiRequest <- R6::R6Class("MultiRequest", public = list(
  pool = NULL,
  cancel_on_error = FALSE,

  reqs = list(),
  resps = list(),
  handles = list(),
  paths = character(), # needed for cache updates
  i = 0,

  initialize = function(pool = NULL, cancel_on_error = FALSE) {
    self$pool <- pool
    self$cancel_on_error <- cancel_on_error
  },

  add_requests = function(reqs, paths = NULL) {
    if (!is.null(paths)) {
      if (length(reqs) != length(paths)) {
        abort("If supplied, `paths` must be the same length as `req`")
      }
    }
    n <- length(reqs)
    self$reqs <- expand(self$reqs, n)
    self$paths <- expand(self$paths, n)
    self$resps <- expand(self$resps, n)

    for (i in seq_along(reqs)) {
      self$add_request(reqs[[i]], paths[[i]])
    }
  },

  add_request = function(req, path = NULL) {
    self$i <- self$i + 1
    self$reqs[[self$i]] <- req
    if (!is.null(path)) {
      self$paths[[self$i]] <- path
    }
    self$resps[[self$i]] <- error_cnd("httr2_cancelled", message = "Request cancelled")

    req <- auth_oauth_sign(req)
    req <- cache_pre_fetch(req)
    if (is_response(req)) {
      self$resps[[self$i]] <- req
      return()
    }

    handle <- req_handle(req)
    curl::handle_setopt(handle, url = req$url)
    curl::multi_add(handle,
      pool = self$pool,
      data = path,
      done = self$done_callback(self$i, path),
      fail = self$fail_callback(self$i)
    )

    # Needed for clean up
    self$handles[[self$i]] <- handle
  },

  perform = function() {
    tryCatch(
      while(curl::multi_run(0.1, pool = self$pool, poll = TRUE)$pending > 0) {
        # TODO: update progress spinner
      },
      interrupt = function(cnd) {
        self$cancel()
        stop(cnd)
      }
    )

    for (i in seq_len(self$i)) {
      self$resps[[i]] <- cache_post_fetch(self$reqs[[i]], self$resps[[i]], path = paths[[i]])
    }
  },

  cancel = function() {
    for (handle in self$handles) {
      curl::multi_cancel(handle)
    }
  },

  done_callback = function(i, path) {
    force(path)
    force(i)

    function(res) {
      body <- if (is.null(path)) res$content else new_path(path)
      resp <- new_response(
        method = req_method_get(self$reqs[[i]]),
        url = res$url,
        status_code = res$status_code,
        headers = as_headers(res$headers),
        body = body
      )
      self$resps[[i]] <- tryCatch(
        resp_check_status(resp),
        error = function(err) {
          if (self$cancel_on_error) self$cancel()
          err
        }
      )
    }
  },

  fail_callback = function(i) {
    force(i)
    function(msg) {
      self$resps[[i]] <- error_cnd("httr2_failed", message = msg)
      if (self$cancel_on_error) self$cancel()
    }
  }
))

expand <- function(x, n, value) {
  if (length(x) >= n) {
    return(x)
  }

  if (missing(value)) {
    length(x) <- n
    x
  } else {
    c(x, rep(value, n - length(x)))
  }
}
