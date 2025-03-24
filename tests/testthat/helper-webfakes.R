local_app_request <- function(fun, method = "get", frame = parent.frame()) {
  # sometimes fails on CRAN and we don't need the hassle
  skip_on_cran()
  # Works interactively (useful for manaul coverage checking)
  # but not in separate process
  if (!interactive()) {
    skip_on_covr()
  }

  app <- webfakes::new_app()

  app$locals$i <- 0
  app$use(function(req, res) {
    app$locals$i <- app$locals$i + 1
    "next"
  })

  app[[method]]("/test", fun)
  app$locals$sync_rep <- sync_rep
  server <- webfakes::local_app_process(app, .local_envir = frame)

  req <- request(server$url("/test"))
  req <- req_error(req, body = function(resp) {
    if (resp_has_body(resp)) resp_body_string(resp)
  })
  req
}
