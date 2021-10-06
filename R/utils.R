bullets_with_header <- function(header, x) {
  if (length(x) == 0) {
    return()
  }

  cli::cli_text("{.strong {header}}")

  as_simple <- function(x) {
    if (is.atomic(x) && length(x) == 1) {
      if (is.character(x)) {
        paste0("'", x, "'")
      } else {
        format(x)
      }
    } else {
      friendly_type_of(x)
    }
  }
  vals <- map_chr(x, as_simple)

  cli::cli_li(paste0("{.field ", names(x), "}: ", vals))
}

modify_list <- function(.x, ...) {
  dots <- list2(...)
  if (length(dots) == 0) return(.x)

  if (!is_named(dots)) {
    abort("All components of ... must be named")
  }
  .x[names(dots)] <- dots
  out <- compact(.x)
  if (length(out) == 0) {
    names(out) <- NULL
  }

  out
}


sys_sleep <- function(seconds) {
  check_number(seconds, "`seconds`")

  if (seconds > 0) {
    # TODO: add progress bar
    signal("", class = "httr2_sleep", seconds = seconds)
    Sys.sleep(seconds)
  }

  invisible()
}

check_string <- function(x, name, optional = TRUE) {
  if (is_string(x) && !is.na(x)) {
    return()
  }
  if (optional && is.null(x)) {
    return()
  }
  abort(glue("{name} must be a string"))
}

check_number <- function(x, name) {
  if ((is_double(x, n = 1) || is_integer(x, n = 1)) && !is.na(x)) {
    return()
  }
  abort(glue("{name} must be a number"))
}

is_error <- function(x) inherits(x, "error")

unix_time <- function() as.integer(Sys.time())

is_testing <- function() {
  identical(Sys.getenv("TESTTHAT"), "true")
}

# https://datatracker.ietf.org/doc/html/rfc7636#appendix-A
base64_url_encode <- function(x) {
  x <- openssl::base64_encode(x)
  x <- gsub("=+$", "", x)
  x <- gsub("+", "-", x, fixed = TRUE)
  x <- gsub("/", "_", x, fixed = TRUE)
  x
}

base64_url_decode <- function(x) {
  mod4 <- nchar(x) %% 4
  if (mod4 > 0) {
    x <- paste0(x, strrep("=", 4 - mod4))
  }

  x <- gsub("_", "/", x, fixed = TRUE)
  x <- gsub("-", "+", x, fixed = TRUE)
  # x <- gsub("=+$", "", x)
  openssl::base64_decode(x)
}

base64_url_rand <- function(bytes = 32) {
  base64_url_encode(openssl::rand_bytes(bytes))
}

#' Temporarily set verbosity for all requests
#'
#' `with_verbose()` is useful for debugging httr2 code buried deep inside
#' another package because it allows you to see exactly what's been sent
#' and requested.
#'
#' @inheritParams req_perform
#' @param code Code to execture
#' @returns The result of evaluating `code`.
#' @export
#' @examples
#' fun <- function() {
#'   request("https://httr2.r-lib.org") %>% req_perform()
#' }
#' with_verbosity(fun())
with_verbosity <- function(code, verbosity = 1) {
  withr::local_options(httr2_verbosity = verbosity)
  code
}

local_time <- function(x, tz = "UTC") {
  out <- as.POSIXct(x, tz = tz)
  attr(out, "tzone") <- NULL
  out
}

http_date <- function(x = Sys.time()) {
  withr::local_locale(LC_TIME = "C")
  strftime(x, "%a, %d %b %Y %H:%M:%S", tz = "UTC", usetz = TRUE)
}

parse_http_date <- function(x) {
  check_string(x, "`x`")

  withr::local_locale(LC_TIME = "C")

  # https://datatracker.ietf.org/doc/html/rfc7231#section-7.1.1.1
  out <- as.POSIXct(strptime(x, "%a, %d %b %Y %H:%M:%S", tz = "UTC"))
  attr(out, "tzone") <- NULL
  out
}

touch <- function(path, time = Sys.time()) {
  if (!file.exists(path)) {
    file.create(path)
  }
  Sys.setFileTime(path, time)
}

local_write_lines <- function(..., .env = caller_env()) {
  path <- withr::local_tempfile(.local_envir = .env)
  writeLines(c(...), path)
  path
}
