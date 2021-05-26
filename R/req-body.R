#' Send data in request body
#'
#' @description
#' * `req_body_none()` sends an empty body.
#' * `req_body_file()` sends a local file
#' * `req_body_raw()` sends a string or raw vector.
#' * `req_body_json()` sends JSON encoded data.
#' * `req_body_form()` sends form encoded data.
#' * `req_body_multipart()` creates a multi-part body.
#'
#' Adding a body to a request will automatically switch the method to POST.
#'
#' @inheritParams req_fetch
#' @export
#' @examples
#' req <- req("http://httpbin.org/post")
#'
#' # Most APIs expect small amounts of data in either form or json encoded:
#' req %>%
#'   req_body_form(list(x = "A simple text string")) %>%
#'   req_dry_run()
#'
#' req %>%
#'   req_body_json(list(x = "A simple text string")) %>%
#'   req_dry_run()
#'
#' # For total control over the body, send a string or raw vector
#' req %>%
#'   req_body_raw("A simple text string") %>%
#'   req_dry_run()
#'
#' # There are two main ways that APIs expect entire files
#' path <- tempfile()
#' writeLines(letters[1:6], path)
#'
#' # You can send a single file as the body:
#' req %>%
#'   req_body_file(path) %>%
#'   req_dry_run()
#'
#' # You can send multiple files, or a mix of files and data
#' # with multipart encoding
#' req %>%
#'   req_body_multipart(list(a = curl::form_file(path), b = "some data")) %>%
#'   req_dry_run()
req_body_none <- function(req) {
  # Must override method, otherwise curl uses HEAD
  req <- req_method(req, "POST")
  req_options(req, nobody = TRUE)
}

#' @export
#' @rdname req_body_none
#' @param path Path to file to upload.
#' @param type Content type. For `req_body_file()`, the default
#'  will will attempt to guess from the extension of `path`.
req_body_file <- function(req, path, type = NULL) {
  size <- file.info(path)$size

  # Connection leaks if not completely uploaded
  con <- file(path, "rb")
  read <- function(nbytes, ...) {
    if (is.null(con)) {
      return(raw())
    }
    bin <- readBin(con, "raw", nbytes)
    if (length(bin) < nbytes) {
      close(con)
      con <<- NULL
    }
    bin
  }

  req <- req_headers(req, `Content-Type` = type %||% "")
  req_options(req,
    post = TRUE,
    readfunction = read,
    postfieldsize_large = size,
  )
}

#' @export
#' @rdname req_body_none
#' @param body A literal string or raw vector to send as body.
req_body_raw <- function(req, body, type = NULL) {
  if (is_string(body)) {
    body <- charToRaw(enc2utf8(body))
  }
  if (!is.raw(body)) {
    abort("`body` must be a raw vector or string")
  }

  # Need to override default content-type "application/x-www-form-urlencoded"
  req <- req_headers(req, `Content-Type` = type %||% "")
  req_options(req,
    post = TRUE,
    postfieldsize = length(body),
    postfields = body
  )
}

#' @export
#' @rdname req_body_none
#' @param data Data to include in body. For `req_body_json()` this can
#'   be any R data structure that can be serialised to JSON, for
#'   `req_body_form()` it should be a named list of simple values,
#'   and `req_body_multipart()` it should be a named list containing
#'   strings or objects produced by [curl::form_file()]/[curl::form_data()].
#' @param auto_unbox Should length-1 vectors be automatically "unboxed" to
#'   JSON scalars?
#' @param digits How many digits of precision should numbers use in JSON?
#' @param null Should `NULL` be translated to JSON's null (`"null"`)
#'   or an empty list (`"list"`).
#' @param ... Other arguments passed on to [jsonlite::toJSON()].
req_body_json <- function(req, data,
                          auto_unbox = TRUE,
                          digits = 22,
                          null = "null",
                          ...) {
  check_installed("jsonlite")
  json <- jsonlite::toJSON(data,
    auto_unbox = TRUE,
    digits = 22,
    null = null,
    ...
  )
  req_body_raw(req, json, "application/json")
}

#' @export
#' @rdname req_body_none
req_body_form <- function(req, data) {
  check_body_data(data)
  req_body_raw(req, httr:::compose_query(data), "application/x-www-form-urlencoded")
}

#' @export
#' @rdname req_body_none
req_body_multipart <- function(req, data) {
  check_body_data(data)
  # fields must be character, raw, curl::form_file, or curl::form_data
  req$fields <- data
  req
}

check_body_data <- function(data) {
  if (!is.list(data)) {
    abort("`data` must be a list")
  }
  if (!is_named(data)) {
    abort("All elements of `data` must be named")
  }
}
