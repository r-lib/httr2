testthat::set_state_inspector(function() {
  list(
    connections = getAllConnections(),
    the_throttle = as.list(the$throttle)
  )
})

expect_redacted <- function(req, expected) {
  expect_equal(which_redacted(req$headers), expected)
}

local_curl_error <- function(
  message = "Failed to connect",
  env = caller_env()
) {
  class <- c("curl_error_couldnt_connect", "curl_error")
  curl_error <- function(call) {
    stop(errorCondition(message, class = class, call = call))
  }

  local_mocked_bindings(
    curl_fetch = function(...) curl_error(quote(curl_fetch())),
    open = function(...) curl_error(quote(open())),
    curl_multi_add = function(handle, pool, data, done, fail) {
      fail(structure(message, class = c(class, "character")))
    },
    .env = env
  )
}

# The default user agent includes httr2/curl/libcurl versions, which vary, so
# mock it to a fixed value. Mock req_user_agent() rather than
# default_user_agent() since the latter is cached in an internal environment.

local_mocked_user_agent <- function(env = caller_env()) {
  local_mocked_bindings(
    req_user_agent = function(req, string = NULL) {
      req_options(req, useragent = string %||% "httr2")
    },
    .env = env
  )
}

multipart_response <- function(
  body,
  content_type = "multipart/byteranges; boundary=foo"
) {
  if (is.character(body)) {
    body <- charToRaw(body)
  }
  new_response(
    "GET",
    "https://foo.com",
    206,
    list(`Content-Type` = content_type),
    body = body
  )
}
