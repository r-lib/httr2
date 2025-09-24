test_that("req_as_curl() works with basic GET requests", {
  expect_snapshot({
    request("https://hb.cran.dev/get") |>
      req_as_curl()
  })
})

test_that("req_as_curl() works with POST methods", {
  expect_snapshot({
    request("https://hb.cran.dev/post") |>
      req_method("POST") |>
      req_as_curl()
  })
})

test_that("req_as_curl() works with headers", {
  expect_snapshot({
    request("https://hb.cran.dev/get") |>
      req_headers(
        "Accept" = "application/json",
        "User-Agent" = "httr2/1.0"
      ) |>
      req_as_curl()
  })
})

test_that("req_as_curl() works with JSON bodies", {
  expect_snapshot({
    request("https://hb.cran.dev/post") |>
      req_body_json(list(name = "test", value = 123)) |>
      req_as_curl()
  })
})

test_that("req_as_curl() works with form bodies", {
  expect_snapshot({
    request("https://hb.cran.dev/post") |>
      req_body_form(name = "test", value = "123") |>
      req_as_curl()
  })
})

test_that("req_as_curl() works with multipart bodies", {
  expect_snapshot({
    request("https://hb.cran.dev/post") |>
      req_body_multipart(name = "test", value = "123") |>
      req_as_curl()
  })
})

test_that("req_as_curl() works with string bodies", {
  expect_snapshot({
    request("https://hb.cran.dev/post") |>
      req_body_raw("test data", type = "text/plain") |>
      req_as_curl()
  })
})

test_that("req_as_curl() works with file bodies", {
  path <- tempfile()
  writeLines("test content", path)

  # normalize the path
  path <- normalizePath(path, winslash = "/")

  expect_snapshot(
    {
      request("https://hb.cran.dev/post") |>
        req_body_file(path, type = "text/plain") |>
        req_as_curl()
    },
    transform = function(x) {
      gsub(path, "<tempfile>", x, fixed = TRUE)
    }
  )
})

test_that("req_as_curl() works with custom content types", {
  expect_snapshot({
    request("https://hb.cran.dev/post") |>
      req_body_json(
        list(test = "data"),
        type = "application/vnd.api+json"
      ) |>
      req_as_curl()
  })
})

test_that("req_as_curl() works with options", {
  expect_snapshot({
    request("https://hb.cran.dev/get") |>
      req_options(timeout = 30, verbose = TRUE, ssl_verifypeer = FALSE) |>
      req_as_curl()
  })
})

test_that("req_as_curl() works with cookies", {
  cookie_file <- tempfile()

  # create the tempfile
  file.create(cookie_file)

  # normalize the path
  cookie_file <- normalizePath(cookie_file, winslash = "/")

  expect_snapshot(
    {
      request("https://hb.cran.dev/cookies") |>
        req_options(cookiejar = cookie_file, cookiefile = cookie_file) |>
        req_as_curl()
    },
    transform = function(x) {
      gsub(cookie_file, "<cookie-file>", x, fixed = TRUE)
    }
  )
})

test_that("req_as_curl() works with obfuscated values in headers", {
  expect_snapshot({
    request("https://hb.cran.dev/get") |>
      req_headers("Authorization" = obfuscated("ZdYJeG8zwISodg0nu4UxBhs")) |>
      req_as_curl()
  })
})

test_that("req_as_curl() works with obfuscated values in JSON body", {
  expect_snapshot({
    request("https://hb.cran.dev/post") |>
      req_body_json(list(
        username = "test",
        password = obfuscated("ZdYJeG8zwISodg0nu4UxBhs")
      )) |>
      req_as_curl()
  })
})

test_that("req_as_curl() works with obfuscated values in form body", {
  expect_snapshot({
    request("https://hb.cran.dev/post") |>
      req_body_form(
        username = "test",
        password = obfuscated("ZdYJeG8zwISodg0nu4UxBhs")
      ) |>
      req_as_curl()
  })
})

test_that("req_as_curl() works with complex requests", {
  expect_snapshot({
    request("https://api.github.com/user/repos") |>
      req_method("POST") |>
      req_headers(
        "Accept" = "application/vnd.github.v3+json",
        "Authorization" = obfuscated("ZdYJeG8zwISodg0nu4UxBhs"),
        "User-Agent" = "MyApp/1.0"
      ) |>
      req_body_json(list(
        name = "test-repo",
        description = "A test repository",
        private = TRUE
      )) |>
      req_options(timeout = 60) |>
      req_as_curl()
  })
})

test_that("req_as_curl() works with simple requests (single line)", {
  expect_snapshot({
    request("https://hb.cran.dev/get") |>
      req_as_curl()
  })
})

test_that("req_as_curl() validates input", {
  expect_snapshot(error = TRUE, {
    req_as_curl("not a request")
  })
})
