#' Perform a list of requests in parallel
#'
#' @description
#' This variation on [req_perform_sequential()] performs multiple requests in
#' parallel. Never use it without [req_throttle()]; otherwise it's too easy to
#' pummel a server with a very large number of simultaneous requests.
#'
#' While running, you'll get a progress bar that looks like:
#' `[working] (1 + 4) -> 5 -> 5`. The string tells you the current status of
#' the queue (e.g. working, waiting, errored) followed by (the
#' number of pending requests + pending retried requests) -> the number of
#' active requests -> the number of complete requests.
#'
#' ## Limitations
#'
#' The main limitation of `req_perform_parallel()` is that it assumes applies
#' [req_throttle()] and [req_retry()] are across all requests. This means,
#' for example, that if request 1 is throttled, but request 2 is not,
#' `req_perform_parallel()` will wait for request 1 before performing request 2.
#' This makes it most suitable for performing many parallel requests to the same
#' host, rather than a mix of different hosts. It's probably possible to remove
#' these limitation, but it's enough work that I'm unlikely to do it unless
#' I know that people would fine it useful: so please let me know!
#'
#' Additionally, it does not respect the `max_tries` argument to `req_retry()`
#' because if you have five requests in flight and the first one gets rate
#' limited, it's likely that all the others do too. This also means that
#' the circuit breaker is never triggered.
#'
#' @inherit req_perform_sequential params return
#' @param pool `r lifecycle::badge("deprecated")`. No longer supported;
#'   to control the maximum number of concurrent requests, set `max_active`.
#' @param max_active Maximum number of concurrent requests.
#' @export
#' @examples
#' # Requesting these 4 pages one at a time would take 2 seconds:
#' request_base <- request(example_url()) |>
#'   req_throttle(capacity = 100, fill_time_s = 60)
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
req_perform_parallel <- function(
  reqs,
  paths = NULL,
  pool = deprecated(),
  on_error = c("stop", "return", "continue"),
  progress = TRUE,
  max_active = 10,
  mock = getOption("httr2_mock", NULL)
) {
  check_paths(paths, reqs)
  if (lifecycle::is_present(pool)) {
    lifecycle::deprecate_warn(
      when = "1.1.0",
      what = "req_perform_parallel(pool)"
    )
  }
  on_error <- arg_match(on_error)
  check_number_whole(max_active, min = 1)
  mock <- as_mock_function(mock, error_call)

  queue <- RequestQueue$new(
    reqs = reqs,
    paths = paths,
    max_active = max_active,
    on_error = on_error,
    progress = progress,
    mock = mock,
    error_call = environment()
  )

  tryCatch(
    queue$process(),
    interrupt = function(cnd) {
      check_repeated_interrupt()

      queue$queue_status <- "errored"
      queue$process()

      n <- sum(!map_lgl(queue$resps, is.null))
      cli::cli_alert_warning(
        "Terminating iteration; returning {n} response{?s}."
      )
    }
  )

  if (on_error == "stop") {
    is_error <- map_lgl(queue$resps, is_error)
    if (any(is_error)) {
      i <- which(is_error)[[1]]
      the$last_response <- queue$resps[[i]]$resp %||% queue$resps[[i]]
      the$last_request <- queue$reqs[[i]]
      cnd_signal(queue$resps[[i]])
    }
  }

  queue$resps
}

