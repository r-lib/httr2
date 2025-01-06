#' Translate curl syntax to httr2
#'
#' @description
#' The curl command line tool is commonly used to demonstrate HTTP APIs and can
#' easily be generated from
#' [browser developer tools](https://everything.curl.dev/cmdline/copyas.html).
#' `curl_translate()` saves you the pain of manually translating these calls
#' by implementing a partial, but frequently used, subset of curl options.
#' Use `curl_help()` to see the supported options, and `curl_translate()`
#' to translate a curl invocation copy and pasted from elsewhere.
#'
#' Inspired by [curlconverter](https://github.com/hrbrmstr/curlconverter)
#' written by [Bob Rudis](https://rud.is/b/).
#'
#' @param cmd Call to curl. If omitted and the clipr package is installed,
#'   will be retrieved from the clipboard.
#' @param simplify_headers Remove typically unimportant headers included when
#'   copying a curl command from the browser. This includes:
#'
#'   * `sec-fetch-*`
#'   * `sec-ch-ua*`
#'   * `referer`, `pragma`, `connection`
#' @returns A string containing the translated httr2 code. If the input
#'   was copied from the clipboard, the translation will be copied back
#'   to the clipboard.
#' @export
#' @examples
#' curl_translate("curl http://example.com")
#' curl_translate("curl http://example.com -X DELETE")
#' curl_translate("curl http://example.com --header A:1 --header B:2")
#' curl_translate("curl http://example.com --verbose")
curl_translate <- function(cmd, simplify_headers = TRUE) {
  if (missing(cmd)) {
    if (is_interactive() && is_installed("clipr")) {
      clip <- TRUE
      cmd <- clipr::read_clip()
      cmd <- paste0(cmd, collapse = "\n")
    } else {
      cli::cli_abort("Must supply {.arg cmd}.")
    }
  } else {
    check_string(cmd)
    clip <- FALSE
  }
  data <- curl_normalize(cmd)

  url_pieces <- httr2::url_parse(data$url)
  query <- url_pieces$query
  url_pieces$query <- NULL
  url <- url_build(url_pieces)

  steps <- glue('request("{url}")')
  steps <- add_curl_step(steps, "req_method", main_args = data$method)

  steps <- add_curl_step(steps, "req_url_query", dots = query)

  # Content type set with data
  type <- data$headers$`Content-Type`
  if (!identical(data$data, "")) {
    data$headers$`Content-Type` <- NULL
  }

  headers <- curl_simplify_headers(data$headers, simplify_headers)
  steps <- add_curl_step(steps, "req_headers", dots = headers)

  if (!identical(data$data, "")) {
    type <- type %||% "application/x-www-form-urlencoded"
    body <- data$data
    steps <- add_curl_step(steps, "req_body_raw", main_args = c(body, type))
  }

  steps <- add_curl_step(steps, "req_auth_basic", main_args = unname(data$auth))

  perform_args <- list()
  if (data$verbose) {
    perform_args$verbosity <- 1
  }
  steps <- add_curl_step(steps, "req_perform", main_args = perform_args, keep_if_empty = TRUE)

  out <- paste0(steps, collapse = paste0(pipe(), "\n  "))
  out <- paste0(out, "\n")

  if (clip) {
    cli::cli_alert_success("Copying to clipboard:")
    clipr::write_clip(out)
  }

  structure(out, class = "httr2_cmd")
}

pipe <- function() {
  if (getRversion() >= "4.1.0") " |> " else " %>% "
}

#' @export
print.httr2_cmd <- function(x, ...) {
  cat(x)
  invisible(x)
}

#' @rdname curl_translate
#' @export
curl_help <- function() {
  cat(curl_opts)
}

curl_translate_eval <- function(cmd, env = caller_env()) {
  code <- curl_translate(cmd)
  eval(parse_expr(code), envir = env)
}

curl_normalize <- function(cmd, error_call = caller_env()) {
  args <- curl_args(cmd, error_call = error_call)

  url <- args[["--url"]] %||%
    args[["<url>"]] %||%
    cli::cli_abort("Must supply url.", call = error_call)

  if (has_name(args, "--header")) {
    headers <- as_headers(args[["--header"]])
  } else {
    headers <- as_headers(list())
  }
  if (has_name(args, "--referer")) {
    headers[["referer"]] <- args[["--referer"]]
  }
  if (has_name(args, "--user-agent")) {
    headers[["user-agent"]] <- args[["--user-agent"]]
  }

  if (has_name(args, "--user")) {
    pieces <- parse_in_half(args[["--user"]], ":")
    auth <- list(
      username = pieces$left,
      password = pieces$right
    )
  } else {
    auth <- NULL
  }

  if (has_name(args, "--request")) {
    method <- args[["--request"]]
  } else if (has_name(args, "--head")) {
    method <- "HEAD"
  } else if (has_name(args, "--get")) {
    method <- "GET"
  } else {
    method <- NULL
  }

  # https://curl.se/docs/manpage.html#-d
  # --data-ascii, --data
  #   * if first element is @, treat as path to read from, stripping CRLF
  #   * if multiple, combine with &
  # --data-raw - like data, but don't handle @ specially
  # --data-binary - like data, but don't strip CRLF
  # --data-urlencode - not supported for now
  data <- unlist(c(
    lapply(args[["--data"]], curl_data),
    lapply(args[["--data-ascii"]], curl_data),
    lapply(args[["--data-raw"]], curl_data, raw = TRUE),
    lapply(args[["--data-binary"]], curl_data, binary = TRUE)
  ))
  data <- paste0(data, collapse = "&")

  list(
    method = method,
    url = url,
    headers = headers,
    auth = auth,
    verbose = isTRUE(args[["--verbose"]]),
    data = data
  )
}

