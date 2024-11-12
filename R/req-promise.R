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
#'
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
req_perform_promise <- function(req,
                                path = NULL,
                                pool = NULL) {
  check_installed(c("promises", "later"))
  check_string(path, allow_null = TRUE)

  if (missing(pool)) {
    if (!identical(later::current_loop(), later::global_loop())) {
      cli::cli_abort(c(
        "Must supply {.arg pool} when calling {.code later::with_temp_loop()}.",
        i = "Do you need {.code pool = curl::new_pool()}?"
      ))
    }
  }

  promises::promise(
    function(resolve, reject) {
      perf <- PerformancePromise$new(
        req = req,
        resolve = resolve,
        reject = reject,
        path = path,
        error_call = environment()
      )

      perf$submit(pool)
    }
  )
}

PerformancePromise <- R6Class("PerformancePromise", inherit = Performance,
  public = list(
    resolve = NULL,
    reject = NULL,

    initialize = function(req, resolve, reject, path = NULL, error_call = NULL) {
      progress <- create_progress_bar(config = FALSE)

      super$initialize(req = req, path = path, progress = progress, error_call = error_call)
      self$resolve <- resolve
      self$reject <- reject
    },

    submit = function(pool = NULL) {
      if (!is.null(self$resp)) {
        # cached
        self$resolve(self$resp)
        return()
      }
      super$submit(pool)
      ensure_pool_poller(pool, self$reject)
    },

    succeed = function(res) {
      tryCatch(
        {
          super$succeed(res)
          self$resolve(self$resp)
        },
        httr2_fail = function(cnd) self$reject(cnd$error),
        error = function(cnd) self$reject(cnd)
      )
    },

    fail = function(msg) {
      tryCatch(
        super$fail(msg),
        httr2_fail = function(cnd) self$reject(cnd$error),
        error = function(cnd) self$reject(cnd)
      )
    }
  ))

ensure_pool_poller <- function(pool, reject) {
  monitor <- pool_poller_monitor(pool)
  if (monitor$already_going()) return()

  poll_pool <- function(ready) {
    tryCatch(
      {
        status <- curl::multi_run(0, pool = pool)
        if (status$pending > 0) {
          fds <- curl::multi_fdset(pool = pool)
          later::later_fd(
            func = poll_pool,
            readfds = fds$reads,
            writefds = fds$writes,
            exceptfds = fds$exceptions,
            timeout = fds$timeout
          )
        } else {
          monitor$ending()
        }
      }, error = function(cnd) {
        monitor$ending()
        reject(cnd)
      }
    )
  }

  monitor$starting()
  poll_pool()
}

pool_poller_monitor <- function(pool) {
  pool_address <- obj_address(pool)
  list(
    already_going = function() env_get(the$pool_pollers, pool_address, default = FALSE),
    starting = function() env_poke(the$pool_pollers, pool_address, TRUE),
    ending = function() env_unbind(the$pool_pollers, pool_address)
  )
}