RequestQueue <- R6::R6Class(
  "RequestQueue",
  public = list(
    pool = NULL,
    rate_limit_deadline = 0,
    token_deadline = 0,
    max_active = NULL,

    # Overall status for the queue
    queue_status = NULL,
    n_pending = 0,
    n_active = 0,
    n_complete = 0,
    n_retries = 0,
    on_error = "stop",
    mock = NULL,
    progress = NULL,

    # Vectorised along reqs
    reqs = list(),
    pooled_reqs = list(),
    resps = list(),
    status = character(),
    tries = integer(),

    # Requests that have failed due to OAuth expiration; used to ensure that we
    # don't retry repeatedly, but still allow all active requests to retry once
    oauth_failed = integer(),

    initialize = function(
      reqs,
      paths = NULL,
      max_active = 10,
      on_error = "stop",
      progress = FALSE,
      mock = NULL,
      error_call = caller_env()
    ) {
      n <- length(reqs)

      if (isTRUE(progress)) {
        self$progress <- cli::cli_progress_bar(
          total = n,
          format = paste0(
            "[{self$queue_status}] ",
            "({self$n_pending} + {self$n_retries}) -> {self$n_active} -> {self$n_complete} | ",
            "{cli::pb_bar} {cli::pb_percent}"
          ),
          .envir = error_call
        )
      }

      # goal is for pool to not do any queueing; i.e. the curl pool will
      # only ever contain requests that we actually want to process. Any
      # throttling is done by `req_throttle()`
      self$max_active <- max_active
      self$pool <- curl::new_pool(
        total_con = 100,
        host_con = 100,
        max_streams = 100
      )
      self$on_error <- on_error
      self$mock <- mock

      self$queue_status <- "working"
      self$n_pending <- n
      self$n_active <- 0
      self$n_complete <- 0

      self$reqs <- reqs
      self$pooled_reqs <- map(seq_along(reqs), function(i) {
        pooled_request(
          req = reqs[[i]],
          path = paths[[i]],
          on_success = function(resp) self$done_success(i, resp),
          on_failure = function(error) self$done_failure(i, error),
          on_error = function(error) self$done_error(i, error),
          mock = mock,
          error_call = error_call
        )
      })
      self$resps <- vector("list", n)
      self$status <- rep("pending", n)
      self$tries <- rep(0L, n)
    },

    process = function(timeout = Inf) {
      deadline <- unix_time() + timeout

      while (unix_time() <= deadline) {
        out <- self$process1(deadline)
        if (!is.null(out)) {
          return(out)
        }
      }

      TRUE
    },

    # Exposed for testing, so we can manaully work through one step at a time
    process1 = function(deadline = Inf) {
      if (self$queue_status == "done") {
        return(FALSE)
      }

      if (!is.null(self$progress)) {
        cli::cli_progress_update(id = self$progress, set = self$n_complete)
      }

      if (self$queue_status == "waiting") {
        request_deadline <- max(self$token_deadline, self$rate_limit_deadline)
        if (request_deadline <= unix_time()) {
          self$queue_status <- "working"
          return()
        }

        if (self$rate_limit_deadline > self$token_deadline) {
          waiting <- "for rate limit"
        } else {
          waiting <- "for throttling"
        }
        pool_wait_for_deadline(
          self$pool,
          min(request_deadline, deadline),
          waiting
        )
        NULL
      } else if (self$queue_status == "working") {
        if (self$n_pending == 0 && self$n_active == 0) {
          self$queue_status <- "done"
        } else if (self$n_pending > 0 && self$n_active <= self$max_active) {
          if (!self$submit_next(deadline)) {
            self$queue_status <- "waiting"
          }
        } else {
          pool_wait_for_one(self$pool, deadline)
        }
        NULL
      } else if (self$queue_status == "errored") {
        # Finish out any active requests but don't add any more
        if (self$n_active > 0) {
          pool_wait_for_one(self$pool, deadline)
        } else {
          self$queue_status <- "done"
        }
        NULL
      }
    },

    submit_next = function(deadline) {
      i <- which(self$status == "pending")[[1]]

      self$token_deadline <- throttle_deadline(self$reqs[[i]])
      if (self$token_deadline > unix_time()) {
        throttle_return_token(self$reqs[[i]])
        return(FALSE)
      }

      self$set_status(i, "active")
      self$resps[i] <- list(NULL)
      self$tries[[i]] <- self$tries[[i]] + 1

      self$pooled_reqs[[i]]$submit(self$pool)
      TRUE
    },

    done_success = function(i, resp) {
      self$set_status(i, "complete")
      self$resps[[i]] <- resp

      self$oauth_failed <- NULL
    },

    done_error = function(i, error) {
      self$resps[[i]] <- error
      self$set_status(i, "complete")
      if (self$on_error != "continue") {
        self$queue_status <- "errored"
      }
    },

    done_failure = function(i, error) {
      req <- self$reqs[[i]]
      resp <- error$resp
      self$resps[[i]] <- error
      tries <- self$tries[[i]]

      if (retry_is_transient(req, resp) && self$can_retry(i)) {
        delay <- retry_after(req, resp, tries)
        self$rate_limit_deadline <- unix_time() + delay

        self$set_status(i, "pending")
        self$n_retries <- self$n_retries + 1
        self$queue_status <- "waiting"
      } else if (resp_is_invalid_oauth_token(req, resp) && self$can_reauth(i)) {
        # This isn't quite right, because if there are (e.g.) four requests in
        # the queue and the first one fails, we'll clear the cache for all four,
        # causing a token refresh more often than necessary. This shouldn't
        # affect correctness, but it does make it slower than necessary.
        self$oauth_failed <- c(self$oauth_failed, i)
        req_auth_clear_cache(self$reqs[[i]])
        self$set_status(i, "pending")
        self$n_retries <- self$n_retries + 1
      } else {
        self$set_status(i, "complete")
        if (self$on_error != "continue") {
          self$queue_status <- "errored"
        }
      }
    },

    set_status = function(i, status) {
      switch(
        self$status[[i]], # old status
        pending = self$n_pending <- self$n_pending - 1,
        active = self$n_active <- self$n_active - 1
      )
      switch(
        status, # new status
        pending = self$n_pending <- self$n_pending + 1,
        active = self$n_active <- self$n_active + 1,
        complete = self$n_complete <- self$n_complete + 1
      )

      self$status[[i]] <- status
    },

    can_retry = function(i) {
      TRUE
      # self$tries[[i]] < retry_max_tries(self$reqs[[i]])
    },
    can_reauth = function(i) {
      !i %in% self$oauth_failed
    }
  )
)

pool_wait_for_one <- function(pool, deadline) {
  timeout <- deadline - unix_time()
  pool_wait(pool, poll = TRUE, timeout = timeout)
}

pool_wait_for_deadline <- function(pool, deadline, waiting_for) {
  now <- unix_time()
  timeout <- deadline - now
  if (timeout <= 0) {
    return(TRUE)
  }

  complete <- pool_wait(pool, poll = FALSE, timeout = timeout)

  # pool might finish early; we still want to wait out the full time
  remaining <- timeout - (unix_time() - now)
  if (remaining > 2) {
    # Use a progress bar
    sys_sleep(remaining, waiting_for)
  } else if (remaining > 0) {
    Sys.sleep(remaining)
  }

  complete
}

pool_wait <- function(pool, poll, timeout) {
  signal("", class = "httr2_pool_wait", timeout = timeout)
  done <- curl::multi_run(pool = pool, poll = poll, timeout = timeout)
  (done$success + done$error) > 0 || done$pending == 0
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
multi_req_perform <- function(
  reqs,
  paths = NULL,
  pool = deprecated(),
  cancel_on_error = FALSE
) {
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
