test_that("invalid token test is specific", {
  req <- request("https://example.com")
  resp_invalid <- response(
    401,
    headers = 'WWW-Authenticate: Bearer realm="example", error="invalid_token", error_description="The access token expired"'
  )

  # Doesn't trigger for response if request doesn't use OAuth
  expect_false(resp_is_invalid_oauth_token(req, resp_invalid))

  req <- req_oauth(req, "", list(), NULL)
  expect_false(resp_is_invalid_oauth_token(req, response(200)))
  expect_false(resp_is_invalid_oauth_token(req, response(401)))
  expect_true(resp_is_invalid_oauth_token(req, resp_invalid))
})


# auth_oauth_token_get() --------------------------------------------------

test_that("can request and cache token if not present", {
  client <- oauth_client("test", "http://example.org/test")
  cache <- cache_mem(client)

  token <- oauth_token("123")
  expect_equal(auth_oauth_token_get(cache, function(...) token), token)
  expect_equal(cache$get(), token)
})

test_that("can re-flow to get new token", {
  client <- oauth_client("test", "http://example.org/test")
  cache <- cache_mem(client)
  cache$set(oauth_token("123", expires_in = -60))

  token <- oauth_token("123")
  expect_equal(auth_oauth_token_get(cache, function(...) token), token)
  expect_equal(cache$get(), token)

  # and cache is cleared if
  cache$set(oauth_token("123", expires_in = -60))
  expect_error(auth_oauth_token_get(cache, function(...) stop("Bad!")))
  expect_equal(cache$get(), NULL)
})

test_that("can refresh to get new token", {
  client <- oauth_client("test", "http://example.org/test")
  cache <- cache_mem(client)
  cache$set(oauth_token("123", refresh_token = "456", expires_in = -60))

  local_mocked_bindings(
    oauth_client_get_token = function(...) oauth_token("789")
  )

  new_token <- oauth_token("789", refresh_token = "456")
  expect_equal(auth_oauth_token_get(cache, function(...) NULL), new_token)
  expect_equal(cache$get(), new_token)
})

test_that("can reflow if refresh fails", {
  client <- oauth_client("test", "http://example.org/test")
  cache <- cache_mem(client)
  cache$set(oauth_token("123", refresh_token = "456", expires_in = -60))

  local_mocked_bindings(
    oauth_client_get_token = function(...) oauth_flow_abort("Nope")
  )

  token <- oauth_token("789")
  expect_equal(auth_oauth_token_get(cache, function(...) token), token)
  expect_equal(cache$get(), token)
})

test_that("can retrieve non-expired token from cache", {
  client <- oauth_client("test", "http://example.org/test")
  cache <- cache_mem(client)

  token <- oauth_token("123")
  cache$set(token)
  expect_equal(auth_oauth_token_get(cache, oauth_flow_refresh), token)
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
  expect_snapshot(
    cache$set(1),
    transform = function(x) {
      gsub(oauth_cache_path(), "<oauth-cache-path>", x, fixed = TRUE)
    }
  )
  expect_equal(cache$get(), 1)
  cache$clear()
  expect_equal(cache$get(), NULL)
})

test_that("can explicitly clear cached value", {
  client <- oauth_client(
    id = "x",
    token_url = "http://example.com",
    name = "httr2-test"
  )
  cache <- cache_mem(client, NULL)
  cache$set("abcdef")

  oauth_cache_clear(client)
  expect_equal(cache$get(), NULL)
})

test_that("can prune old files", {
  path <- withr::local_tempdir()
  touch(file.path(path, "a-token.rds"), Sys.time() - 86400 * 1)
  touch(file.path(path, "b-token.rds"), Sys.time() - 86400 * 2)
  cache_disk_prune(2, path)
  expect_equal(dir(path), "a-token.rds")
})

# cache_path --------------------------------------------------------------

test_that("can override path with env var", {
  withr::local_envvar("HTTR2_OAUTH_CACHE" = "/tmp")
  expect_equal(oauth_cache_path(), "/tmp")
})
