oauth_shiny_set_cookie_header <- function(name, value, cookie_opts) {
  # Chunk cookies if it exceeds 4000 characters to comply with max size 4096
  if (nchar(value) <= 4000) {
    cookie_hdr <- set_cookie_header(name, value, cookie_opts)
  } else {
    values <- strsplit(value, "(?<=.{4000})(?=.)", perl = TRUE)[[1]]
    names <- paste(name, seq(length(values)), sep = "_")
    cookie_hdr <- map2(names, values, set_cookie_header, cookie_opts)
  }
  unlist(cookie_hdr)
}

################# #
# Gargle Cookie Functions
# From: https://github.com/r-lib/gargle/pull/157/
# Remains unchanged, only changed standard args for cookie options (samesite, secure, httponly)
################# #

parse_cookies <- function(req) {
  cookie_header <- req[["HTTP_COOKIE"]]
  if (is.null(cookie_header)) {
    return(NULL)
  }

  cookies <- strsplit(cookie_header, "; *")[[1]]
  m <- regexec("(.*?)=(.*)", cookies)
  matches <- regmatches(cookies, m)
  names <- vapply(matches, function(x) {
    if (length(x) == 3) {
      x[[2]]
    } else {
      ""
    }
  }, character(1))

  if (any(names == "")) {
    # Malformed cookie
    return(NULL)
  }

  values <- vapply(matches, function(x) {
    x[[3]]
  }, character(1))

  set_names(as.list(values), names)
}

cookie_options <- function(max_age = NULL, domain = NULL, path = "/",
                           secure = TRUE, http_only = TRUE, same_site = "lax", expires = NULL) {
  if (!is.null(expires)) {
    stopifnot(length(expires) == 1 && (inherits(expires, "POSIXt") || is.character(expires)))
    if (inherits(expires, "POSIXt")) {
      expires <- as.POSIXlt(expires, tz = "GMT")
      expires <- sprintf(
        "%s, %02d %s %04d %02d:%02d:%02.0f GMT",
        c("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")[[expires$wday + 1]],
        expires$mday,
        c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")[[expires$mon + 1]],
        expires$year + 1900,
        expires$hour,
        expires$min,
        expires$sec
      )
    }
  }

  stopifnot(is.null(max_age) || (is.numeric(max_age) && length(max_age) == 1))
  if (!is.null(max_age)) {
    max_age <- sprintf("%.0f", max_age)
  }
  stopifnot(is.null(domain) || (is.character(domain) && length(domain) == 1))
  stopifnot(is.null(path) || (is.character(path) && length(path) == 1))
  stopifnot(is.null(secure) || isTRUE(secure) || isFALSE(secure))
  if (isFALSE(secure)) {
    secure <- NULL
  }
  stopifnot(is.null(http_only) || isTRUE(http_only) || isFALSE(http_only))
  if (isFALSE(http_only)) {
    http_only <- NULL
  }

  stopifnot(is.null(same_site) || (is.character(same_site) && length(same_site) == 1 &&
    grepl("^(strict|lax|none)$", same_site, ignore.case = TRUE)))
  # Normalize case
  if (!is.null(same_site)) {
    same_site <- c(strict = "Strict", lax = "Lax", none = "None")[[tolower(same_site)]]
  }
  list(
    "Expires" = expires,
    "Max-Age" = max_age,
    "Domain" = domain,
    "Path" = path,
    "Secure" = secure,
    "HttpOnly" = http_only,
    "SameSite" = same_site
  )
}

set_cookie_header <- function(name, value, cookie_options = cookie_options()) {
  stopifnot(is.character(name) && length(name) == 1)
  stopifnot(is.null(value) || (is.character(value) && length(value) == 1))
  value <- value %||% ""

  parts <- rlang::list2(
    !!name := value,
    !!!cookie_options
  )
  parts <- parts[!vapply(parts, is.null, logical(1))]

  names <- names(parts)
  sep <- ifelse(vapply(parts, isTRUE, logical(1)), "", "=")
  values <- ifelse(vapply(parts, isTRUE, logical(1)), "", as.character(parts))
  header <- paste(collapse = "; ", paste0(names, sep, values))
  list("Set-Cookie" = header)
}

# Returns a list, suitable for `!!!`-ing into a list of HTTP headers
delete_cookie_header <- function(name, cookie_options = cookie_options()) {
  cookie_options[["Expires"]] <- NULL
  cookie_options[["Max-Age"]] <- 0
  set_cookie_header(name, "", cookie_options)
}
