#' Perform requests iteratively, generating new requests from previous responses
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' `req_perform_iteratively()` iteratively generates and performs requests,
#' using a callback function, `next_req`, to define the next request based on
#' the current request and response. You will probably want to it pair with an
#' [iteration helper][iterate_with_offset] and use a
#' [multi-response handler][resps_combine] to process the result.
#'
#' @inheritParams req_perform
#' @param next_req A function that takes the previous response (`resp`) and
#'   request (`req`) and returns a [request] for the next page or `NULL` if
#'   the iteration should terminate.
#' @param max_reqs The maximum number of requests to perform. Use `Inf` to
#'   perform all requests until `next_req()` returns `NULL`.
#' @param progress Display a progress bar? Use `TRUE` to turn on a basic
#'   progress bar, use a string to give it a name, or see [progress_bars] to
#'   customise it in other ways.
#' @param path Optionally, path to save body of request. This should be
#'   a glue string that uses `{i}` to distinguish different requests.
#'   Useful for large responses because it avoids storing the response in
#'   memory.
#' @return A list of [response()]s.
#' @export
#' @examples
#' req <- request(example_url()) |>
#'   req_url_path("/iris") |>
#'   req_throttle(10) |>
#'   req_url_query(limit = 5)
#'
#' resps <- req_perform_iteratively(req, iterate_with_offset("page_index"))
#'
#' resps |> resps_combine(function(resp) {
#'   data <- resp_body_json(resp)$data
#'   data.frame(
#'     Sepal.Length = sapply(data, `[[`, "Sepal.Length"),
#'     Sepal.Width = sapply(data, `[[`, "Sepal.Width"),
#'     Petal.Length = sapply(data, `[[`, "Petal.Length"),
#'     Petal.Width = sapply(data, `[[`, "Petal.Width"),
#'     Species = sapply(data, `[[`, "Species")
#'   )
#' })
req_perform_iteratively <- function(req,
                                    next_req,
                                    path = NULL,
                                    max_reqs = 20,
                                    progress = TRUE) {
  check_request(req)
  check_function2(next_req, args = c("resp", "req"))
  check_number_whole(max_reqs, allow_infinite = TRUE, min = 1)
  check_string(path, allow_empty = FALSE, allow_null = TRUE)

  get_path <- function(i) {
    if (is.null(path)) {
      NULL
    } else {
      glue::glue(path)
    }
  }

  progress <- create_progress_bar(
    total = max_reqs,
    name = "Iterating",
    config = progress
  )

  resps <- vector("list", length = if (is.finite(max_reqs)) max_reqs else 100)
  i <- 1L

  tryCatch({
    repeat {
      resps[[i]] <- resp <- req_perform(req, path = get_path(i))
      progress$update()

      withCallingHandlers(
        {
          req <- next_req(resp = resp, req = req)
        },
        httr2_total_pages = function(cnd) {
          # Allow next_req() to shrink the number of pages remaining
          # Most important in max_req = Inf case
          if (cnd$n < max_reqs) {
            max_reqs <<- cnd$n
            progress$update(total = max_reqs)
          }
        }
      )

      if (is.null(req) || i >= max_reqs) {
        break
      }
      check_request(req, arg = "next_req()")

      i <- i + 1L
      if (i > length(resps)) {
        signal("", class = "httr2:::doubled")
        length(resps) <- length(resps) * 2
      }
    }
  }, interrupt = function(cnd) {
    # interrupt might occur after i was incremented
    if (is.null(resps[[i]])) {
      i <<- i - 1
    }
    cli::cli_alert_warning(
      "Terminating iteration; returning {i} response{?s}."
    )
  })
  progress$done()

  if (i < length(resps)) {
    resps <- resps[seq_len(i)]
  }

  resps
}
