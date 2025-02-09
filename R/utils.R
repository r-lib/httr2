bullets_with_header <- function(header, x) {
  if (length(x) == 0) {
    return()
  }

  cli::cli_text("{.strong {header}}")
  bullets(x)
}

bullets <- function(x) {
  as_simple <- function(x) {
    if (is.atomic(x) && length(x) == 1) {
      if (is_redacted(x)) {
        x
      } else if (is.character(x)) {
        paste0('"', x, '"')
      } else {
        format(x)
      }
    } else {
      paste0("<", class(x)[[1L]], ">")
    }
  }
  vals <- map_chr(x, as_simple)
  names <- format(names(x))
  names <- gsub(" ", "\u00a0", names, fixed = TRUE)

  for (i in seq_along(x)) {
    cli::cli_li("{.field {names[[i]]}}: {vals[[i]]}")
  }
}

modify_list <- function(.x, ..., error_call = caller_env()) {
  dots <- list2(...)
  if (length(dots) == 0) return(.x)

  if (!is_named(dots)) {
    cli::cli_abort(
      "All components of {.arg ...} must be named.",
      call = error_call
    )
  }



  out <- .x[!names(.x) %in% names(dots)]
  out <- c(out, compact(dots))

  if (length(out) == 0) {
    names(out) <- NULL
  }

  out
}


sys_sleep <- function(seconds, task, fps = 10, progress = NULL) {
  check_number_decimal(seconds)
  check_string(task)
  check_number_decimal(fps)
  progress <- progress %||% getOption("httr2_progress", !is_testing())
  check_bool(progress, allow_null = TRUE)

  if (seconds == 0) {
    return(invisible())
  }

  if (!progress) {
    cli::cli_alert("Waiting {round(seconds, 2)}s {task}")
    Sys.sleep(seconds)
    return(invisible())
  }

  start <- cur_time()
  signal("", class = "httr2_sleep", seconds = seconds)

  cli::cli_progress_bar(
    format = "Waiting {ceiling(seconds)}s {task} {cli::pb_bar}",
    total = seconds * fps
  )

  while ({left <- start + seconds - cur_time(); left > 0}) {
    Sys.sleep(min(1 / fps, left))
    cli::cli_progress_update(set = (seconds - left) * fps)
  }
  cli::cli_progress_done()

  invisible()
}

cur_time <- function() proc.time()[[3]]

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
#'   request("https://httr2.r-lib.org") |> req_perform()
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

check_function2 <- function(x,
                            ...,
                            args = NULL,
                            allow_null = FALSE,
                            arg = caller_arg(x),
                            call = caller_env()) {
  check_function(
    x = x,
    allow_null = allow_null,
    arg = arg,
    call = call
  )

  if (!is.null(x)) {
    .check_function_args(
      f = x,
      expected_args = args,
      arg = arg,
      call = call
    )
  }
}

# Basically copied from rlang. Can be removed when https://github.com/r-lib/rlang/pull/1652
# is merged
.check_function_args <- function(f,
                                 expected_args,
                                 arg,
                                 call) {
  if (is_null(expected_args)) {
    return(invisible(NULL))
  }

  actual_args <- fn_fmls_names(f) %||% character()
  missing_args <- setdiff(expected_args, actual_args)
  if (is_empty(missing_args)) {
    return(invisible(NULL))
  }

  n_expected_args <- length(expected_args)
  n_actual_args <- length(actual_args)

  if (n_actual_args == 0) {
    arg_info <- "instead it has no arguments"
  } else {
    arg_info <- paste0("it currently has {.arg {actual_args}}")
  }

  cli::cli_abort(
    paste0("{.arg {arg}} must have the {cli::qty(n_expected_args)}argument{?s} {.arg {expected_args}}; ", arg_info, "."),
    call = call,
    arg = arg
  )
}

# This is inspired by the C interface of `cli_progress_bar()` which has just
# 2 arguments: `total` and `config`
create_progress_bar <- function(total,
                                name,
                                config,
                                env = caller_env(),
                                config_arg = caller_arg(config),
                                error_call = caller_env()) {
  if (is_false(config)) {
    return(list(
      update = function(...) {},
      done = function() {}
    ))
  }

  if (is.null(config) || is_bool(config)) {
    args <- list()
  } else if (is_scalar_character(config)) {
    args <- list(name = config)
  } else if (is.list(config)) {
    args <- config
  } else {
    stop_input_type(
      config,
      what = c("a bool", "a string", "a list"),
      arg = config_arg,
      call = error_call
    )
  }

  args$name <- args$name %||% name
  # Can be removed if https://github.com/r-lib/cli/issues/630 is fixed
  if (is.infinite(total)) {
    total <- NA
  }
  args$total <- total
  args$.envir <- env

  id <- exec(cli::cli_progress_bar, !!!args)

  list(
    update = function(...) cli::cli_progress_update(..., id = id),
    done = function() cli::cli_progress_done(id = id)
  )
}

imap <- function(.x, .f, ...) {
  map2(.x, names(.x), .f, ...)
}

read_con <- function(con, buffer = 32 * 1024) {
  bytes <- raw()
  repeat {
    new <- readBin(con, "raw", n = buffer)
    if (length(new) == 0) break
    bytes <- c(bytes, new)
  }
  if (length(bytes) == 0) {
    NULL
  } else {
    bytes
  }
}


# Slices the vector using the only sane semantics: start inclusive, end
# exclusive.
#
# * Allows start == end, which means return no elements.
# * Allows start == length(vector) + 1, which means return no elements.
# * Allows zero-length vectors.
#
# Otherwise, slice() is quite strict about what it allows start/end to be: no
# negatives, no reversed order.
slice <- function(vector, start = 1, end = length(vector) + 1) {
  stopifnot(start > 0)
  stopifnot(start <= length(vector) + 1)
  stopifnot(end > 0)
  stopifnot(end <= length(vector) + 1)
  stopifnot(end >= start)

  if (start == end) {
    vector[FALSE] # Return an empty vector of the same type
  } else {
    vector[start:(end - 1)]
  }
}

is_named_list <- function(x) {
  is_list(x) && (is_named(x) || length(x) == 0)
}

pretty_json <- function(x) {
  parsed <- tryCatch(
    jsonlite::parse_json(x),
    error = function(e) NULL
  )
  if (is.null(parsed)) {
    x
  } else {
    jsonlite::toJSON(parsed, auto_unbox = TRUE, pretty = TRUE)
  }
}

log_stream <- function(..., prefix = "<< ") {
  out <- gsub("\n", paste0("\n", prefix), paste0(prefix, ..., collapse = ""))
  cli::cat_line(out)
}
