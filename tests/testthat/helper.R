testthat::set_state_inspector(function() {
  list(connections = getAllConnections())
})

expect_redacted <- function(req, expected) {
  expect_equal(attr(req$headers, "redact"), expected)
}
