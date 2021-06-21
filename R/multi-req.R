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
  if (!is.null(paths)) {
    if (length(reqs) != length(paths)) {
      abort("If supplied, `paths` must be the same length as `requests`")
    }
  }

  out <- rep(list(error_cnd("httr2_cancelled", message = "Request cancelled")), length(reqs))
  handles <- vector("list", length(reqs))
  done_i <- function(i, path, method) {
    force(i)
    function(res) {
      body <- if (is.null(path)) res$content else new_path(path)
      resp <- new_response(
        method = method,
        url = res$url,
        status_code = res$status_code,
        headers = as_headers(res$headers),
        body = body
      )
      out[[i]] <<- tryCatch(resp_check_status(resp), error = function(err) {
        if (cancel_on_error) multi_cancel_all(handles)
        err
      })
    }
  }
  fail_i <- function(i) {
    force(i)
    function(msg) {
      out[[i]] <<- error_cnd("httr2_failed", message = msg)
      if (cancel_on_error) multi_cancel_all(handles)
    }
  }

  for (i in seq_along(reqs)) {
    req <- reqs[[i]]
    req <- auth_oauth_sign(req)
    req <- cache_pre_fetch(req)
    if (is_response(req)) {
      out[[i]] <- req
      next
    }

    handles[[i]] <- req_handle(req)
    curl::handle_setopt(handles[[i]], url = req$url)
    curl::multi_add(handles[[i]],
      pool = pool,
      data = paths[[i]],
      done = done_i(i, paths[[i]], req_method_get(req)),
      fail = fail_i(i)
    )
  }

  tryCatch(
    while(curl::multi_run(0.1, pool = pool, poll = TRUE)$pending > 0) {
      # TODO: update progress spinner
    },
    interrupt = function(cnd) {
      multi_cancel_all(handles)
      invokeRestart("abort")
    }
  )

  for (i in seq_along(reqs)) {
    out[[i]] <- cache_post_fetch(reqs[[i]], out[[i]], path = paths[[i]])
  }

  out
}

multi_cancel_all <- function(handles) {
  for (handle in handles) {
    curl::multi_cancel(handle)
  }
}
