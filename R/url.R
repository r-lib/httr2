#' Parse a URL into its component pieces
#'
#' `url_parse()` parses a URL into its component parts, powered by
#' [curl::curl_parse_url()]. The parsing algorithm follows the specifications
#' detailed in `r rfc(3986)`.
#'
#' @param url A string containing the URL to parse.
#' @param base_url Use this as a parent, if `url` is a relative URL.
#' @returns An S3 object of class `httr2_url` with the following components:
#'   `scheme`, `hostname`, `username`, `password`, `port`, `path`, `query`, and
#'   `fragment`.
#' @export
#' @family URL manipulation
#' @examples
#' url_parse("http://google.com/")
#' url_parse("http://google.com:80/")
#' url_parse("http://google.com:80/?a=1&b=2")
#' url_parse("http://username@google.com:80/path;test?a=1&b=2#40")
#'
#' # You can parse a relative URL if you also provide a base url
#' url_parse("foo", "http://google.com/bar/")
#' url_parse("..", "http://google.com/bar/")
url_parse <- function(url, base_url = NULL) {
  check_string(url)
  check_string(base_url, allow_null = TRUE)

  curl <- curl::curl_parse_url(url, baseurl = base_url)

  parsed <- list(
    scheme = curl$scheme,
    hostname = curl$host,
    username = curl$user,
    password = curl$password,
    port = curl$port,
    path = curl$path,
    query = if (length(curl$params)) as.list(curl$params),
    fragment = curl$fragment
  )
  class(parsed) <- "httr2_url"
  parsed
}

#' Modify a URL
#'
#' @description
#' Use `url_modify()` to modify any component of the URL,
#' `url_modify_relative()` to modify with a relative URL,
#' or `url_modify_query()` to modify individual query parameters.
#'
#' For `url_modify()`, components that aren't specified in the
#' function call will be left as is; components set to `NULL` will be removed,
#' and all other values will be updated. Note that removing `scheme` or
#' `hostname` will create a relative URL.
#'
#' @param url,.url A string or [parsed URL][url_parse()].
#' @param scheme The scheme, typically either `http` or `https`.
#' @param hostname The hostname, e.g., `www.google.com` or `posit.co`.
#' @param username,password Username and password to embed in the URL.
#'   Not generally recommended but needed for some legacy applications.
#' @param port An integer port number.
#' @param path The path, e.g., `/search`. Paths must start with `/`, so this
#'   will be automatically added if omitted.
#' @param query Either a query string or a named list of query components.
#' @param fragment The fragment, e.g., `#section-1`.
#' @return An object of the same type as `url`.
#' @export
#' @family URL manipulation
#' @examples
#' url_modify("http://hadley.nz", path = "about")
#' url_modify("http://hadley.nz", scheme = "https")
#' url_modify("http://hadley.nz/abc", path = "/cde")
#' url_modify("http://hadley.nz/abc", path = "")
#' url_modify("http://hadley.nz?a=1", query = "b=2")
#' url_modify("http://hadley.nz?a=1", query = list(c = 3))
#'
#' url_modify_query("http://hadley.nz?a=1&b=2", c = 3)
#' url_modify_query("http://hadley.nz?a=1&b=2", b = NULL)
#' url_modify_query("http://hadley.nz?a=1&b=2", a = 100)
#'
#' url_modify_relative("http://hadley.nz/a/b/c.html", "/d.html")
#' url_modify_relative("http://hadley.nz/a/b/c.html", "d.html")
#' url_modify_relative("http://hadley.nz/a/b/c.html", "../d.html")
url_modify <- function(
  url,
  scheme = as_is,
  hostname = as_is,
  username = as_is,
  password = as_is,
  port = as_is,
  path = as_is,
  query = as_is,
  fragment = as_is
) {
  if (!is_string(url) && !is_url(url)) {
    stop_input_type(url, "a string or parsed URL")
  }
  string_url <- is_string(url)

  check_url_component(scheme)
  check_url_component(hostname)
  check_url_component(username)
  check_url_component(password)
  if (!leave_as_is(port)) {
    check_number_whole(port, min = 1, max = 65535, allow_null = TRUE)
  }
  check_url_component(path)
  check_url_component(fragment)

  if (is_string(query)) {
    query <- url_query_parse(query)
  } else if (is_named_list(query)) {
    for (nm in names(query)) {
      check_query_param(query[[nm]], paste0("query$", nm))
    }
  } else if (!is.null(query) && !leave_as_is(query)) {
    stop_input_type(query, "a character vector, named list, or NULL")
  }

  new <- list(
    scheme = scheme,
    hostname = hostname,
    username = username,
    password = password,
    port = port,
    path = path,
    query = query,
    fragment = fragment
  )
  new <- new[!map_lgl(new, leave_as_is)]

  if (string_url) {
    new[map_lgl(new, is.null)] <- ""
    url_build(structure(c(url = url, new), class = "httr2_url"))
  } else {
    url[names(new)] <- new
    url
  }
}

