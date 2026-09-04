#' @param hash_key A function with argument `req` that returns the components
#'    of the request that should be used for computing equality. By default,
#'    `hash_key` inspects the `url`, `body`, and `headers`, which should be
#'    adequate for most needs.
#' @param progress_label A 1function with `req` that returns a string used to
#'    label the progress bar. The default displays the URL which is most useful
#'    for spidering HTML sites.
#' @examples
#' url <- "https://ggplot2.tidyverse.org/"
#' req <- request(url)
#' req_perform_spider(req, next_reqs = spider_descendents(url))
req_perform_spider <- function(
    req,
    next_reqs,
    path = NULL,
    on_error = c("stop", "return", "continue"),
    hash_key = NULL,
    progress = TRUE,
    progress_label = NULL
) {

  check_request(req)
  check_function2(next_reqs, args = c("resp", "req"))
  check_string(path, allow_empty = FALSE, allow_null = TRUE)
  on_error <- match.arg(on_error)
  check_function2(hash_key, args = "req", allow_null = TRUE)
  check_function2(progress_label, args = "req", allow_null = TRUE)
  check_bool(progress)

  hash_key <- hash_key %||% function(req) req[c("url", "body", "headers")]
  progress_label <- progress_label %||% function(req) req$url

  get_path <- function(hash) {
    if (is.null(path)) {
      NULL
    } else {
      glue::glue(path)
    }
  }

  todo <- fastmap::fastqueue()
  done <- fastmap::fastmap()
  seen <- fastmap::fastmap()

  todo$add(req)

  if (progress) {
    cli::cli_progress_bar(
      type = "custom",
      total = NA,
      format = "Spidering {done$size()}/{done$size() + todo$size()}: {progress_label(req)}"
    )
  }

  while (todo$size() > 0) {
    req <- todo$remove()
    if (progress) cli::cli_progress_update()

    req_hash <- hash(hash_key(req))
    resp <- req_perform(req, path = get_path(req_hash))
    done$set(req_hash, resp)
    seen$set(req_hash, TRUE)

    up_next <- next_reqs(req, resp)
    for (req in up_next) {
      req_hash <- hash(hash_key(req))
      if (!seen$has(req_hash)) {
        seen$set(req_hash, TRUE)
        todo$add(req)
      }
    }
  }

  unname(done$as_list())
}


#' @export
#' @rdname req_perform_spider
spider_descendents <- function(home_url) {
  force(home_url)
  function(req, resp) {
    html <- resp_body_html(resp)

    a <- xml2::xml_find_all(html, "//a[@href]")
    href <- xml2::xml_attr(a, "href")
    href <- xml2::url_absolute(href, resp_url(resp))
    href <- href[map_lgl(href, can_parse)]
    href <- map_chr(href, strip_fragment)
    href <- unique(href)

    descendents <- href[map_lgl(href, url_is_child, home_url)]

    map(descendents, function(path) req_url(req, path))
  }
}

url_is_child <- function(child, parent) {
  parent <- url_parse(parent)
  child <- url_parse(child)

  identical(child$scheme, parent$scheme) &&
    identical(child$hostname, parent$hostname) &&
    identical(child$port, parent$port) &&
    path_is_child(child$path, parent$path)
}

# path_is_child("/foo2", "/foo")
# path_is_child("/foo/bar", "/foo")
path_is_child <- function(child, parent) {
  parent <- normalize_path(parent)
  child <- normalize_path(child)

  if (startsWith(child, parent)) {
    if (nchar(child) > nchar(parent)) {
      i <- nchar(parent) + 1
      substring(child, i, i) == "/"
    } else {
      FALSE
    }
  } else {
    FALSE
  }
}

normalize_path <- function(path) {
  # strip index.html and friends
  path <- sub("(index|default)\\.[a-z]+$", "", path, ignore.case = TRUE)
  # strip trailing /
  path <- sub("/$", "", path)
  # url_parse ensures it always starts with /
  path
}

strip_fragment <- function(url) {
  url <- url_parse(url)
  url$fragment <- NULL
  url_build(url)
}

can_parse <- function(url) {
  tryCatch(
    {
      url_parse(url)
      TRUE
    },
    error = function(cnd) FALSE
  )
}
