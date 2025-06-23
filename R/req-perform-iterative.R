#' Perform requests iteratively, generating new requests from previous responses
#'
#' @description
#' `req_perform_iterative()` iteratively generates and performs requests,
#' using a callback function, `next_req`, to define the next request based on
#' the current request and response. You will probably want to pair it with an
#' [iteration helper][iterate_with_offset] and use a
#' [multi-response handler][resps_successes] to process the result.
#'
#' # `next_req()`
#'
#' The key piece that makes `req_perform_iterative()` work is the `next_req()`
#' argument. For most common cases, you can use one of the canned helpers,
#' like [iterate_with_offset()]. If, however, the API you're wrapping uses a
#' different pagination system, you'll need to write your own. This section
#' gives some advice.
#'
#' Generally, your function needs to inspect the response, extract some data
#' from it, then use that to modify the previous request. For example, imagine
#' that the response returns a cursor, which needs to be added to the body of
#' the request. The simplest version of this function might look like this:
#'
#' ```R
#' next_req <- function(resp, req) {
#'   cursor <- resp_body_json(resp)$next_cursor
#'   req |> req_body_json_modify(cursor = cursor)
#' }
#' ```
#'
#' There's one problem here: if there are no more pages to return, then
#' `cursor` will be `NULL`, but `req_body_json_modify()` will still generate
#' a meaningful request. So we need to handle this specifically by
#' returning `NULL`:
#'
#' ```R
#' next_req <- function(resp, req) {
#'   cursor <- resp_body_json(resp)$next_cursor
#'   if (is.null(cursor))
#'     return(NULL)
#'   req |> req_body_json_modify(cursor = cursor)
#' }
#' ```
#'
#' A value of `NULL` lets `req_perform_iterative()` know there are no more
#' pages remaining.
#'
#' There's one last feature you might want to add to your iterator: if you
#' know the total number of pages, then it's nice to let
#' `req_perform_iterative()` know so it can adjust the progress bar.
#' (This will only ever decrease the number of pages, not increase it.)
#' You can signal the total number of pages by calling [signal_total_pages()],
#' like this:
#'
#' ```R
#' next_req <- function(resp, req) {
#'   body <- resp_body_json(resp)
#'   cursor <- body$next_cursor
#'   if (is.null(cursor))
#'     return(NULL)
#'
#'   signal_total_pages(body$pages)
#'   req |> req_body_json_modify(cursor = cursor)
#' }
#' ```
#'
#' @inheritParams req_perform_sequential
#' @param req The first [request] to perform.
#' @param next_req A function that takes the previous response (`resp`) and
#'   request (`req`) and returns a [request] for the next page or `NULL` if
#'   the iteration should terminate. See below for more details.
#' @param max_reqs The maximum number of requests to perform. Use `Inf` to
#'   perform all requests until `next_req()` returns `NULL`.
#' @param on_error What should happen if a request fails?
#'
#'   * `"stop"`, the default: stop iterating with an error.
#'   * `"return"`: stop iterating, returning all the successful responses so
#'     far, as well as an error object for the failed request.
#' @param path Optionally, path to save the body of request. This should be
#'   a glue string that uses `{i}` to distinguish different requests.
#'   Useful for large responses because it avoids storing the response in
#'   memory.
#' @return
#' A list, at most length `max_reqs`, containing [response]s and possibly one
#' error object, if `on_error` is `"return"` and one of the requests errors.
#' If present, the error object will always be the last element in the list.
#'
#' Only httr2 errors are captured; see [req_error()] for more details.
#' @export
#' @examples
#' req <- request(example_url()) |>
#'   req_url_path("/iris") |>
#'   req_throttle(10) |>
#'   req_url_query(limit = 5)
#'
#' resps <- req_perform_iterative(req, iterate_with_offset("page_index"))
#'
#' data <- resps |> resps_data(function(resp) {
#'   data <- resp_body_json(resp)$data
#'   data.frame(
#'     Sepal.Length = sapply(data, `[[`, "Sepal.Length"),
#'     Sepal.Width = sapply(data, `[[`, "Sepal.Width"),
#'     Petal.Length = sapply(data, `[[`, "Petal.Length"),
#'     Petal.Width = sapply(data, `[[`, "Petal.Width"),
#'     Species = sapply(data, `[[`, "Species")
#'   )
#' })
#' str(data)
req_perform_iterative <- function(
  req,
  next_req,
  path = NULL,
  max_reqs = 20,
  on_error = c("stop", "return"),
  mock = getOption("httr2_mock", NULL),
  progress = TRUE
) {
  check_request(req)
  check_function2(next_req, args = c("resp", "req"))
  check_number_whole(max_reqs, allow_infinite = TRUE, min = 1)
  check_string(path, allow_empty = FALSE, allow_null = TRUE)
  on_error <- arg_match(on_error)
  mock <- as_mock_function(mock, error_call)

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

  tryCatch(
    repeat {
      httr2_error <- switch(
        on_error,
        stop = function(cnd) zap(),
        return = function(cnd) cnd
      )
      resp <- try_fetch(
        req_perform(req, path = get_path(i), mock = mock),
        httr2_error = httr2_error
      )
      resps[[i]] <- resp

      if (on_error == "return" && is_error(resp)) {
        break
      }

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
            progress$update(total = max_reqs, inc = 0)
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
    },
    interrupt = function(cnd) {
      check_repeated_interrupt()

      # interrupt might occur after i was incremented
      if (is.null(resps[[i]])) {
        i <<- i - 1
      }
      cli::cli_alert_warning(
        "Terminating iteration; returning {i} response{?s}."
      )
    }
  )
  progress$done()

  if (i < length(resps)) {
    resps <- resps[seq_len(i)]
  }

  resps
}
