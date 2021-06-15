test_that("invalid token test is specific", {
  req <- request("https://example.com")
  resp_invalid <- response(401, headers = 'WWW-Authenticate: Bearer realm="example", error="invalid_token", error_description="The access token expired"')

  # Doesn't trigger for response if request doesn't use OAuth
  expect_false(resp_is_invalid_oauth_token(req, resp_invalid))

  req <- req_oauth(req, "", list(), NULL)
  expect_false(resp_is_invalid_oauth_token(req, response(200)))
  expect_false(resp_is_invalid_oauth_token(req, response(401)))
  expect_true(resp_is_invalid_oauth_token(req, resp_invalid))
})


# Cache -------------------------------------------------------------------

test_that("can store in memory", {
  client <- oauth_client(
    id = "x",
    token_url = "http://example.com",
    name = "httr2-test"
  )

  cache <- cache_mem(client, NULL)
  withr::defer(cache$clear())

  expect_equal(cache$get(), NULL)
  cache$set(1)
  expect_equal(cache$get(), 1)
  cache$clear()
  expect_equal(cache$get(), NULL)
})

test_that("can store on disk", {
  client <- oauth_client(
    id = "x",
    token_url = "http://example.com",
    name = "httr2-test"
  )

  cache <- cache_disk(client, NULL)
  withr::defer(cache$clear())

  expect_equal(cache$get(), NULL)
  cache$set(1)
  expect_equal(cache$get(), 1)
  cache$clear()
  expect_equal(cache$get(), NULL)
})
