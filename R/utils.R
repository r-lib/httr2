bullets_with_header <- function(header, x) {
  if (length(x) == 0) {
    return()
  }

  cli::cat_line(cli::format_inline("{.strong {header}}"))
  bullets(x)
}

bullets <- function(x) {
  as_simple <- function(x) {
    if (is.atomic(x) && length(x) == 1) {
      if (is.character(x)) {
        paste0('"', x, '"')
      } else {
        format(x)
      }
    } else {
      if (is_redacted_sentinel(x)) {
        format(x)
      } else {
        paste0("<", class(x)[[1L]], ">")
      }
    }
  }
  vals <- map_chr(x, as_simple)
  names <- format(names(x))
  names <- gsub(" ", "\u00a0", names, fixed = TRUE)

  for (i in seq_along(x)) {
    cli::cat_line(cli::format_inline("* {.field {names[[i]]}}: {vals[[i]]}"))
  }
}

modify_list <- function(
  .x,
  ...,
  .ignore_case = FALSE,
  error_call = caller_env()
) {
  dots <- list2(...)
  if (length(dots) == 0) {
    return(.x)
  }

  if (!is_named(dots)) {
    cli::cli_abort(
      "All components of {.arg ...} must be named.",
      call = error_call
    )
  }

  if (.ignore_case) {
    out <- .x[!tolower(names(.x)) %in% tolower(names(dots))]
  } else {
    out <- .x[!names(.x) %in% names(dots)]
  }

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

  while (
    {
      left <- start + seconds - cur_time()
      left > 0
    }
  ) {
    Sys.sleep(min(1 / fps, left))
    cli::cli_progress_update(set = (seconds - left) * fps)
  }
  cli::cli_progress_done()

  invisible()
}

# allow mocking
Sys.sleep <- NULL

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

check_function2 <- function(
  x,
  ...,
  args = NULL,
  allow_null = FALSE,
  arg = caller_arg(x),
  call = caller_env()
) {
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
.check_function_args <- function(f, expected_args, arg, call) {
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
    paste0(
      "{.arg {arg}} must have the {cli::qty(n_expected_args)}argument{?s} {.arg {expected_args}}; ",
      arg_info,
      "."
    ),
    call = call,
    arg = arg
  )
}

# This is inspired by the C interface of `cli_progress_bar()` which has just
# 2 arguments: `total` and `config`
create_progress_bar <- function(
  progress,
  total,
  name = "iterating",
  format = NULL,
  envir = caller_env(),
  frame = caller_env()
) {
  if (is_false(progress)) {
    return(list(
      update = function(...) {},
      done = function() {}
    ))
  }

  if (is.null(progress) || isTRUE(progress)) {
    args <- list()
    args$name <- name
    args$format <- format
  } else if (is_scalar_character(progress)) {
    args <- list(name = progress)
  } else if (is.list(progress)) {
    args <- progress
    args$name <- args$name %||% name
    args$format <- args$format %||% format
  } else {
    stop_input_type(
      progress,
      what = c("a bool", "a string", "a list"),
      call = frame
    )
  }

  args$total <- total
  args$.envir <- envir
  args$.auto_close <- FALSE

  id <- exec(cli::cli_progress_bar, !!!args)
  withr::defer(cli::cli_progress_done(id = id), envir = frame)

  list(
    update = function(...) {
      cli::cli_progress_update(..., id = id, .envir = envir)
    },
    done = function() cli::cli_progress_done(id = id)
  )
}

imap <- function(.x, .f, ...) {
  map2(.x, names(.x), .f, ...)
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
  tryCatch(
    gsub("\n$", "", jsonlite::prettify(x, indent = 2)),
    error = function(e) x
  )
}

log_stream <- function(..., prefix = "<< ") {
  out <- gsub("\n", paste0("\n", prefix), paste0(prefix, ..., collapse = ""))
  cli::cat_line(out)
}

paste_c <- function(..., collapse = "") {
  paste0(c(...), collapse = collapse)
}

# Give user the get-out-of-jail-free card if interrupt-capturing function
# is wrapped inside a loop
check_repeated_interrupt <- function() {
  if (as.double(Sys.time()) - the$last_interrupt < 1) {
    cli::cli_alert_warning("Interrupting")
    interrupt()
  }
  the$last_interrupt <- as.double(Sys.time())
}