as_is <- quote(as_is)
leave_as_is <- function(x) identical(x, as_is)
check_url_component <- function(x, arg = caller_arg(x), call = caller_env()) {
  if (leave_as_is(x)) {
    return(invisible(NULL))
  }

  check_string(x, allow_null = TRUE, arg = arg, call = call)
}

#' @export
#' @rdname url_modify
#' @param relative_url A relative URL to append to the base URL.
url_modify_relative <- function(url, relative_url) {
  string_url <- is_string(url)
  if (!string_url) {
    url <- url_build(url)
  }

  new_url <- url_parse(relative_url, base_url = url)

  if (string_url) {
    url_build(new_url)
  } else {
    new_url
  }
}

#' @export
#' @rdname url_modify
#' @param ... <[`dynamic-dots`][rlang::dyn-dots]>
#'   Name-value pairs that define query parameters. Each value must be either
#'   an atomic vector or `NULL` (which removes the corresponding parameters).
#'   If you want to opt out of escaping, wrap strings in `I()`.
#' @param .multi Controls what happens when a value is a vector:
#'
#'   * `"error"`, the default, throws an error.
#'   * `"comma"`, separates values with a `,`, e.g. `?x=1,2`.
#'   * `"pipe"`, separates values with a `|`, e.g. `?x=1|2`.
#'   * `"explode"`, turns each element into its own parameter, e.g. `?x=1&x=2`
#'
#'   If none of these options work for your needs, you can instead supply a
#'   function that takes a character vector of argument values and returns a
#'   a single string.
#' @param .space How should spaces in query params be escaped? The default,
#'   "percent", uses standard percent encoding (i.e. `%20`), but you can opt-in
#'   to "form" encoding, which uses `+` instead.
url_modify_query <- function(
  .url,
  ...,
  .multi = c("error", "comma", "pipe", "explode"),
  .space = c("percent", "form")
) {
  if (!is_string(.url) && !is_url(.url)) {
    stop_input_type(.url, "a string or parsed URL")
  }
  string_url <- is_string(.url)
  if (string_url) {
    .url <- url_parse(.url)
  }

  new_query <- multi_dots(..., .multi = .multi, .space = .space)
  if (length(new_query) > 0) {
    .url$query <- modify_list(.url$query, !!!new_query)
  }

  if (string_url) {
    url_build(.url)
  } else {
    .url
  }
}

is_url <- function(x) inherits(x, "httr2_url")

#' @export
print.httr2_url <- function(x, ...) {
  cli::cat_line(cli::format_inline("{.cls {class(x)}} {url_build(x)}"))
  if (!is.null(x$scheme)) {
    cli::cat_line(cli::format_inline("* {.field scheme}: {x$scheme}"))
  }
  if (!is.null(x$hostname)) {
    cli::cat_line(cli::format_inline("* {.field hostname}: {x$hostname}"))
  }
  if (!is.null(x$username)) {
    cli::cat_line(cli::format_inline("* {.field username}: {x$username}"))
  }
  if (!is.null(x$password)) {
    cli::cat_line(cli::format_inline("* {.field password}: {x$password}"))
  }
  if (!is.null(x$port)) {
    cli::cat_line(cli::format_inline("* {.field port}: {x$port}"))
  }
  if (!is.null(x$path)) {
    cli::cat_line(cli::format_inline("* {.field path}: {x$path}"))
  }
  if (!is.null(x$query)) {
    cli::cat_line(cli::format_inline("* {.field query}:"))
    for (i in seq_along(x$query)) {
      nm <- names(x$query)[[i]]
      val <- x$query[[i]]
      cli::cat_line(cli::format_inline("  * {.field {nm}}: {val}"))
    }
  }
  if (!is.null(x$fragment)) {
    cli::cat_line(cli::format_inline("* {.field fragment}: {x$fragment}"))
  }
  invisible(x)
}

