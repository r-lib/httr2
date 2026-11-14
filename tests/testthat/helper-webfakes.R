local_app_request <- function(fun, method = "get", frame = parent.frame()) {
  # sometimes fails on CRAN and we don't need the hassle
  skip_on_cran()

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

# Shared app for the tests in test-resp-stream.R. Starting a webfakes process
# takes ~0.3 s, so registering all routes on one app (rather than one app per
# test with local_app_request()) speeds up the file considerably.
stream_app <- new.env(parent = emptyenv())

stream_app_request <- function(path) {
  # sometimes fails on CRAN and we don't need the hassle
  skip_on_cran()

  if (is.null(stream_app$server)) {
    app <- webfakes::new_app()
    app$locals$sync_rep <- sync_rep

    app$get("/pull", function(req, res) {
      sync <- req$app$locals$sync_rep("pull")
      res$send_chunk("This is a ")
      sync(res$send_chunk("complete sentence.\n"))
    })
    app$get("/letters", function(req, res) {
      res$send_chunk(paste0(letters[1:5], "\n", collapse = ""))
    })
    app$get("/zeros", function(req, res) {
      res$send_chunk(paste(rep_len("0", 1000), collapse = ""))
    })
    app$get("/trailing", function(req, res) {
      # "b" has no trailing line ending, so it can't be served until EOF.
      res$send_chunk("a\nb")
    })
    app$get("/lines", function(req, res) {
      res$send_chunk("line 1\n")
      res$send_chunk("line 2\n")
    })

    stream_app$server <- webfakes::local_app_process(
      app,
      .local_envir = testthat::teardown_env()
    )
  }

  request(stream_app$server$url(path))
}
