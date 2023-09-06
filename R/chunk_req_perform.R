#' Chunk a request
#'
#' @inheritParams req_perform
#' @param chunk_size The size of each chunk.
#' @param data The data to chunk.
#' @param apply_chunk A function that applies the chunk to the request. It
#'   takes two arguments:
#'
#'   1. `req`: the original request.
#'   2. `chunk`: the current data chunk.#'
#' @return For `req_chunk()` a list of requests. For `chunk_req_perform()` a
#'   list of parsed responses.
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
                      apply_chunk) {
  check_request(req)
  chunks <- vec_chop_by_size(data, chunk_size)
  check_function2(apply_chunk, args = c("req", "chunk"))

  n <- length(chunks)
  requests <- lapply(chunks, function(chunk) apply_chunk(req, chunk))
  new_chunked_request(requests, chunks)
}

#' @rdname req_chunk
#' @inheritParams paginate_req_perform
#' @param parse_resp A function with one argument `resp` that parses the
#'   response.
#' @param progress Whether to show a progress bar. Use `TRUE` to turn on a basic
#'   progress bar, use a string to give it a name, or see progress_bars for more
#'   details.
chunk_req_perform <- function(req,
                              data,
                              chunk_size,
                              apply_chunk,
                              parse_resp = NULL,
                              progress = TRUE) {
  chunked_requests <- req_chunk(
    req = req,
    data = data,
    chunk_size = chunk_size,
    apply_chunk = apply_chunk
  )
  requests <- chunked_requests$requests
  the$last_chunks <- chunked_requests$chunks

  parse_resp <- parse_resp %||% function(resp) resp
  check_function2(parse_resp, args = "resp")

  n <- length(requests)
  the$last_chunked_responses <- vector("list", n)

  pb <- create_progress_bar(total = n, name = "Request chunks", progress)
  show_progress <- !is.null(pb)

  for (i in seq2(1, n)) {
    req_i <- requests[[i]]
    resp_i <- req_perform(req_i)

    parsed <- parse_resp(resp_i)
    the$last_chunked_responses[[i]] <- parsed
    the$last_chunk_idx <- i

    if (show_progress) cli::cli_progress_update()
  }
  if (show_progress) cli::cli_progress_done()

  the$last_chunked_responses
}

#' @export
#' @rdname last_response
last_chunked_responses <- function() {
  the$last_chunked_responses[seq2(1, the$last_chunk_idx)]
}

#' @export
#' @rdname last_response
last_chunk <- function() {
  the$last_chunks[[the$last_chunk_idx]]
}

vec_chop_by_size <- function(x,
                             size,
                             x_arg = caller_arg(x),
                             size_arg = caller_arg(size),
                             error_call = caller_env()) {
  check_installed("vctrs", version = "0.6.0", call = error_call)
  vctrs::obj_check_vector(x, call = error_call, arg = x_arg)
  check_number_whole(size, min = 1, call = error_call, arg = size_arg)

  n <- vctrs::vec_size(x)
  sizes <- vctrs::vec_rep(size, n %/% size)
  if (n %% size != 0) {
    sizes <- c(sizes, n %% size)
  }
  sizes <- vctrs::vec_cast(sizes, integer())

  vctrs::vec_chop(x, sizes = sizes)
}

new_chunked_request <- function(requests, chunks) {
  structure(
    list(
      requests = requests,
      chunks = chunks
    ),
    class = "httr2_chunked_request"
  )
}

is_chunked_request <- function(x) {
  inherits(x, "httr2_chunked_request")
}

#' @export
print.httr2_chunked_request <- function(x, ..., redact_headers = TRUE) {
  n <- length(x$chunks)
  cli::cli_text("{.cls {class(x)}} - {n} chunks")
  cli::cli_text("\n")
  cli::cli_text("{.strong First chunk}\n")

  print(x$requests[[1]], redact_headers = redact_headers)

  invisible(x)
}
