#' Check the content type of a response
#'
#' A different content type than expected often leads to an error in parsing
#' the response body. This function checks that the content type of the response
#' is as expected and fails otherwise.
#'
#' @param valid_types A character vector of valid MIME types. Should only
#'   be specified with `type/subtype`.
#' @param valid_suffix A string given an "structured media type" suffix.
#' @param check_type Should the type actually be checked? Provided as a
#'   convenience for when using this function inside `resp_body_*` helpers.
#' @inheritParams resp_headers
#' @inheritParams rlang::args_error_context
#' @return Called for its side-effect; erroring if the response does not
#'   have the expected content type.
#' @export
#' @examples
#' resp <- response(headers = list(`content-type` = "application/json"))
#' resp_check_content_type(resp, "application/json")
#' try(resp_check_content_type(resp, "application/xml"))
#'
#' # `types` can also specify multiple valid types
#' resp_check_content_type(resp, c("application/xml", "application/json"))
resp_check_content_type <- function(resp,
                                    valid_types = NULL,
                                    valid_suffix = NULL,
                                    check_type = TRUE,
                                    call = caller_env()) {

  check_response(resp)
  check_character(valid_types, allow_null = TRUE)
  check_string(valid_suffix, allow_null = TRUE)
  check_bool(check_type, allow_na = TRUE)

  if (isFALSE(check_type)) {
    return(invisible())
  }

  check_content_type(
    resp_content_type(resp),
    valid_types = valid_types,
    valid_suffix = valid_suffix,
    inform_check_type = !is.na(check_type),
    call = call
  )
  invisible()
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
      type = "",
      subtype = "",
      suffix = ""
    )
    return(out)
  }

  match_object <- regexec(regex, x, perl = TRUE)
  match <- regmatches(x, match_object)[[1]]
  list(
    type = match[[2]],
    subtype = match[[3]],
    suffix = if (match[[4]] != "") match[[4]] else ""
  )
}

check_content_type <- function(content_type,
                               valid_types = NULL,
                               valid_suffix = NULL,
                               inform_check_type = FALSE,
                               call = caller_env()) {
  parsed <- parse_content_type(content_type)
  base_type <- paste0(parsed$type, "/", parsed$subtype)

  if (is.null(valid_types) || base_type %in% valid_types) {
    return()
  }
  if (!is.null(valid_suffix) && parsed$suffix == valid_suffix) {
    return()
  }

  msg <- "Expecting type {.or {.str {valid_types}}}"
  if (!is.null(valid_suffix)) {
    msg <- paste0(msg, " or suffix {.str {valid_suffix}}.")
  }

  cli::cli_abort(
    c("Unexpected content type {.str {content_type}}.", "*" = msg),
    i = if (inform_check_type) "Override check with `check_type = FALSE`.",
    call = call
  )
}


is_text_type <- function(content_type) {
  if (is.null(content_type)) {
    return(FALSE)
  }

  parsed <- parse_content_type(content_type)
  if (parsed$type == "text") {
    return(TRUE)
  }

  special_cases <- c(
    "application/xml",
    "application/x-www-form-urlencoded",
    "application/json",
    "application/ld+json",
    "multipart/form-data"
  )
  base_type <- paste0(parsed$type, "/", parsed$subtype)
  if (base_type %in% special_cases) {
    return(TRUE)
  }

  FALSE
}
