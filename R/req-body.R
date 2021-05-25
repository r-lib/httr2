
req_body_none <- function(req) {
  req_options_set(req, post = TRUE, nobody = TRUE)
}

req_body_file <- function(req, path, type = NULL) {
  size <- file.info(path)$size

  con <- file(body$path, "rb")
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

  req <- req_content_type(req, type, path = path)
  req <- req_options_set(req,
    post = TRUE,
    readfunction = read,
    postfieldsize_large = size,
  )
}

req_body_raw <- function(req, body, type = NULL) {
  if (is_string(body)) {
    body <- charToRaw(enc2utf8(body))
  } else if (is.raw(body)) {
    #
  } else {
    abort("`body` must be a raw vector or string")
  }

  # Need to override default POST content-type
  req <- req_content_type(req, type, default = "")
  req_options_set(req,
    post = TRUE,
    postfieldsize = length(body),
    postfields = body
  )
}

req_body_json <- function(req, auto_unbox = TRUE, digits = 22, null = "null", ...) {
  json <- jsonlite::toJSON(body, auto_unbox = TRUE, digits = 22, null = null, ...)
  req_body_raw(json, "application/json")
}

req_body_form <- function(req, ...) {
  fields <- list2(...)
  req_body_raw(httr:::compose_query(fields), "application/x-www-form-urlencoded")
}

req_body_multipart <- function(req, ...) {
  fields <- list2(...)
  if (!is_named(fields)) {
    abort("All body components must be named")
  }

  # fields must be character, raw, curl::form_file, or curl::form_data
  req$fields <- utils::modifyList(req$fields, fields)
  req
}


