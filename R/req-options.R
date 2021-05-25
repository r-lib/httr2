req_options_set <- function(req, ...) {
  options <- list2(...)
  req$options <- utils::modifyList(req$options, options)
  req
}

req_user_agent <- function(req, ua) {
  req_options_set(req, useragent = ua)
}

req_authenticate <- function(req, user_name, password, type = "basic") {
  stopifnot(is.character(user_name), length(user_name) == 1)
  stopifnot(is.character(password), length(password) == 1)

  req_options_set(req,
    httpauth = auth_flags(type),
    userpwd = paste0(user_name, ":", password)
  )
}

req_cookies <- function(req, ...) {
  cookies <- map_chr(list2(...), curl::curl_escape)
  cookie <- paste(names(cookies), cookies, sep = "=", collapse = ";")

  req_options_set(req, cookie = cookie)
}

req_timeout <- function(req, seconds) {
  if (seconds < 0.001) {
    abort("`timeout` must be >1 ms")
  }
  req_options_set(req, timeout_ms = seconds * 1000)
}

req_verbose <- function(req, data_out = TRUE, data_in = FALSE, info = FALSE, ssl = FALSE) {
  debug <- function(type, msg) {
    switch(type + 1,
      text =       if (info)            prefix_message("*  ", msg),
      headerIn =                        prefix_message("<- ", msg),
      headerOut =                       prefix_message("-> ", msg),
      dataIn =     if (data_in)         prefix_message("<<  ", msg, TRUE),
      dataOut =    if (data_out)        prefix_message(">> ", msg, TRUE),
      sslDataIn =  if (ssl && data_in)  prefix_message("*< ", msg, TRUE),
      sslDataOut = if (ssl && data_out) prefix_message("*> ", msg, TRUE)
    )
  }
  req_options_set(req, debugfunction = debug, verbose = TRUE)
}


# helpers -----------------------------------------------------------------

prefix_message <- function(prefix, x, blank_line = FALSE) {
  x <- readBin(x, character())

  lines <- unlist(strsplit(x, "\n", fixed = TRUE, useBytes = TRUE))
  out <- paste0(prefix, lines, collapse = "\n")
  cat(out)
  if (blank_line) cat("\n")
}


auth_flags <- function(type) {
  constants <- c(
    basic = 1,
    digest = 2,
    gssnegotiate = 4,
    ntlm = 8,
    digest_ie = 16,
    any = -17
  )
  type <- arg_match0(type, names(constants), "type")
  constants[[type]]
}
