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
#' @param type MIME content type. Will be ignored if you have manually set
#'  a `Content-Type` header.
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
req_body_raw <- function(req, body, type = NULL) {
  check_request(req)
  if (!is.raw(body) && !is_string(body)) {
    cli::cli_abort("{.arg body} must be a raw vector or string.")
  }

  req_body(
    req,
    data = body,
    type = "raw",
    content_type = type %||% ""
  )
}

#' @export
#' @rdname req_body
#' @param path Path to file to upload.
req_body_file <- function(req, path, type = NULL) {
  check_request(req)
  if (!file.exists(path)) {
    cli::cli_abort("{.arg path} ({.path {path}}) does not exist.")
  }

  # Need to override default content-type "application/x-www-form-urlencoded"
  req_body(
    req,
    data = new_path(path),
    type = "raw-file",
    content_type = type %||% ""
  )
}

#' @export
#' @rdname req_body
#' @param data Data to include in body.
#' @param auto_unbox Should length-1 vectors be automatically "unboxed" to
#'   JSON scalars?
#' @param digits How many digits of precision should numbers use in JSON?
#' @param null Should `NULL` be translated to JSON's null (`"null"`)
#'   or an empty list (`"list"`).
req_body_json <- function(req, data,
                          auto_unbox = TRUE,
                          digits = 22,
                          null = "null",
                          type = "application/json",
                          ...) {
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
  if (req$body$type != "json") {
    cli::cli_abort("Can only be used after {.fn req_body_json")
  }

  req$body$data <- utils::modifyList(req$body$data, list2(...))
  req
}

#' @export
#' @rdname req_body
#' @param ... <[`dynamic-dots`][rlang::dyn-dots]> Name-data pairs used to send
#'   data in the body.
#'
#'   * For `req_body_form()`, the values must be strings (or things easily
#'     coerced to strings);
#'   * For `req_body_multipart()` the values must be strings or objects
#'     produced by [curl::form_file()]/[curl::form_data()].
#'   * For `req_body_json_modify()`, any simple data made from atomic vectors
#'     and lists.
#'
#'   `req_body_json()` uses this argument differently; it takes additional
#'   arguments passed on to  [jsonlite::toJSON()].
#' @inheritParams req_url_query
req_body_form <- function(.req,
                          ...,
                          .multi = c("error", "comma", "pipe", "explode")) {
  check_request(.req)

  dots <- multi_dots(..., .multi = .multi)
  data <- modify_list(.req$body$data, !!!dots)
  req_body(
    .req,
    data = data,
    type = "form",
    content_type = "application/x-www-form-urlencoded"
  )
}

#' @export
#' @rdname req_body
req_body_multipart <- function(.req, ...) {
  check_request(.req)

  data <- modify_list(.req$body$data, ...)
  # data must be character, raw, curl::form_file, or curl::form_data
  req_body(
    .req,
    data = data,
    type = "multipart",
    content_type = NULL
  )
}

# General structure -------------------------------------------------------

req_body <- function(req, data, type, content_type, params = list(), error_call = parent.frame()) {
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
  if (is.null(req$body)) {
    "empty"
  } else {
    data <- req$body$data
    if (is.raw(data)) {
      glue("{length(data)} bytes of raw data")
    } else if (is_string(data)) {
      glue("a string")
    } else if (is_path(data)) {
      glue("path '{data}'")
    } else if (is.list(data)) {
      glue("{req$body$type} encoded data")
    } else {
      "invalid"
    }
  }
}

req_body_get <- function(req) {
  if (is.null(req$body)) {
    return("")
  }
  switch(
    req$body$type,
    raw = req$body$data,
    form = {
      data <- unobfuscate(req$body$data)
      query_build(data)
    },
    json = exec(jsonlite::toJSON, req$body$data, !!!req$body$params),
    cli::cli_abort("Unsupported request body type {.str {req$body$type}}.")
  )
}

req_body_apply <- function(req) {
  if (is.null(req$body)) {
    return(req)
  }

  data <- req$body$data
  type <- req$body$type

  if (type == "raw-file") {
    size <- file.info(data)$size
    # Only open connection if needed
    delayedAssign("con", file(data, "rb"))

    req <- req_policies(
      req,
      done = function() close(con)
    )
    req <- req_options(req,
      post = TRUE,
      readfunction = function(nbytes, ...) readBin(con, "raw", nbytes),
      seekfunction = function(offset, ...) seek(con, where = offset),
      postfieldsize_large = size
    )
  } else if (type == "raw") {
    req <- req_body_apply_raw(req, data)
  } else if (type == "json") {
    req <- req_body_apply_raw(req, req_body_get(req))
  } else if (type == "multipart") {
    data <- unobfuscate(data)
    req$fields <- data
  } else if (type == "form") {
    req <- req_body_apply_raw(req, req_body_get(req))
  } else {
    cli::cli_abort("Unsupported request body {.arg type}.", .internal = TRUE)
  }

  # Respect existing Content-Type if set
  type_idx <- match("content-type", tolower(names(req$headers)))
  if (!is.na(type_idx)) {
    content_type <- req$headers[[type_idx]]
    req$headers <- req$headers[-type_idx]
  } else {
    content_type <- req$body$content_type
  }
  req <- req_headers(req, `Content-Type` = content_type)

  req
}

req_body_apply_raw <- function(req, body) {
  if (is_string(body)) {
    body <- charToRaw(enc2utf8(body))
  }
  req_options(req,
    post = TRUE,
    postfieldsize = length(body),
    postfields = body
  )
}
