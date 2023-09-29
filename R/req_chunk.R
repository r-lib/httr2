#' Chunk a request
#'
#' Use `req_chunk()` to specify how to request a chunk of data.
#' Use `chunk_req_perform()` to request all chunks.
#' If you need more control use a combination of [req_perform()] and
#' [multi_next_request()] to iterate through the chunks yourself.
#'
#' @inheritParams req_perform
#' @param chunk_size The size of each chunk.
#' @param data The vector to chunk.
#' @param apply_chunk A function that applies the chunk to the request. It
#'   takes two arguments:
#'
#'   1. `req`: the original request.
#'   2. `chunk`: the current data chunk.#'
#' @param parse_resp A function with one argument `resp` that parses the
#'   response.
#' @return For `req_chunk()` a list of requests. For `chunk_req_perform()` a
#'   list of parsed responses. If this argument is not specified, it will be a
#'   list of responses.
#' @export
#'
#' @examples
#' req <- request("https://api.restful-api.dev/objects")
#'
#' ids <- 1:7
#' chunk_size <- 3
#'
#' apply_chunk <- function(req, chunk) {
#'   chunk <- rlang::set_names(chunk, "id")
#'   req_url_query(req, !!!chunk)
#' }
#'
#' parse_resp <- function(resp) {
#'   parsed <- resp_body_json(resp)
#'   data.frame(
#'     id = sapply(parsed, function(x) x$id),
#'     name = sapply(parsed, function(x) x$name)
#'   )
#' }
#'
#' # in most cases `chunk_req_perform()` should be sufficient
#' \dontrun{
#' responses <- chunk_req_perform(
#'   req,
#'   chunk_size = 10,
#'   data = ids,
#'   apply_chunk = apply_chunk,
#'   parse_resp = parse_resp
#' )
#' }
#'
#' # in case you need more control of how the requests are performed you can create
#' # the requests first with `req_chunk()` ...
#' requests <- req_chunk(
#'   req,
#'   chunk_size = 3,
#'   data = ids,
#'   apply_chunk = apply_chunk
#' )
#'
#' # a simple list of requests
#' requests
#'
#' # ... which you can perform with `req_perform()`
#' \dontrun{
#' n <- length(requests)
#' paths <- character(n)
#' responses <- list()
#' for (i in seq2(1, n)) {
#'   paths[[i]] <- tempfile()
#'   responses[[i]] <- req_perform(requests[[i]], path = paths[[i]])
#' }
#' }
req_chunk <- function(req,
                      data,
                      chunk_size,
                      apply_chunk,
                      parse_resp = NULL) {
  check_request(req)
  vctrs::obj_check_vector(data)
  check_number_whole(chunk_size, min = 1)
  check_function2(apply_chunk, args = c("req", "chunk"))
  check_function2(parse_resp, args = "resp", allow_null = TRUE)
  parse_resp <- parse_resp %||% identity
  parse_resp_wrapped <- function(resp) {
    list(data = parse_resp(resp))
  }

  n <- vctrs::vec_size(data)
  n_chunks <- ceiling(n / chunk_size)
  n_requests <- n_chunks
  get_n_requests <- function(parsed) n_chunks

  chunk_next_request <- function(req, parsed) {
    check_request(req)

    req$policies$multi$cur_chunk <- req$policies$multi$cur_chunk + 1L
    i <- req$policies$multi$cur_chunk

    if (i > n_chunks) {
      return()
    }

    start <- (i - 1L) * chunk_size
    idx <- seq2(start + 1L, min(start + chunk_size, n))
    chunk <- vctrs::vec_slice(data, idx)

    apply_chunk(req, chunk)
  }

  req_multi_policy(
    req,
    parse_resp = parse_resp_wrapped,
    next_request = chunk_next_request,
    n_requests = n_requests,
    get_n_requests = get_n_requests,
    apply_chunk = apply_chunk,
    data = data,
    cur_chunk = 0L,
    chunk_size = chunk_size,
    size = n
  )
}
