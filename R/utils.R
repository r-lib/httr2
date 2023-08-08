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

  out <- .x[!names(.x) %in% names(dots)]
  out <- c(out, compact(dots))

  if (length(out) == 0) {
    names(out) <- NULL
  }

  out
}


sys_sleep <- function(seconds, fps = 10) {
  check_number(seconds, "`seconds`")

  if (seconds == 0) {
    return(invisible())
  }

  start <- cur_time()
  signal("", class = "httr2_sleep", seconds = seconds)

  cli::cli_progress_bar(
    format = "Waiting {round(seconds)}s to retry {cli::pb_bar}",
    total = seconds * fps
  )

  while({left <- start + seconds - cur_time(); left > 0}) {
    Sys.sleep(min(1 / fps, left))
    cli::cli_progress_update(set = (seconds - left) * fps)
  }
  cli::cli_progress_done()

  invisible()
}

cur_time <- function() proc.time()[[3]]

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
#' `with_verbosity()` is useful for debugging httr2 code buried deep inside
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

httr2_verbosity <- function() {
  x <- getOption("httr2_verbosity")
  if (!is.null(x)) {
    return(x)
  }

  # Hackish fallback for httr::with_verbose
  old <- getOption("httr_config")
  if (!is.null(old$options$debugfunction)) {
    1
  } else {
    0
  }
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
  check_string(x)

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
