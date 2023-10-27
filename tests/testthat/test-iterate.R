test_that("can perform multiple requests", {
  req <- request(example_url()) %>%
    req_url_path("/iris") %>%
    req_url_query(limit = 5)

  resps <- req_perform_iteratively(
    req,
    next_req = iterate_with_offset("page_index"),
    max_reqs = 4
  )

  expect_length(resps, 4)
  expect_equal(resp_url(resps[[4]]), paste0(example_url(), "iris?limit=5&page_index=4"))
})

test_that("can save results to disk", {
  req <- request(example_url()) %>%
    req_url_path("/iris") %>%
    req_url_query(limit = 5)

  dir <- withr::local_tempdir()

  resps <- req_perform_iteratively(
    req,
    next_req = iterate_with_offset("page_index"),
    max_reqs = 2,
    path = paste0(dir, "/file-{i}")
  )

  expect_equal(resps[[1]]$body, new_path(file.path(dir, "file-1")))
  expect_equal(resps[[2]]$body, new_path(file.path(dir, "file-2")))
})

test_that("user temination still returns data", {
  req <- request(example_url()) %>%
    req_url_path("/iris") %>%
    req_url_query(limit = 5)
  next_req <- function(resp, req) interrupt()

  expect_snapshot(
    resps <- req_perform_iteratively(req, next_req = next_req)
  )
  expect_length(resps, 1)
})


test_that("can retrieve all pages", {
  req <- request(example_url()) %>%
    req_url_path("/iris") %>%
    req_url_query(limit = 1)

  i <- 1
  next_req <- function(resp, req) {
    i <<- i + 1
    if (i <= 120) {
      req %>% req_url_query(page_index = 1)
    }
  }
  expect_condition(
    resps <- req_perform_iteratively(req, next_req = next_req, max_reqs = Inf),
    class = "httr2:::doubled"
  )
  expect_length(resps, 120)
})

test_that("checks its inputs", {
  req <- request_test()
  expect_snapshot(error = TRUE,{
    req_perform_iteratively(1)
    req_perform_iteratively(req, function(x, y) x + y)
    req_perform_iteratively(req, function(resp, req) {}, path = 1)
    req_perform_iteratively(req, function(resp, req) {}, max_reqs = -1)
    req_perform_iteratively(req, function(resp, req) {}, progress = -1)
  })
})