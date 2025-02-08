testthat::set_state_inspector(function() {
  list(
    connections = getAllConnections(),
    the_throttle = as.list(the$throttle)
  )
})

expect_redacted <- function(req, expected) {
  expect_equal(attr(req$headers, "redact"), expected)
}
