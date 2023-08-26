#' Check the content type of a response
#'
#' A different content type than expected often leads to an error in parsing
#' the response body. This function checks that the content type of the response
#' is as expected and fails otherwise.
#'
#' @param resp A response object.
#' @param types A character vector of valid content types.
#' @param check_type Should the type actually be checked? Provide as a
#'   convenience for when using inside `resp_body_*` helpers.
#' @inheritParams rlang::args_error_context
#' @return Called for its side-effect; erroring if the response does not
#'   have the expected content type.
#' @export
#' @examples
#' resp <- response(headers = list(`content-type` = "application/json"))
#' check_resp_content_type(resp, "application/json")
#' try(check_resp_content_type(resp, "application/xml"))
#'
#' # `types` can also specify multiple valid types
#' check_resp_content_type(resp, c("application/xml", "application/json"))
check_resp_content_type <- function(resp,
                                    types,
                                    check_type = TRUE,
                                    call = caller_env()) {
  check_response(resp)
  check_character(types)
  check_bool(types)

  if (!check_type) {
    return(invisible())
  }

  content_type <- resp_content_type(resp)
  check_content_type(
    content_type,
    types,
    inform_check_type = TRUE,
    call = call
  )
}

parse_content_type <- function(x) {
  # Create regex with {rex} package
  #
  # ```
  # library(rex)
  # # see https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types for the
  # # possible types
  # types <- c("application", "audio", "font", "example", "image", "message", "model", "multipart", "text", "video")
  # regex <- rex(
  #   start,
  #   capture(regex(paste0(types, collapse = "|")), name = "type"),
  #   "/",
  #   capture(
  #     maybe(or("vnd", "prs", "x"), "."),
  #     one_or_more(none_of("+;")),
  #     name = "subtype"
  #   ),
  #   maybe("+", capture(one_or_more(none_of(";")), name = "suffix")),
  #   maybe(";", capture(one_or_more(any), name = "parameters")),
  #   end
  # )
  # unclass(regex)
  # ```
  stopifnot(length(x) == 1)
  regex <- "^(?<type>application|audio|font|example|image|message|model|multipart|text|video)/(?<subtype>(?:(?:vnd|prs|x)\\.)?(?:[^+;])+)(?:\\+(?<suffix>(?:[^;])+))?(?:;(?<parameters>(?:.)+))?$"
  if (!grepl(regex, x, perl = TRUE)) {
    out <- list(
      type = NULL,
      subtype = NULL,
      suffix = NULL
    )
    return(out)
  }

  match_object <- regexec(regex, x, perl = TRUE)
  match <- regmatches(x, match_object)[[1]]
  list(
    type = match[[2]],
    subtype = match[[3]],
    suffix = if (match[[4]] != "") match[[4]]
  )
}

check_content_type <- function(content_type,
                               valid_types,
                               inform_check_type = FALSE,
                               call = caller_env()) {
  if (content_type %in% valid_types) {
    return(invisible())
  }

  content_type_parsed <- parse_content_type(content_type)
  valid_types_parsed <- lapply(valid_types, parse_content_type)

  for (i in seq_along(valid_types_parsed)) {
    if (has_content_type(content_type_parsed, valid_types_parsed[[i]])) {
      return(invisible())
    }
  }

  valid_types_msg <- vapply(valid_types_parsed, content_type_msg, character(1))
  if (length(valid_types) > 1) {
    valid_types_msg <- c(i = "Expecting one of:", set_names(valid_types_msg, "*"))
  } else {
    valid_types_msg <- c(i = paste0("Expecting ", valid_types_msg))
  }

  abort(c(
    glue("Unexpected content type '{content_type}'"),
    valid_types_msg,
    i = if (inform_check_type) "Override check with `check_type = FALSE`"
  ), call = call)
}

has_content_type <- function(is, exp) {
  # compare whole type in case `exp` has a suffix
  if (!is.null(exp$suffix)) {
    out <- identical(is, exp)
    return(out)
  }

  if (!is.null(is$suffix)) {
    is <- list(type = is$type, subtype = is$suffix, suffix = NULL)
  }

  identical(is, exp)
}

content_type_msg <- function(x) {
  if (is.null(x$suffix)) {
    glue("'{x$type}/{x$subtype}' or '{x$type}/<subtype>+{x$subtype}'")
  } else {
    glue("'{x$type}/{x$subtype}+{x$suffix}'")
  }
}
