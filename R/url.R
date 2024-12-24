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
#' Modify components of a URL. The default value of each argument, `NULL`,
#' means leave the component as is. If you want to remove a component,
#' set it to `""`. Note that setting `scheme` or `hostname` to `""` will
#' create a relative URL.
#'
#' @param url A string or [parsed URL](url_parse).
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
url_modify <- function(url,
                       scheme = NULL,
                       hostname = NULL,
                       username = NULL,
                       password = NULL,
                       port = NULL,
                       path = NULL,
                       query = NULL,
                       fragment = NULL) {

  if (!is_string(url) && !is_url(url)) {
    stop_input_type(url, "a string or parsed URL")
  }
  string_url <- is_string(url)
  if (string_url) {
    url <- url_parse(url)
  }

  check_string(scheme, allow_null = TRUE)
  check_string(hostname, allow_null = TRUE)
  check_string(username, allow_null = TRUE)
  check_string(password, allow_null = TRUE)
  check_number_whole(port, min = 1, allow_null = TRUE)
  check_string(path, allow_null = TRUE)
  check_string(fragment, allow_null = TRUE)

  if (is_string(query)) {
    query <- query_parse(query)
  } else if (is.list(query) && (is_named(query) || length(query) == 0)) {
    for (nm in names(query)) {
      check_query_param(query[[nm]], paste0("query$", nm))
    }
  } else if (!is.null(query)) {
    stop_input_type(query, "a character vector, named list, or NULL")
  }

  new <- compact(list(
    scheme = scheme,
    hostname = hostname,
    username = username,
    password = password,
    port = port,
    path = path,
    query = query,
    fragment = fragment
  ))
  is_empty <- map_lgl(new, identical, "")
  new[is_empty] <- list(NULL)
  url[names(new)] <- new

  if (string_url) {
    url_build(url)
  } else {
    url
  }
}

is_url <- function(x) inherits(x, "httr2_url")

#' @export
print.httr2_url <- function(x, ...) {
  cli::cli_text("{.cls {class(x)}} {url_build(x)}")
  if (!is.null(x$scheme)) {
    cli::cli_li("{.field scheme}: {x$scheme}")
  }
  if (!is.null(x$hostname)) {
    cli::cli_li("{.field hostname}: {x$hostname}")
  }
  if (!is.null(x$username)) {
    cli::cli_li("{.field username}: {x$username}")
  }
  if (!is.null(x$password)) {
    cli::cli_li("{.field password}: {x$password}")
  }
  if (!is.null(x$port)) {
    cli::cli_li("{.field port}: {x$port}")
  }
  if (!is.null(x$path)) {
    cli::cli_li("{.field path}: {x$path}")
  }
  if (!is.null(x$query)) {
    cli::cli_li("{.field query}: ")
    id <- cli::cli_ul()
    # escape curly brackets for cli by replacing single with double brackets
    query_vals <- gsub("{", "{{", gsub("}", "}}", x$query, fixed = TRUE), fixed = TRUE)
    cli::cli_li(paste0("  {.field ", names(x$query), "}: ", query_vals))
    cli::cli_end(id)
  }
  if (!is.null(x$fragment)) {
    cli::cli_li("{.field fragment}: {x$fragment}")
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

  if (!is.null(url$query)) {
    query <- query_build(url$query)
  } else {
    query <- NULL
  }

  if (is.null(url$username) && is.null(url$password)) {
    user_pass <- NULL
  } else if (is.null(url$username) && !is.null(url$password)) {
    cli::cli_abort("Cannot set url {.arg password} without {.arg username}.")
  } else if (!is.null(url$username) && is.null(url$password)) {
    user_pass <- paste0(url$username, "@")
  } else {
    user_pass <- paste0(url$username, ":", url$password, "@")
  }

  if (!is.null(user_pass) || !is.null(url$hostname) || !is.null(url$port)) {
    authority <- paste0(user_pass, url$hostname)
    if (!is.null(url$port)) {
      authority <- paste0(authority, ":", url$port)
    }
  } else {
    authority <- NULL
  }

  if (is.null(url$path) || !startsWith(url$path, "/")) {
    url$path <- paste0("/", url$path)
  }

  prefix <- function(prefix, x) if (!is.null(x)) paste0(prefix, x)
  paste0(
    url$scheme, if (!is.null(url$scheme)) ":",
    if (!is.null(url$scheme) || !is.null(authority)) "//",
    authority, url$path,
    prefix("?", query),
    prefix("#", url$fragment)
  )
}

query_parse <- function(x) {
  x <- gsub("^\\?", "", x) # strip leading ?, if present
  params <- parse_name_equals_value(parse_delim(x, "&"))

  if (length(params) == 0) {
    return(NULL)
  }

  out <- as.list(curl::curl_unescape(params))
  names(out) <- curl::curl_unescape(names(params))
  out
}

query_build <- function(x, error_call = caller_env()) {
  elements_build(x, "Query", "&", error_call = error_call)
}

elements_build <- function(x, name, collapse, error_call = caller_env()) {
  if (!is_list(x) || (!is_named(x) && length(x) > 0)) {
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

format_query_param <- function(x,
                               name,
                               multi = FALSE,
                               error_call = caller_env()) {
  check_query_param(x, name, multi = multi, error_call = error_call)

  if (inherits(x, "AsIs")) {
    unclass(x)
  } else {
    x <- format(x, scientific = FALSE, trim = TRUE, justify = "none")
    curl::curl_escape(x)
  }
}
check_query_param <- function(x, name, multi = FALSE, error_call = caller_env()) {
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
