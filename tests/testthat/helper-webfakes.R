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
# takes ~0.3 s, so tests share one app (rather than one per test with
# local_app_request()). Routes can't be added once the process is running, so
# the routes take their behavior from the request and each test just picks a
# URL.
stream_app <- new.env(parent = emptyenv())

stream_app_request <- function(path) {
  # sometimes fails on CRAN and we don't need the hassle
  skip_on_cran()

  if (is.null(stream_app$server)) {
    app <- webfakes::new_app()
    app$locals$sync_rep <- sync_rep

    app$get("/chunks", function(req, res) {
      chunks <- unname(req$query[startsWith(names(req$query), "chunk")])
      for (chunk in chunks) {
        res$send_chunk(chunk)
      }
    })
    app$get("/pull", function(req, res) {
      sync <- req$app$locals$sync_rep("pull")
      res$send_chunk("This is a ")
      sync(res$send_chunk("complete sentence.\n"))
    })

    stream_app$server <- webfakes::local_app_process(
      app,
      .local_envir = testthat::teardown_env()
    )
  }

  request(stream_app$server$url(path))
}

# Request that the shared app send each chunk in ... (in order).
stream_app_chunks <- function(...) {
  query <- paste0(
    "chunk=",
    utils::URLencode(c(...), reserved = TRUE),
    collapse = "&"
  )
  stream_app_request(paste0("/chunks?", query))
}
