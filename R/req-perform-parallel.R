#' Perform a list of requests in parallel
#'
#' @description
#' This variation on [req_perform_sequential()] performs multiple requests in
#' parallel. Exercise caution when using this function; it's easy to pummel a
#' server with many simultaneous requests. Only use it with hosts designed to
#' serve many files at once, which are typically web servers, not API servers.
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
#' @inherit req_perform_sequential params return
#' @param pool Optionally, a curl pool made by [curl::new_pool()]. Supply
#'   this if you want to override the defaults for total concurrent connections
#'   (100) or concurrent connections per host (6).
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
#' # req_perform_parallel() will fail on error
#' reqs <- list(
#'   request_base |> req_url_path("/status/200"),
#'   request_base |> req_url_path("/status/400"),
#'   request("FAILURE")
#' )
#' try(resps <- req_perform_parallel(reqs))
#'
#' # but can use on_error to capture all successful results
#' resps <- req_perform_parallel(reqs, on_error = "continue")
#'
#' # Inspect the successful responses
#' resps |> resps_successes()
#'
#' # And the failed responses
#' resps |> resps_failures() |> resps_requests()
req_perform_parallel <- function(reqs,
                                 paths = NULL,
                                 pool = NULL,
                                 on_error = c("stop", "return", "continue"),
                                 progress = TRUE) {
  check_paths(paths, reqs)
  on_error <- arg_match(on_error)

  progress <- create_progress_bar(
    total = length(reqs),
    name = "Iterating",
    config = progress
  )

  error_call <- environment()
  resps <- rep_along(reqs, list())

  handle_success <- function(i, resp, tries) {
    progress$update()
    resps[[i]] <<- resp
  }
  handle_problem <- function(i, error, tries) {
    progress$update()
    error$call <- error_call
    resps[[i]] <<- error
    signal("", error = error, class = "httr2_fail")
  }

  pooled_requests <- map(seq_along(reqs), function(i) {
    pooled_request(
      req = reqs[[i]],
      path = paths[[i]],
      error_call = error_call,
      on_success = function(resp, tries) handle_success(i, resp, tries),
      on_failure = function(error, tries) handle_problem(i, error, tries),
      on_error = function(error, tries) handle_problem(i, error, tries)
    )
  })

  walk(pooled_requests, function(req) req$submit(pool))
  pool_run(pool, pooled_requests, on_error = on_error)
  progress$done()

  resps
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
#'   hit an error? Set this to `TRUE` to stop all requests as soon as you
#'   hit an error. Responses that were never performed be `NULL` in the result.
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
  on.exit(pool_cancel(pool, perfs), add = TRUE)

  # The done and fail callbacks for curl::multi_add() are designed to always
  # succeed. If the request actually failed, they raise a `httr_fail`
  # signal (not error) that wraps the error. Here we catch that error and
  # handle it based on the value of `on_error`
  httr2_fail <- switch(on_error,
    stop =     function(cnd) cnd_signal(cnd$error),
    continue = function(cnd) zap(),
    return =   function(cnd) NULL
  )

  try_fetch(
    curl::multi_run(pool = pool),
    interrupt = function(cnd) NULL,
    httr2_fail = httr2_fail
  )

  invisible()
}

pool_cancel <- function(pool, perfs) {
  walk(perfs, ~ .x$cancel())
  curl::multi_run(pool = pool)
}
