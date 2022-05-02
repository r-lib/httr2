#' Set request method/path from a template
#'
#' @description
#' Many APIs document their methods with a lightweight template mechanism
#' that looks like `GET /user/{user}` or `POST /organisation/:org`. This
#' function makes it easy to copy and paste such snippets and retrieve template
#' variables either from function arguments or the current environment.
#'
#' The result is used to set the request path or, if one already exists, to append
#' it. This is useful when the existing path needs to be kept, but chaining
#' multiple `req_template()` calls should probably be avoided, as it might lead
#' to code that is hard to understand.
#'
#' @inheritParams req_perform
#' @param template A template string which consists of a optional HTTP method
#'   and a path containing variables labelled like either `:foo` or `{foo}`.
#' @param ... Template variables.
#' @param .env Environment in which to look for template variables not found
#'   in `...`. Expert use only.
#' @returns A modified HTTP [request].
#' @export
#' @examples
#' httpbin <- request("http://httpbin.org")
#'
#' # You can supply template parameters in `...`
#' httpbin %>% req_template("GET /bytes/{n}", n = 100)
#'
#' # or you retrieve from the current environment
#' n <- 200
#' httpbin %>% req_template("GET /bytes/{n}")
#'
#' # Existing path is preserved:
#' httpbin_cookies <- request("http://httpbin.org/cookies")
#' name <- "id"
#' value <- "a3fWa"
#' httpbin_cookies %>% req_template("GET /set/{name}/{value}")
req_template <- function(req, template, ..., .env = parent.frame()) {
  check_request(req)
  check_string(template, "`template`")

  pieces <- strsplit(template, " ")[[1]]
  if (length(pieces) == 1) {
    template <- pieces[[1]]
  } else if (length(pieces) == 2) {
    req <- req_method(req, pieces[[1]])
    template <- pieces[[2]]
  } else {
    abort(c(
      "Can't parse template `template`",
      i = "Should have form like 'GET /a/b/c' or 'a/b/c/'"
    ))
  }

  dots <- list2(...)
  if (length(dots) > 0 && !is_named(dots)) {
    abort("All elements of ... must be named")
  }

  path <- template_process(template, dots, .env)
  req_url_path_append(req, path)
}

template_process <- function(template, dots = list(), env = parent.frame()) {
  type <- template_type(template)
  vars <- template_vars(template, type)
  vals <- map_chr(vars, template_val, dots = dots, env = env)

  for (i in seq_along(vars)) {
    pattern <- switch(type,
      colon = paste0(":", vars[[i]]),
      uri = paste0("{", vars[[i]], "}")
    )
    template <- gsub(pattern, vals[[i]], template, fixed = TRUE)
  }
  template
}

template_val <- function(name, dots, env) {
  if (has_name(dots, name)) {
    val <- dots[[name]]
  } else if (env_has(env, name, inherit = TRUE)) {
    val <- env_get(env, name, inherit = TRUE)
  } else {
    abort(glue("Can't find template variable '{name}'"))
  }

  if (!is.atomic(val) || length(val) != 1) {
    abort(glue("Template variable '{name}' is not a simple scalar value"))
  }
  as.character(val)
}

template_vars <- function(x, type) {
  if (type == "none") return(character())

  pattern <- switch(type,
    colon = ":([a-zA-Z0-9_]+)",
    uri = "\\{(\\w+?)\\}"
  )
  loc <- gregexpr(pattern, x, perl = TRUE)[[1]]
  start <- attr(loc, "capture.start")
  end <- start + attr(loc, "capture.length") - 1
  substring(x, start, end)
}

template_type <- function(x) {
  if (grepl(":", x)) {
    "colon"
  } else if (grepl("\\{\\w+?\\}", x)) {
    "uri"
  } else {
    "none"
  }
}
