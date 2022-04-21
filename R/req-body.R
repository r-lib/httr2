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
#' req <- request("http://httpbin.org/post")
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

  req_body(req, data = body, type = type %||% "")
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
  req_body(req, data = new_path(path), type = type %||% "")
}

#' @export
#' @rdname req_body
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
  check_request(req)
  check_body_data(data)
  check_installed("jsonlite")

  params <- list2(
    auto_unbox = auto_unbox,
    digits = digits,
    null = null,
    ...
  )

  data <- merge_body_data(req$body$data, data)

  req_body(req, data = data, type = "json", params = params)
}

#' @export
#' @rdname req_body
req_body_form <- function(req, data) {
  check_request(req)
  check_body_data(data)

  data <- merge_body_data(req$body$data, data)

  req_body(req, data = data, type = "form")
}

#' @export
#' @rdname req_body
req_body_multipart <- function(req, data) {
  check_request(req)
  check_body_data(data)

  data <- merge_body_data(req$body$data, data)

  # data must be character, raw, curl::form_file, or curl::form_data
  req_body(req, data = data, type = "multipart")
}

# General structure -------------------------------------------------------

req_body <- function(req, data, type = NULL, params = list()) {
  req$body <- list(
    data = data,
    type = type,
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

  if (is_path(data)) {
    size <- file.info(data)$size
    con <- file(data, "rb")
    # Leaks connection if request doesn't complete
    read <- function(nbytes, ...) {
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
    req <- req_options(req,
      post = TRUE,
      readfunction = read,
      postfieldsize_large = size
    )
  } else if (is.raw(data) || is_string(data)) {
    req <- req_body_apply_raw(req, data)
  } else if (is.list(data)) {
    data <- unobfuscate(data)
    if (type == "multipart") {
      type <- NULL
      req$fields <- data
    } else if (type == "form") {
      type <- "application/x-www-form-urlencoded"
      req <- req_body_apply_raw(req, query_build(data))
    } else if (type == "json") {
      type <- "application/json"
      json <- exec(jsonlite::toJSON, data, !!!req$body$params)
      req <- req_body_apply_raw(req, json)
    } else {
      abort("Unsupported request body `type`")
    }
  } else {
    abort("Unsupported request body `data`")
  }

  # Must set header afterwards
  req <- req_headers(req, `Content-Type` = type)
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


# Helpers -----------------------------------------------------------------

check_body_data <- function(data) {
  if (!is.list(data)) {
    abort("`data` must be a list")
  }
  if (!is_named(data)) {
    abort("All elements of `data` must be named")
  }
}

merge_body_data <- function(old, new) {

  if (!is.object(new) && !is.object(old)) {
    return(modify_list(old, !!!new))
  }

  if (length(old)) {
    warn(glue::glue("Replacing existing body, {friendly_type_of(old)}, with {friendly_type_of(new)}"))
  }

  new
}
