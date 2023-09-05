#' Perform a request in chunks
#'
#' @inheritParams req_perform
#' @param chunk_size The size of each chunk.
#' @param data The data to chunk.
#' @param apply_chunk A function that applies the chunk to the request. It
#'   takes two arguments:
#'
#'   1. `req`: the original request.
#'   2. `chunk`: the current data chunk.
#' @param parse_resp A function with one argument `resp` that parses the
#'   response.
#'
#' @return A list of parsed responses.
#' @export
#'
#' @examples
#' ids <- 1:20
#' responses <- request("https://api.restful-api.dev/objects") %>%
#'   chunk_req_perform(
#'     chunk_size = 10,
#'     data = ids,
#'     req_prep = function(req, chunk) {
#'       chunk <- set_names(chunk, "id")
#'       req_url_query(req, !!!chunk)
#'     },
#'     parse_resp = function(resp) {
#'       # resp
#'       parsed <- resp_body_json(resp)
#'       data.frame(
#'         id = sapply(parsed, function(x) x$id),
#'         name = sapply(parsed, function(x) x$name)
#'       )
#'     }
#'   )
#'
#' responses
chunk_req_perform <- function(req,
                              data,
                              chunk_size,
                              apply_chunk,
                              parse_resp = NULL) {
  check_request(req)
  chunks <- vec_chop_by_size(data, chunk_size)
  check_function2(apply_chunk, args = c("req", "chunk"))
  parse_resp <- parse_resp %||% function(resp) resp
  check_function2(parse_resp, args = c("resp"))

  n <- length(chunks)
  the$last_chunked_responses <- vector("list", n)

  for (i in seq2(1, n)) {
    the$last_chunk_idx <- i

    chunk_i <- chunks[[i]]
    req_i <- apply_chunk(req, chunk_i)
    resp_i <- req_perform(req_i)

    parsed <- parse_resp(resp_i)
    the$last_chunked_responses[[i]] <- parsed
  }

  the$last_chunked_responses
}

vec_chop_by_size <- function(x, size, error_call = caller_env()) {
  check_installed("vctrs", version = "0.6.0", call = error_call)
  vctrs::obj_check_vector(x, call = error_call)
  check_number_whole(size, min = 1, call = error_call)

  n <- vctrs::vec_size(x)
  sizes <- vctrs::vec_rep(size, n %/% size)
  if (n %% size != 0) {
    sizes <- c(sizes, n %% size)
  }
  sizes <- vctrs::vec_cast(sizes, integer())

  vctrs::vec_chop(x, sizes = sizes)
}
