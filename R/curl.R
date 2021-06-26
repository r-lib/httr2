#' Translate curl syntax to httr2
#'
#' @description
#' The curl command line tool is commonly to demonstrate HTTP APIs and can
#' easily be be generated from
#' [browser developer tools](https://everything.curl.dev/usingcurl/copyas).
#' `curl_translate()` saves you the pain of manually translating these calls
#' by implementing a partial, but frequently used, subset of curl options.
#' Use `curl_help()` to see the supported options, and `curl_translate()`
#' to translate a curl invocation copy and pasted from elsewhere.
#'
#' Inspired by [curlconverter](https://github.com/hrbrmstr/curlconverter)
#' written by [Bob Rudis](http://rud.is/b).
#'
#' @param cmd Call to curl. If omitted and the clipr package is installed,
#'   will be retrieved from the clipboard.
#' @return A string containing the translated httr2 code. If the input
#'   was copied from the clipboard, the translation will be copied back
#'   to the clipboard.
#' @export
#' @examples
#' curl_translate("curl http://example.com")
#' curl_translate("curl http://example.com -X DELETE")
#' curl_translate("curl http://example.com --header A:1 --header B:2")
#' curl_translate("curl http://example.com --verbose")
curl_translate <- function(cmd) {
  if (missing(cmd)) {
    if (is_interactive() && is_installed("clipr")) {
      clip <- TRUE
      cmd <- clipr::read_clip()
    } else {
      abort("Must supply `cmd`")
    }
  } else {
    clip <- FALSE
  }
  data <- curl_normalize(cmd)

  out <- glue('request("{data$url}")')
  add_line <- function(x, y) {
    paste0(x, ' %>% \n  ', gsub("\n", "\n  ", y))
  }

  if (!is.null(data$method)) {
    out <- add_line(out, glue('req_method("{data$method}")'))
  }

  # Content type set with data
  type <- data$headers$`Content-Type`
  data$headers$`Content-Type` <- NULL

  if (length(data$headers) > 0) {
    names <- quote_name(names(data$headers))
    values <- encodeString(unlist(data$headers), quote = '"')
    args <- paste0("  ", names, " = ", values, ",\n", collapse = "")

    out <- add_line(out, paste0("req_headers(\n", args, ")"))
  }

  if (!identical(data$data, "")) {
    type <- encodeString(type %||% "application/x-www-form-urlencoded", quote = '"')
    body <- encodeString(data$data, quote = '"')
    out <- add_line(out, glue("req_body_raw({body}, {type})"))
  }

  if (!is.null(data$auth)) {
    out <- add_line(out, glue('req_auth_basic("{data$auth[[1]]}", "{data$auth[[2]]}")'))
  }

  if (data$verbose) {
    out <- add_line(out, "req_perform(verbosity = 1)")
  } else {
    out <- add_line(out, "req_perform()")
  }
  out <- paste0(out, "\n")

  if (clip) {
    cli::cli_alert_success("Copying to clipboard:")
    clipr::write_clip(out)
  }

  structure(out, class = "httr2_cmd")
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

curl_normalize <- function(cmd) {
  args <- curl_args(cmd)

  url <- args[["--url"]] %||% args[["<url>"]] %||% abort("Must supply url")

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
      username = pieces[[1]],
      password = pieces[[2]]
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
curl_opts <- "Usage: curl [<url>] [-H <header> ...] [options] [<url>]
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

curl_args <- function(cmd) {
  check_installed("docopt")

  pieces <- parse_in_half(cmd, " ")
  if (pieces[[1]] != "curl") {
    abort("Expecting call to curl")
  }
  if (grepl("'", cmd)) {
    args <- parse_delim(pieces[[2]], " ", quote = "'")
  } else {
    args <- parse_delim(pieces[[2]], " ", quote = '"')
  }

  parsed <- docopt::docopt(curl_opts, args = args, help = FALSE, strict = TRUE)

  # Drop default options
  parsed <- compact(parsed)
  is_false <- map_lgl(parsed, identical, FALSE)
  parsed <- parsed[!is_false]

  parsed
}


# Helpers -----------------------------------------------------------------

is_syntactic <- function(x) {
  x == make.names(x)
}
quote_name <- function(x) {
  ifelse(is_syntactic(x), x, encodeString(x, quote = "`"))
}
