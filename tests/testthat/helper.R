testthat::set_state_inspector(function() {
  list(
    connections = getAllConnections(),
    the_throttle = as.list(the$throttle)
  )
})

expect_redacted <- function(req, expected) {
  expect_equal(which_redacted(req$headers), expected)
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
