#' Perform a list of requests in parallel
#'
#' @description
#' This variation on [req_perform()] performs multiple requests in parallel.
#' Exercise caution when using this function; it's easy to pummel a server
#' with many simultaneous requests. Only use it with hosts designed to serve
#' many files at once, which are typically web servers, not API servers.
#'
#' `req_perform_parallel()` has a few limitations:
#'
#' * Will not retrieve a new OAuth token if it expires part way through
#'   the requests.
#' * Does not perform throttling with [req_throttle()].
#' * Does not attempt retries as described by [req_retry()].
#' * Only consults the cache set by [req_cache()] before/after all requests.
#'
#' If any of these limitations are problematic for your use case, we recommend
#' [req_perform_sequential()] instead.
#'
#' @param reqs A list of [request]s.
#' @param paths An optional list of paths, if you want to download the request
#'   bodies to disks. If supplied, must be the same length as `reqs`.
#' @param pool Optionally, a curl pool made by [curl::new_pool()]. Supply
#'   this if you want to override the defaults for total concurrent connections
#'   (100) or concurrent connections per host (6).
#' @param on_error What should happen if one of the requests fails?
#'
#'   * `stop`, the default: stop iterating with an error.
#'   * `return`: stop iterating, returning all the successful responses
#'     received so far, as well as an error object for the failed request.
#'   * `continue`: continue iterating, recording errors in the result.
#' @return
#' A list, the same length as `reqs`, containing [response]s and possibly
#' error objects, if `on_error` is `"return"` or `"continue"` and one of the
#' responses error. If `on_error` is `"return"` and it errors on the ith
#' request, the ith element of the result will be an error object, and the
#' remaining elements will be `NULL`. If `on_error` is `"continue"`, it will
#' be a mix of requests and error objects.
#'
#' Only httr2 errors are captured; see [req_error()] for more details.
#' @export
#' @examples
#' # Requesting these 4 pages one at a time would take 2 seconds:
#' request_base <- request(example_url())
#' reqs <- list(
#'   request_base |> req_url_path("/delay/0.5"),
#'   request_base |> req_url_path("/delay/0.5"),
#'   request_base |> req_url_path("/delay/0.5"),
#'   request_base |> req_url_path("/delay/0.5")
#' )
#' # But it's much faster if you request in parallel
#' system.time(resps <- req_perform_parallel(reqs))
#'
#' reqs <- list(
#'   request_base |> req_url_path("/status/200"),
#'   request_base |> req_url_path("/status/400"),
#'   request("FAILURE")
#' )
#' # req_perform_parallel() will always succeed
#' resps <- req_perform_parallel(reqs)
#'
#' # Inspect the successful responses
#' resps |> resps_successes()
#'
#' # And the failed responses
#' resps |> resps_failures() |> resps_requests()
req_perform_parallel <- function(reqs,
                                 paths = NULL,
                                 pool = NULL,
                                 on_error = c("stop", "return", "continue")) {
  check_paths(paths, reqs)
  on_error <- arg_match(on_error)

  perfs <- vector("list", length(reqs))
  for (i in seq_along(reqs)) {
    perfs[[i]] <- Performance$new(
      req = reqs[[i]],
      path = paths[[i]],
      error_call = environment()
    )
    perfs[[i]]$submit(pool)
  }

  pool_run(pool, perfs, on_error = on_error)
  map(perfs, ~ .$resp)
}


#' Perform a list of requests in parallel
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' Please use [req_perform_parallel()] instead, and note:
#'
#' * `cancel_on_error = FALSE` is now `on_error = "continue"`
#' * `cancel_on_error = TRUE` is now `on_error = "return"`
#'
#' @export
#' @param cancel_on_error Should all pending requests be cancelled when you
#'   hit an error. Set this to `TRUE` to stop all requests as soon as you
#'   hit an error. Responses that were never performed will have class
#'   `httr2_cancelled` in the result.
#' @inheritParams req_perform_parallel
#' @keywords internal
multi_req_perform <- function(reqs,
                              paths = NULL,
                              pool = NULL,
                              cancel_on_error = FALSE) {
  lifecycle::deprecate_warn(
    "1.0.0",
    "multi_req_perform()",
    "req_perform_parallel()"
  )
  check_bool(cancel_on_error)

  req_perform_parallel(
    reqs = reqs,
    paths = paths,
    pool = pool,
    on_error = if (cancel_on_error) "continue" else "return"
  )
}

pool_run <- function(pool, perfs, on_error = "continue") {
  poll_until_done <- function(pool) {
    repeat({
      # TODO: progress bar
      run <- curl::multi_run(0.1, pool = pool, poll = TRUE)
      if (run$pending == 0) {
        break
      }
    })
  }

  # Ensure that this function leaves the pool in a good state
  on.exit({
    pool_cancel(pool, perfs)
    curl::multi_run(pool = pool)
  }, add = TRUE)

  cancel <- function(cnd) cnd
  if (on_error == "stop") {
    signal <- tryCatch(poll_until_done(pool), interrupt = cancel, `httr2:::failed` = cancel)
    if (is_error(signal$response)) {
      cnd_signal(signal$response)
    }
  } else if (on_error == "continue") {
    tryCatch(poll_until_done(pool), interrupt = cancel)
  } else {
    tryCatch(poll_until_done(pool), interrupt = cancel, `httr2:::failed` = cancel)
  }

  invisible()
}

# Wrap up all components of request -> response in a single object
Performance <- R6Class("Performance", public = list(
  req = NULL,
  path = NULL,

  handle = NULL,
  resp = NULL,
  pool = NULL,
  error_call = NULL,

  initialize = function(req, path = NULL, error_call = NULL) {
    self$req <- req
    self$path <- path
    self$error_call <- error_call

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
    curl::multi_add(self$handle,
      pool = self$pool,
      data = self$path,
      done = self$succeed,
      fail = self$fail
    )
    invisible(self)
  },

  succeed = function(res) {
    self$handle <- NULL
    body <- if (is.null(self$path)) res$content else new_path(self$path)
    resp <- new_response(
      method = req_method_get(self$req),
      url = res$url,
      status_code = res$status_code,
      headers = as_headers(res$headers),
      body = body,
      request = self$req
    )
    resp <- cache_post_fetch(self$reqs, resp, path = self$paths)

    self$resp <- tryCatch(
      resp_check_status(resp, error_call = self$error_call),
      error = identity
    )
    if (is_error(self$resp)) {
      signal("", response = self$resp, class = "httr2:::failed")
    }
  },

  fail = function(msg) {
    self$handle <- NULL
    self$resp <- error_cnd(
      "httr2_failure",
      message = msg,
      request = self$req,
      call = self$error_call
    )
    signal("", response = self$resp, class = "httr2:::failed")
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