#' Build a string from a URL object
#'
#' This is the inverse of [url_parse()], taking a parsed URL object and
#' turning it back into a string.
#'
#' @param url An URL object created by [url_parse].
#' @family URL manipulation
#' @export
url_build <- function(url) {
  if (!is_url(url)) {
    stop_input_type(url, "a parsed URL")
  }

  if (is.null(url$query)) {
    query <- NULL
  } else if (length(url$query) == 0 || identical(url$query, "")) {
    query <- ""
  } else {
    query <- I(url_query_build(url$query))
  }

  url <- curl::curl_modify_url(
    url = url$url,
    scheme = url$scheme,
    host = url$hostname,
    user = url$username,
    password = url$password,
    port = url$port,
    path = url$path,
    query = query,
    fragment = url$fragment
  )

  # Workaround https://github.com/curl/curl/issues/17977
  # curl url parser esacapes colons in paths which google seems to use
  # quite frequently. So we hack the problem away for now, restoring the
  # behaviour of httr2 1.1.2
  if (grepl("%3A", url, fixed = TRUE)) {
    path <- curl::curl_parse_url(url, decode = FALSE)$path
    path <- gsub("%3A", ":", path, fixed = TRUE)
    url <- curl::curl_modify_url(url, path = I(path))
  }
  url
}

#' Parse query parameters and/or build a string
#'
#' `url_query_parse()` parses a query string into a named list;
#' `url_query_build()` builds a query string from a named list.
#'
#' @param query A string, when parsing; a named list when building.
#' @export
#' @examples
#' str(url_query_parse("a=1&b=2"))
#'
#' url_query_build(list(x = 1, y = "z"))
#' url_query_build(list(x = 1, y = 1:2), .multi = "explode")
url_query_parse <- function(query) {
  check_string(query)

  query <- gsub("^\\?", "", query) # strip leading ?, if present
  params <- parse_name_equals_value(parse_delim(query, "&"))

  if (length(params) == 0) {
    return(NULL)
  }

  out <- as.list(curl::curl_unescape(params))
  names(out) <- curl::curl_unescape(names(params))
  out
}

#' @export
#' @rdname url_query_parse
#' @inheritParams url_modify_query
url_query_build <- function(
  query,
  .multi = c("error", "comma", "pipe", "explode")
) {
  if (!is_named_list(query)) {
    stop_input_type(query, "a named list")
  }

  query <- multi_dots(!!!query, .multi = .multi, error_arg = "query")
  elements_build(query, "Query", "&")
}

elements_build <- function(x, name, collapse, error_call = caller_env()) {
  if (!is_named_list(x)) {
    cli::cli_abort("{name} must be a named list.", call = error_call)
  }

  x <- compact(x)
  if (length(x) == 0) {
    return(NULL)
  }

  values <- map2_chr(x, names(x), format_query_param, error_call = error_call)
  names <- curl::curl_escape(names(x))

  paste0(names, "=", values, collapse = collapse)
}

format_query_param <- function(
  x,
  name,
  multi = FALSE,
  form = FALSE,
  error_call = caller_env()
) {
  check_query_param(x, name, multi = multi, error_call = error_call)

  if (inherits(x, "AsIs")) {
    unclass(x)
  } else if (is_obfuscated(x)) {
    x
  } else {
    x <- format(x, scientific = FALSE, trim = TRUE, justify = "none")
    x <- curl::curl_escape(x)
    if (form) {
      x <- gsub("%20", "+", x, fixed = TRUE)
    }
    x
  }
}
check_query_param <- function(
  x,
  name,
  multi = FALSE,
  error_call = caller_env()
) {
  if (inherits(x, "AsIs")) {
    if (multi) {
      ok <- is.character(x)
      expected <- "a character vector"
    } else {
      ok <- is.character(x) && length(x) == 1
      expected <- "a single string"
    }
    arg <- paste0("Escaped query value `", name, "`")
    x <- unclass(x)
  } else {
    if (multi) {
      ok <- is.atomic(x)
      expected <- "an atomic vector"
    } else {
      ok <- is.atomic(x) && length(x) == 1
      expected <- "a length-1 atomic vector"
    }
    arg <- paste0("Query value `", name, "`")
  }

  if (ok) {
    invisible()
  } else {
    stop_input_type(x, expected, arg = I(arg), call = error_call)
  }
}