curl_simplify_headers <- function(headers, simplify_headers) {
  if (simplify_headers) {
    header_names <- tolower(names(headers))
    to_drop <- startsWith(header_names, "sec-fetch") |
      startsWith(header_names, "sec-ch-ua") |
      header_names %in% c("referer", "pragma", "connection")
    headers <- headers[!to_drop]
  }

  headers
}

curl_data <- function(x, binary = FALSE, raw = FALSE) {
  if (!raw && grepl("^@", x)) {
    path <- sub("^@", "", x)
    if (binary) {
      x <- readBin(path, "character", n = file.size(path))
    } else {
      x <- paste(readLines(path, warn = FALSE))
    }
  } else {
    x
  }
}

# Format described at <http://docopt.org>
curl_opts <- "Usage: curl [<url>] [-H <header> ...] [-d <data> ...] [options] [<url>]
      --basic                  (IGNORED)
      --compressed             (IGNORED)
      --digest                 (IGNORED)
  -d, --data <data>            HTTP POST data
      --data-raw <data>        HTTP POST data, '@' allowed
      --data-ascii <data>      HTTP POST ASCII data
      --data-binary <data>     HTTP POST binary data
      --data-urlencode <data>  HTTP POST data url encoded
  -G, --get                    Put the post data in the URL and use GET
  -I, --head                   Show document info only
  -H, --header <header>        Pass custom header(s) to server
  -i, --include                (IGNORED)
  -k, --insecure               (IGNORED)
  -L, --location               (IGNORED)
  -m, --max-time <seconds>     Maximum time allowed for the transfer
  -u, --user <user:password>   Server user and password
  -A, --user-agent <name>      Send User-Agent STRING to server
  -#, --progress-bar           Display transfer progress as a progress bar
  -e, --referer <referer>      Referer URL
  -X, --request <command>      Specify request command to use
      --url <url>              URL to work with
  -v, --verbose                Make the operation more talkative
"

curl_args <- function(cmd, error_call = caller_env()) {
  check_installed("docopt")

  pieces <- parse_in_half(cmd, " ")
  if (pieces$left != "curl") {
    cli::cli_abort(
      "Expecting call to {.str curl} not to {.str {pieces[[1]]}}.",
      call = error_call
    )
  }
  if (grepl("'", cmd, fixed = TRUE)) {
    args <- parse_delim(pieces$right, " ", quote = "'")
  } else {
    args <- parse_delim(pieces$right, " ", quote = '"')
  }

  args <- args[args != "" & args != "\\"]

  parsed <- docopt::docopt(curl_opts, args = args, help = FALSE, strict = TRUE)

  # Drop default options
  parsed <- compact(parsed)
  is_false <- map_lgl(parsed, identical, FALSE)
  parsed <- parsed[!is_false]

  parsed
}


# Helpers -----------------------------------------------------------------

is_syntactic <- function(x) {
  x == "" | x == make.names(x)
}
quote_name <- function(x) {
  ifelse(is_syntactic(x), x, encodeString(x, quote = "`"))
}

add_curl_step <- function(steps,
                          f,
                          ...,
                          main_args = NULL,
                          dots = NULL,
                          keep_if_empty = FALSE) {
  check_dots_empty0(...)
  args <- c(main_args, dots)

  if (is_empty(args) && !keep_if_empty) {
    return(steps)
  }

  names <- quote_name(names2(args))
  string <- vapply(args, is.character, logical(1L))
  values <- unlist(args)
  values <- ifelse(string, encode_string2(values), values)

  args_named <- ifelse(
    names == "",
    paste0(values),
    paste0(names, " = ", values)
  )
  if (is_empty(dots)) {
    args_string <- paste0(args_named, collapse = ", ")
    new_step <- paste0(f, "(", args_string, ")")
  } else {
    args_string <- paste0("    ", args_named, ",\n", collapse = "")
    new_step <- paste0(f, "(\n", args_string, "  )")
  }

  c(steps, new_step)
}

encode_string2 <- function(x) {
  supports_raw_string <- getRversion() >= "4.0.0"

  has_double_quote <- grepl('"', x, fixed = TRUE)
  has_single_quote <- grepl("'", x, fixed = TRUE)
  use_double <- !has_double_quote | has_single_quote
  out <- ifelse(
    use_double,
    encodeString(x, quote = '"'),
    encodeString(x, quote = "'")
  )
  if (supports_raw_string) {
    has_unprintable <- grepl("[^[[:cntrl:]]]", x)
    x_encoded <- encodeString(x)
    has_both_quotes <- has_double_quote & has_single_quote
    use_raw_string <- !has_unprintable & (x != x_encoded | has_both_quotes)
    out[use_raw_string] <- paste0('r"---{', x[use_raw_string], '}---"')
  }

  names(out) <- names(x)
  out
}
