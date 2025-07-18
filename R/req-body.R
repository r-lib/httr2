#' Send data in request body
#'
#' @description
#' * `req_body_file()` sends a local file.
#' * `req_body_raw()` sends a string or raw vector.
#' * `req_body_json()` sends JSON encoded data. Named components of this data
#'   can later be modified with `req_body_json_modify()`.
#' * `req_body_form()` sends form encoded data.
#' * `req_body_multipart()` creates a multi-part body.
#'
#' Adding a body to a request will automatically switch the method to POST.
#'
#' @inheritParams req_perform
#' @param type MIME content type. The default, `""`, will not emit a
#'   `Content-Type` header.  Ignored if you have set a `Content-Type` header
#'   with [req_headers()].
#' @returns A modified HTTP [request].
#' @examples
#' req <- request(example_url()) |>
#'   req_url_path("/post")
#'
#' # Most APIs expect small amounts of data in either form or json encoded:
#' req |>
#'   req_body_form(x = "A simple text string") |>
#'   req_dry_run()
#'
#' req |>
#'   req_body_json(list(x = "A simple text string")) |>
#'   req_dry_run()
#'
#' # For total control over the body, send a string or raw vector
#' req |>
#'   req_body_raw("A simple text string") |>
#'   req_dry_run()
#'
#' # There are two main ways that APIs expect entire files
#' path <- tempfile()
#' writeLines(letters[1:6], path)
#'
#' # You can send a single file as the body:
#' req |>
#'   req_body_file(path) |>
#'   req_dry_run()
#'
#' # You can send multiple files, or a mix of files and data
#' # with multipart encoding
#' req |>
#'   req_body_multipart(a = curl::form_file(path), b = "some data") |>
#'   req_dry_run()
#' @name req_body
#' @aliases NULL
NULL

#' @export
#' @rdname req_body
#' @param body A literal string or raw vector to send as body.
req_body_raw <- function(req, body, type = "") {
  check_request(req)
  check_string(type)

  if (is.raw(body)) {
    req_body(req, data = body, type = "raw", content_type = type)
  } else if (is_string(body)) {
    req_body(req, data = body, type = "string", content_type = type)
  } else {
    cli::cli_abort("{.arg body} must be a raw vector or string.")
  }
}

#' @export
#' @rdname req_body
#' @param path Path to file to upload.
req_body_file <- function(req, path, type = "") {
  check_request(req)
  check_string(path)
  if (!file.exists(path)) {
    cli::cli_abort("Can't find file {.path {path}}.")
  } else if (dir.exists(path)) {
    cli::cli_abort("{.arg path} must be a file, not a directory.")
  }
  check_string(type)

  req_body(req, data = path, type = "file", content_type = type)
}

#' @export
#' @rdname req_body
#' @param data Data to include in body.
#' @param auto_unbox Should length-1 vectors be automatically "unboxed" to
#'   JSON scalars?
#' @param digits How many digits of precision should numbers use in JSON?
#' @param null Should `NULL` be translated to JSON's null (`"null"`)
#'   or an empty list (`"list"`).
req_body_json <- function(
  req,
  data,
  auto_unbox = TRUE,
  digits = 22,
  null = "null",
  type = "application/json",
  ...
) {
  check_request(req)
  check_installed("jsonlite")
  check_string(type)
  check_content_type(type, "application/json", "json")

  params <- list2(
    auto_unbox = auto_unbox,
    digits = digits,
    null = null,
    ...
  )
  req_body(
    req,
    data = data,
    type = "json",
    content_type = type,
    params = params
  )
}

#' @export
#' @rdname req_body
req_body_json_modify <- function(req, ...) {
  check_request(req)
  if (!req_get_body_type(req) %in% c("empty", "json")) {
    cli::cli_abort("Can only be used after {.fn req_body_json}.")
  }

  req$body$data <- utils::modifyList(req$body$data %||% list(), list2(...))
  req
}

#' @export
#' @rdname req_body
#' @param ... <[`dynamic-dots`][rlang::dyn-dots]> Name-data pairs used to send
#'   data in the body.
#'
#'   * For `req_body_form()`, the values must be strings (or things easily
#'     coerced to strings). Vectors are converted to strings using the
#'     value of `.multi`.
#'   * For `req_body_multipart()` the values must be strings or objects
#'     produced by [curl::form_file()]/[curl::form_data()].
#'   * For `req_body_json_modify()`, any simple data made from atomic vectors
#'     and lists.
#'
#'   `req_body_json()` uses this argument differently; it takes additional
#'   arguments passed on to  [jsonlite::toJSON()].
#' @inheritParams req_url_query
req_body_form <- function(
  .req,
  ...,
  .multi = c("error", "comma", "pipe", "explode")
) {
  check_request(.req)

  dots <- multi_dots(..., .multi = .multi)
  data <- modify_list(.req$body$data, !!!dots)
  req_body(.req, data = data, type = "form")
}

