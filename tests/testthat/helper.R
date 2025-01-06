testthat::set_state_inspector(function() {
  list(connections = getAllConnections())
})
