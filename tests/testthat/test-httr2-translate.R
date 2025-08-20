test_that("httr2_translate() works with basic GET requests", {
  expect_snapshot({
    request("https://httpbin.org/get") |>
      httr2_translate()
  })
})

test_that("httr2_translate() works with POST methods", {
  expect_snapshot({
    request("https://httpbin.org/post") |>
      req_method("POST") |>
      httr2_translate()
  })
})

test_that("httr2_translate() works with headers", {
  expect_snapshot({
    request("https://httpbin.org/get") |>
      req_headers(
        "Accept" = "application/json",
        "User-Agent" = "httr2/1.0"
      ) |>
      httr2_translate()
  })
})

test_that("httr2_translate() works with JSON bodies", {
  expect_snapshot({
    request("https://httpbin.org/post") |>
      req_body_json(list(name = "test", value = 123)) |>
      httr2_translate()
  })
})

test_that("httr2_translate() works with form bodies", {
  expect_snapshot({
    request("https://httpbin.org/post") |>
      req_body_form(name = "test", value = "123") |>
      httr2_translate()
  })
})

test_that("httr2_translate() works with multipart bodies", {
  expect_snapshot({
    request("https://httpbin.org/post") |>
      req_body_multipart(name = "test", value = "123") |>
      httr2_translate()
  })
})

test_that("httr2_translate() works with string bodies", {
  expect_snapshot({
    request("https://httpbin.org/post") |>
      req_body_raw("test data", type = "text/plain") |>
      httr2_translate()
  })
})

test_that("httr2_translate() works with file bodies", {
  path <- tempfile()
  writeLines("test content", path)

  # normalize the path
  path <- normalizePath(path, winslash = "/")

  expect_snapshot(
    {
      request("https://httpbin.org/post") |>
        req_body_file(path, type = "text/plain") |>
        httr2_translate()
    },
    transform = function(x) {
      gsub(path, "<tempfile>", x, fixed = TRUE)
    }
  )
})

test_that("httr2_translate() works with custom content types", {
  expect_snapshot({
    request("https://httpbin.org/post") |>
      req_body_json(
        list(test = "data"),
        type = "application/vnd.api+json"
      ) |>
      httr2_translate()
  })
})

test_that("httr2_translate() works with options", {
  expect_snapshot({
    request("https://httpbin.org/get") |>
      req_options(timeout = 30, verbose = TRUE, ssl_verifypeer = FALSE) |>
      httr2_translate()
  })
})

test_that("httr2_translate() works with cookies", {
  cookie_file <- tempfile()

  # create the tempfile
  file.create(cookie_file)

  # normalize the path
  cookie_file <- normalizePath(cookie_file, winslash = "/")

  expect_snapshot(
    {
      request("https://httpbin.org/cookies") |>
        req_options(cookiejar = cookie_file, cookiefile = cookie_file) |>
        httr2_translate()
    },
    transform = function(x) {
      gsub(cookie_file, "<cookie-file>", x, fixed = TRUE)
    }
  )
})

test_that("httr2_translate() works with obfuscated values in headers", {
  expect_snapshot({
    request("https://httpbin.org/get") |>
      req_headers("Authorization" = obfuscated("ZdYJeG8zwISodg0nu4UxBhs")) |>
      httr2_translate()
  })
})

test_that("httr2_translate() works with obfuscated values in JSON body", {
  expect_snapshot({
    request("https://httpbin.org/post") |>
      req_body_json(list(
        username = "test",
        password = obfuscated("ZdYJeG8zwISodg0nu4UxBhs")
      )) |>
      httr2_translate()
  })
})

test_that("httr2_translate() works with obfuscated values in form body", {
  expect_snapshot({
    request("https://httpbin.org/post") |>
      req_body_form(
        username = "test",
        password = obfuscated("ZdYJeG8zwISodg0nu4UxBhs")
      ) |>
      httr2_translate()
  })
})

test_that("httr2_translate() works with complex requests", {
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
      httr2_translate()
  })
})

test_that("httr2_translate() works with simple requests (single line)", {
  expect_snapshot({
    request("https://httpbin.org/get") |>
      httr2_translate()
  })
})

test_that("httr2_translate() validates input", {
  expect_snapshot(error = TRUE, {
    httr2_translate("not a request")
  })
})
