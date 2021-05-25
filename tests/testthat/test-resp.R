test_that("respinse has basic print method", {
  skip_if_not(curl::curl_version()$version == "7.64.1")
  expect_snapshot(req_fetch(req("https://httpbin.org")))
})
