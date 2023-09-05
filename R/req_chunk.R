chunk_req_perform <- function(req,
                              chunk_size,
                              data,
                              req_prep,
                              parse_resp = NULL) {
  check_request(req)
  vctrs::obj_check_vector(data)
  check_function2(req_prep, args = c("req", "chunk"))
  parse_resp <- parse_resp %||% function(resp) resp
  check_function2(parse_resp, args = c("resp"))

  chunks <- vec_chop_by_size(data, chunk_size)
  n <- length(chunks)
  the$last_chunked_responses <- vector("list", n)

  for (i in seq2(1, n)) {
    the$last_chunk_idx <- i

    chunk_i <- chunks[[i]]
    req_i <- req_prep(req, chunk_i)
    resp_i <- req_perform(req_i)

    parsed <- parse_resp(resp_i)
    the$last_chunked_responses[[i]] <- parsed
  }

  the$last_chunked_responses
}

vec_chop_by_size <- function(x, size) {
  check_installed("vctrs", version = "0.6.0")
  check_number_whole(size, min = 1)

  n <- vctrs::vec_size(x)
  sizes <- vctrs::vec_rep(size, n %/% size)
  if (n %% size != 0) {
    sizes <- c(sizes, n %% size)
  }
  sizes <- vctrs::vec_cast(sizes, integer())

  vctrs::vec_chop(x, sizes = sizes)
}
