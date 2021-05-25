
resp_header <- function(resp, header) {
  resp$headers[[tolower(header)]]
}
resp_header_exists <- function(resp, header) {
  has_name(resp$headers, tolower(header))
}

resp_content_type <- function(resp) {
  type <- resp_header(resp, "content-type")
  tryCatch(
    error = function(err) NA_character_,
    httr::parse_media(type)$complete
  )
}

resp_content_type_params <- function(resp) {
  type <- resp_header(resp, "content-type")
  tryCatch(
    error = function(err) NULL,
    httr::parse_media(type)$params
  )
}

resp_encoding <- function(resp) {
  encoding <- resp_content_type_params(resp)$charset

  if (is.null(encoding)) {
    warn("No encoding found; guessing UTF-8")
    "UTF-8"
  } else {
    encoding
  }
}

resp_has_content_type <- function(resp, types) {
  resp_type <- resp_content_type(resp)
  if (is.null(resp_type)) {
    FALSE
  } else {
    resp_type %in% types
  }
}

check_content_type <- function(resp, types, check_type = TRUE) {
  if (!check_type || resp_content_type(resp) %in% types) {
    return()
  }

  if (length(types) > 1) {
    type <- paste0("one of ", paste0("'", types, "'", collapse = ", "))
  } else {
    type <- type
  }
  abort(c(
    glue("Declared content type is not {type}"),
    i = "Override check with `check_type = FALSE`"
  ))
}
