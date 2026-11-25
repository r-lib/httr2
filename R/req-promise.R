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
  if (is.null(poller) || poller$done || !later::exists_loop(poller$loop)) {
    poller <- PoolPoller$new(pool)
    the$pool_pollers[[key]] <- poller
    poller$poll()
  } else {
    poller$repoll()
  }
  invisible()
}

PoolPoller <- R6Class(
  "PoolPoller",
  public = list(
    pool = NULL,
    loop = NULL,
    cancel_poll = NULL,
    done = FALSE,

    initialize = function(pool) {
      self$pool <- pool
      self$loop <- later::current_loop()
    },

    stop = function() {
      self$done <- TRUE
      self$pool <- NULL
      self$loop <- NULL
    },

    repoll = function() {
      # poll() snapshots the pool's sockets at its end, so a poll that is
      # running or queued (cancel_poll is NULL) is guaranteed to see the
      # new request when it snapshots, and there's nothing to do.
      if (is.null(self$cancel_poll)) {
        return(invisible())
      }

      # The pending wait only watches sockets known before this request arrived,
      # so cancel it and re-poll.
      self$cancel_poll()
      self$cancel_poll <- NULL

      # Defer to the next tick on the poller's own loop, rather than calling
      # poll() directly, so that curl work (and any errors or completion
      # callbacks it triggers) doesn't run in the caller's stack.
      later::later(\() self$poll(), loop = self$loop)
    },

    poll = function() {
      self$cancel_poll <- NULL
      withCallingHandlers(
        {
          curl_multi_run(0, pool = self$pool)
          if (length(curl::multi_list(self$pool)) > 0) {
            self$cancel_poll <- self$schedule_poll()
          } else {
            self$stop()
          }
        },
        error = function(cnd) {
          self$stop()
          cli::cli_abort(
            c(
              "Background request polling stopped after an unexpected error.",
              i = "Pending promises may not resolve until a new request is submitted to the same pool."
            ),
            parent = cnd
          )
        }
      )
      invisible()
    },

    schedule_poll = function() {
      fds <- curl::multi_fdset(pool = self$pool)
      later::later_fd(
        func = \(ready) self$poll(),
        readfds = fds$reads,
        writefds = fds$writes,
        exceptfds = fds$exceptions,
        # curl reports milliseconds and later expects seconds.
        timeout = fds$timeout / 1000,
        loop = self$loop
      )
    }
  )
)

# For mocking
curl_multi_run <- function(...) {
  curl::multi_run(...)
}
