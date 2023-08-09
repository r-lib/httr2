#' Send data in request body
#'
#' @description
#' * `req_body_file()` sends a local file.
#' * `req_body_raw()` sends a string or raw vector.
#' * `req_body_json()` sends JSON encoded data.
#' * `req_body_form()` sends form encoded data.
#' * `req_body_multipart()` creates a multi-part body.
#'
#' Adding a body to a request will automatically switch the method to POST.
#'
#' @inheritParams req_perform
#' @returns A modified HTTP [request].
#' @examples
#' req <- request(example_url()) %>%
#'   req_url_path("/post")
#'
#' # Most APIs expect small amounts of data in either form or json encoded:
#' req %>%
#'   req_body_form(x = "A simple text string") %>%
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
#'   req_body_multipart(a = curl::form_file(path), b = "some data") %>%
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
    abort("`body` must be a raw vector or string")
  }

  req_body(req, data = body, type = "raw", content_type = type %||% "")
}

#' @export
#' @rdname req_body
#' @param path Path to file to upload.
#' @param type Content type. For `req_body_file()`, the default
#'  will will attempt to guess from the extension of `path`.
req_body_file <- function(req, path, type = NULL) {
  check_request(req)
  if (!file.exists(path)) {
    abort("`path` does not exist")
  }

  # Need to override default content-type "application/x-www-form-urlencoded"
  req_body(req, data = new_path(path), type = "raw-file", content_type = type %||% "")
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
                          ...) {
  check_request(req)
  check_installed("jsonlite")

  params <- list2(
    auto_unbox = auto_unbox,
    digits = digits,
    null = null,
    ...
  )
  req_body(req, data = data, type = "json", params = params)
}

#' @export
#' @rdname req_body
#' @param ... <[`dynamic-dots`][rlang::dyn-dots]> Name-data pairs used send
#'   data in the body. For `req_body_form()`, the values must be strings (or
#'   things easily coerced to string); for `req_body_multipart()` the values
#'   must be strings or objects produced by
#'   [curl::form_file()]/[curl::form_data()].
#'
#'   For `req_body_json()`, additional arguments passed on to
#'   [jsonlite::toJSON()].
req_body_form <- function(.req, ...) {
  check_request(.req)

  data <- modify_body_data(.req$body$data, ...)
  req_body(.req, data = data, type = "form")
}

#' @export
#' @rdname req_body
req_body_multipart <- function(.req, ...) {
  check_request(.req)

  data <- modify_body_data(.req$body$data, ...)
  # data must be character, raw, curl::form_file, or curl::form_data
  req_body(.req, data = data, type = "multipart")
}

modify_body_data <- function(data, ...) {
  dots <- list2(...)
  if (length(dots) == 1 && !is_named(dots) && is.list(dots[[1]])) {
    warn("This function no longer takes a list, instead supply named arguments in ...", call = caller_env())
    modify_list(data, !!!dots[[1]])
  } else {
    modify_list(data, ...)
  }
}

# General structure -------------------------------------------------------

req_body <- function(req, data, type = NULL, params = list(), content_type = NULL) {
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

req_body_apply <- function(req) {
  if (is.null(req$body)) {
    return(req)
  }

  data <- req$body$data
  type <- req$body$type

  # Respect existing Content-Type if set
  type_idx <- match("content-type", tolower(names(req$headers)))
  if (!is.na(type_idx)) {
    content_type <- req$headers[[type_idx]]
    req$headers <- req$headers[-type_idx]
  } else {
    content_type <- req$body$content_type
  }

  if (type == "raw-file") {
    size <- file.info(data)$size
    con <- file(data, "rb")
    # Leaks connection if request doesn't complete
    readfunction <- function(nbytes, ...) {
      if (is.null(con)) {
        raw()
      } else {
        out <- readBin(con, "raw", nbytes)
        if (length(out) < nbytes) {
          close(con)
          con <<- NULL
        }
        out
      }
    }
    seekfunction <- function(offset, ...) {
      if (is.null(con)) {
        con <<- file(data, "rb")
      }
      seek(con, where = offset)
    }

    req <- req_options(req,
      post = TRUE,
      readfunction = readfunction,
      seekfunction = seekfunction,
      postfieldsize_large = size
    )
  } else if (type == "raw") {
    req <- req_body_apply_raw(req, data)
  } else if (type == "json") {
    content_type <- "application/json"
    json <- exec(jsonlite::toJSON, data, !!!req$body$params)
    req <- req_body_apply_raw(req, json)
  } else if (type == "multipart") {
    data <- unobfuscate(data)
    content_type <- NULL
    req$fields <- data
  } else if (type == "form") {
    data <- unobfuscate(data)
    content_type <- "application/x-www-form-urlencoded"
    req <- req_body_apply_raw(req, query_build(data))
  } else {
    abort("Unsupported request body `type`", .internal = TRUE)
  }

  # Must set header afterwards
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
