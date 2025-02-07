test_that("can perform multiple requests", {
  req <- request(example_url("/iris")) %>%
    req_url_query(limit = 5)

  resps <- req_perform_iterative(
    req,
    next_req = iterate_with_offset("page_index"),
    max_reqs = 4
  )

  expect_length(resps, 4)
  expect_equal(resp_url(resps[[4]]), paste0(example_url(), "iris?limit=5&page_index=4"))
})

test_that("can save results to disk", {
  req <- request(example_url("/iris")) %>%
    req_url_query(limit = 5)

  dir <- withr::local_tempdir()

  resps <- req_perform_iterative(
    req,
    next_req = iterate_with_offset("page_index"),
    max_reqs = 2,
    path = paste0(dir, "/file-{i}")
  )

  expect_equal(resps[[1]]$body, new_path(file.path(dir, "file-1")))
  expect_equal(resps[[2]]$body, new_path(file.path(dir, "file-2")))
})

test_that("user temination still returns data", {
  req <- request(example_url("/iris")) %>%
    req_url_query(limit = 5)
  next_req <- function(resp, req) interrupt()

  expect_snapshot(
    resps <- req_perform_iterative(req, next_req = next_req)
  )
  expect_length(resps, 1)
})


test_that("can retrieve all pages", {
  req <- request(example_url("/iris")) %>%
    req_url_query(limit = 1)

  i <- 1
  next_req <- function(resp, req) {
    i <<- i + 1
    if (i <= 120) {
      req %>% req_url_query(page_index = 1)
    }
  }
  expect_condition(
    resps <- req_perform_iterative(req, next_req = next_req, max_reqs = Inf),
    class = "httr2:::doubled"
  )
  expect_length(resps, 120)
})

test_that("can choose to return on failure", {
  iterator <- function(resp, req) {
    request_test("/status/:status", status = 404)
  }
  expect_error(
    req_perform_iterative(request_test(), iterator),
    class = "httr2_http_404"
  )

  out <- req_perform_iterative(request_test(), iterator, on_error = "return")
  expect_length(out, 2)
  expect_s3_class(out[[1]], "httr2_response")
  expect_s3_class(out[[2]], "httr2_http_404")
})

test_that("checks its inputs", {
  req <- request_test()
  expect_snapshot(error = TRUE, {
    req_perform_iterative(1)
    req_perform_iterative(req, function(x, y) x + y)
    req_perform_iterative(req, function(resp, req) {}, path = 1)
    req_perform_iterative(req, function(resp, req) {}, max_reqs = -1)
    req_perform_iterative(req, function(resp, req) {}, progress = -1)
  })
})
