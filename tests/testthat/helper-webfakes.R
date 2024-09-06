local_app_request <- function(get, frame = parent.frame()) {
  # Works interactively (useful for manaul coverage checking)
  # but not in separate process
  if (!is_interactive()) {
    skip_on_covr()
  }

  app <- webfakes::new_app()
  app$get("/test", get)
  server <- webfakes::local_app_process(app, .local_envir = frame)

  req <- request(server$url("/test"))
  req <- req_error(req, body = function(resp) resp_body_string(resp))
  req
}
