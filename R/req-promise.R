#' Perform request asynchronously using the promises package
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This variation on [req_perform()] returns a [promises::promise()] object immediately
#' and then performs the request in the background, returning program control before the request
#' is finished. See the
#' [promises package documentation](https://rstudio.github.io/promises/articles/promises_01_motivation.html)
#' for more details on how to work with the resulting promise object.
#'
#' If using together with [later::with_temp_loop()] or other private event loops,
#' a new curl pool made by [curl::new_pool()] should be created for requests made
#' within the loop to ensure that only these requests are being polled by the loop.
#'
#' Like with [req_perform_parallel()], exercise caution when using this function;
#' it's easy to pummel a server with many simultaneous requests. Also, not all servers
#' can handle more than 1 request at a time, so the responses may still return
#' sequentially.
#'
#' `req_perform_promise()` also has similar limitations to the
#' [req_perform_parallel()] function, it:
#'
#' * Will not retrieve a new OAuth token if it expires after the promised request
#'   is created but before it is actually requested.
#' * Does not perform throttling with [req_throttle()].
#' * Does not attempt retries as described by [req_retry()].
#' * Only consults the cache set by [req_cache()] when the request is promised.
#'
#' @inheritParams req_perform
#' @inheritParams req_perform_parallel
#' @param pool A pool created by [curl::new_pool()].
#' @return a [promises::promise()] object which resolves to a [response] if
#' successful or rejects on the same errors thrown by [req_perform()].
#' @export
#'
#' @examples
#' \dontrun{
#' library(promises)
#' request_base <- request(example_url()) |> req_url_path_append("delay")
#'
#' p <- request_base |> req_url_path_append(2) |> req_perform_promise()
#'
#' # A promise object, not particularly useful on its own
#' p
#'
#' # Use promise chaining functions to access results
#' p %...>%
#'   resp_body_json() %...>%
#'   print()
#'
#'
#' # Can run two requests at the same time
#' p1 <- request_base |> req_url_path_append(2) |> req_perform_promise()
#' p2 <- request_base |> req_url_path_append(1) |> req_perform_promise()
#'
#' p1 %...>%
#'   resp_url_path %...>%
#'   paste0(., " finished") %...>%
#'   print()
#'
#' p2 %...>%
#'   resp_url_path %...>%
#'   paste0(., " finished") %...>%
#'   print()
#'
#' # See the [promises package documentation](https://rstudio.github.io/promises/)
#' # for more information on working with promises
#' }
req_perform_promise <- function(
  req,
  path = NULL,
  pool = NULL,
  verbosity = NULL,
  mock = getOption("httr2_mock", NULL)
) {
  check_installed(c("promises", "later"))

  check_request(req)
  check_string(path, allow_null = TRUE)
  verbosity <- verbosity %||% httr2_verbosity()
  mock <- as_mock_function(mock)

  if (missing(pool)) {
    if (!identical(later::current_loop(), later::global_loop())) {
      cli::cli_abort(c(
        "Must supply {.arg pool} when calling {.code later::with_temp_loop()}.",
        i = "Do you need {.code pool = curl::new_pool()}?"
      ))
    }
  } else {
    if (!is.null(pool) && !inherits(pool, "curl_multi")) {
      stop_input_type(pool, "a {curl} pool", allow_null = TRUE)
    }
  }
  # verbosity checked by req_verbosity
  req <- req_verbosity(req, verbosity)

  promises::promise(function(resolve, reject) {
    pooled_req <- pooled_request(
      req = req,
      path = path,
      on_success = function(resp) resolve(resp),
      on_failure = function(error) reject(error),
      on_error = function(error) reject(error),
      mock = mock
    )
    pooled_req$submit(pool)
    ensure_pool_poller(pool)
  })
}

ensure_pool_poller <- function(pool) {
  key <- obj_address(pool)
  poller <- the$pool_pollers[[key]]
  if (!is.null(poller) && later::exists_loop(poller$loop)) {
    wake_pool_poller(poller)
    return(invisible())
  }

  # A temporary loop can be destroyed while a socket wait is outstanding.
  if (!is.null(poller$cancel_wait)) {
    poller$cancel_wait()
  }

  poller <- new_environment(list(
    pool = pool,
    loop = later::current_loop(),
    cancel_wait = NULL
  ))
  the$pool_pollers[[key]] <- poller
  poll_curl_pool(poller)
}

wake_pool_poller <- function(poller) {
  # A poll already running or scheduled will pick up the new request.
  if (is.null(poller$cancel_wait)) {
    return(invisible())
  }

  # The old socket wait doesn't include the newly added handle.
  poller$cancel_wait()
  poller$cancel_wait <- NULL
  later::later(\() poll_curl_pool(poller), loop = poller$loop)
}

poll_curl_pool <- function(poller) {
  poller$cancel_wait <- NULL
  pool <- poller$pool
  key <- obj_address(pool)
  withCallingHandlers(
    {
      curl::multi_run(0, pool = pool)
      # Count handles after running curl: a completion callback can add one.
      if (length(curl::multi_list(pool = pool)) == 0) {
        env_unbind(the$pool_pollers, key)
        return(invisible())
      }

      fds <- curl::multi_fdset(pool = pool)
      poller$cancel_wait <- later::later_fd(
        func = \(ready) poll_curl_pool(poller),
        readfds = fds$reads,
        writefds = fds$writes,
        exceptfds = fds$exceptions,
        timeout = fds$timeout,
        loop = poller$loop
      )
    },
    error = function(cnd) env_unbind(the$pool_pollers, key)
  )
}