#' @export
#' @rdname req_body
req_body_multipart <- function(.req, ...) {
  check_request(.req)

  data <- modify_list(.req$body$data, ...)
  # data must be character, raw, curl::form_file, or curl::form_data
  req_body(.req, data = data, type = "multipart")
}

# General structure -------------------------------------------------------

req_body <- function(
  req,
  data,
  type,
  content_type = NULL,
  params = list(),
  error_call = parent.frame()
) {
  # If this changes, also update docs in req_get_body_type()
  arg_match(type, c("raw", "string", "file", "json", "form", "multipart"))

  if (!is.null(req$body) && req$body$type != type) {
    cli::cli_abort(
      c(
        "Can't change body type from {req$body$type} to {type}.",
        i = "You must use only one type of `req_body_*()` per request."
      ),
      call = error_call
    )
  }

  req$body <- list(
    data = data,
    type = type,
    content_type = content_type,
    params = params
  )
  req
}

req_body_info <- function(req) {
  switch(
    req_get_body_type(req),
    empty = "empty",
    raw = glue("a {length(req$body$data)} byte raw vector"),
    string = "a string",
    file = glue("a path '{req$body$data}'"),
    json = "JSON data",
    form = "form data",
    multipart = "multipart data"
  )
}


#' Get request body
#'
#' @description
#' This pair of functions gives you sufficient information to capture the
#' body of a request, and recreate, if needed. httr2 currently supports
#' seven possible body types:
#'
#' * empty: no body.
#' * raw: created by [req_body_raw()] with a raw vector.
#' * string: created by [req_body_raw()] with a string.
#' * file: created by [req_body_file()].
#' * json: created by [req_body_json()]/[req_body_json_modify()].
#' * form: created by [req_body_form()].
#' * multipart: created by [req_body_multipart()].
#'
#' @inheritParams req_perform
#' @export
#' @examples
#' req <- request(example_url())
#' req |> req_body_raw("abc") |> req_get_body_type()
#' req |> req_body_file(system.file("DESCRIPTION")) |> req_get_body_type()
#' req |> req_body_json(list(x = 1, y = 2)) |> req_get_body_type()
#' req |> req_body_form(x = 1, y = 2) |> req_get_body_type()
#' req |> req_body_multipart(x = "x", y = "y") |> req_get_body_type()
req_get_body_type <- function(req) {
  check_request(req)
  req$body$type %||% "empty"
}

#' @export
#' @rdname req_get_body_type
#' @param obfuscated What to do with obfuscated values that can be present in
#'   JSON, form, and multipart bodies?
#'   * `"remove"` (the default) replaces them with `NULL`.
#'   * `"redact"` replaces them with `<REDACTED>`.
#'   * `"reveal"` leaves them in place.
#' @param obfuscated Form and JSON bodies can contain [obfuscated] values.
#'   This argument control what happens to them: should they be removed,
#'   redacted, or revealed.
req_get_body <- function(req, obfuscated = c("remove", "redact", "reveal")) {
  check_request(req)
  obfuscated <- arg_match(obfuscated)

  data <- req$body$data
  if (req_get_body_type(req) %in% c("json", "form", "multipart")) {
    data <- unobfuscate(data, obfuscated)
  }
  data
}

req_body_apply <- function(req) {
  req <- switch(
    req_get_body_type(req),
    empty = req,
    raw = ,
    string = req_body_apply_data(req, req$body$data),
    file = req_body_apply_stream(req, req$body$data),
    json = ,
    form = req_body_apply_data(req, req_body_render(req)),
    multipart = req_body_apply_multipart(req, req$body$data),
  )

  # Set Content-Type if not already set
  if (!is.null(req$body$content_type) && is.null(req$headers$`Content-Type`)) {
    req <- req_headers(req, `Content-Type` = req$body$content_type)
  }

  req
}

# Needed for JSON and form types since these have special representation
# in httr2 but not curl.
req_body_render <- function(req) {
  type <- req_get_body_type(req)
  switch(
    type,
    form = url_query_build(unobfuscate(req$body$data)),
    json = unclass(exec(
      jsonlite::toJSON,
      unobfuscate(req$body$data),
      !!!req$body$params
    )),
    cli::cli_abort("Unsupported type {type}", .internal = TRUE)
  )
}

req_body_apply_data <- function(req, data) {
  if (is_string(data)) {
    data <- charToRaw(enc2utf8(data))
  }
  req_options(req, post = TRUE, postfieldsize = length(data), postfields = data)
}
req_body_apply_stream <- function(req, data) {
  size <- file.info(data)$size
  # Only open connection if needed
  delayedAssign("con", file(data, "rb"))

  req <- req_policies(req, done = function() close(con))
  req <- req_options(
    req,
    post = TRUE,
    readfunction = function(nbytes, ...) readBin(con, "raw", nbytes),
    seekfunction = function(offset, ...) seek(con, where = offset),
    postfieldsize_large = size
  )
  req
}
req_body_apply_multipart <- function(req, data) {
  req$fields <- unobfuscate(req$body$data)
  req
}
