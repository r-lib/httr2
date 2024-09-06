test_that("validates inputs", {
  expect_snapshot(error = TRUE, {
    req_perform_connection(1)
    req_perform_connection(request_test(), 1)
  })
})

test_that("can read all data from a connection", {
  resp <- request_test("/stream-bytes/2048") %>% req_perform_connection()
  withr::defer(close(resp))

  out <- resp_body_raw(resp)
  expect_length(out, 2048)
  expect_false(resp_has_body(resp))
})

test_that("reads body on error", {
  app <- webfakes::new_app()
  app$get("/fail", function(req, res) {
    res$set_status(404L)$send_json(list(status = 404), auto_unbox = TRUE)
  })
  server <- webfakes::local_app_process(app)
  req <- request(server$url("/fail"))

  expect_error(req_perform_connection(req), class = "httr2_http_404")
  resp <- last_response()
  expect_equal(resp_body_json(resp), list(status = 404))
})

test_that("can retry a transient error", {
  app <- webfakes::new_app()
  app$get("/retry", function(req, res) {
    i <- res$app$locals$i %||% 1
    if (i == 1) {
      res$app$locals$i <- 2
      res$
        set_status(429)$
        set_header("retry-after", 0)$
        send_json(list(status = list("waiting")))
    } else {
      res$send_json(list(status = list("done")))
    }
  })

  server <- webfakes::local_app_process(app)
  req <- request(server$url("/retry")) %>%
    req_retry(max_tries = 2)

  cnd <- catch_cnd(resp <- req_perform_connection(req), "httr2_retry")
  expect_s3_class(cnd, "httr2_retry")
  expect_equal(cnd$tries, 1)
  expect_equal(cnd$delay, 0)

  expect_equal(resp_body_json(resp), list(status = list("done")))
})
