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

test_that("req_as_curl() can reveal obfuscated values", {
  expect_snapshot({
    request("https://hb.cran.dev/get") |>
      req_headers_redacted(Authorization = "secret-token") |>
      req_as_curl(obfuscated = "reveal")
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

test_that("req_as_curl() reads raw bodies from stdin", {
  expect_snapshot({
    request("https://hb.cran.dev/post") |>
      req_body_raw(charToRaw("test data"), type = "text/plain") |>
      req_as_curl()
  })
})

test_that("an explicit Content-Type header isn't duplicated by the body", {
  expect_snapshot({
    request("https://hb.cran.dev/post") |>
      req_headers("Content-Type" = "application/json") |>
      req_body_raw("{}") |>
      req_as_curl()
  })
})

test_that("req_method_as_curl() only sets the method when it's not GET", {
  expect_null(req_method_as_curl(request("https://example.com")))
  expect_equal(
    req_method_as_curl(req_method(request("https://example.com"), "DELETE")),
    "-X DELETE"
  )
})

test_that("req_headers_as_curl() drops missing headers and reveals secrets", {
  expect_null(req_headers_as_curl(request("https://example.com")))

  req <- request("https://example.com") |>
    req_headers_redacted(Authorization = "secret")
  expect_equal(
    req_headers_as_curl(req, "redact"),
    '-H "Authorization: <REDACTED>"'
  )
  expect_equal(
    req_headers_as_curl(req, "reveal"),
    '-H "Authorization: secret"'
  )
})

test_that("req_options_as_curl() translates each known option", {
  req <- request("https://example.com") |>
    req_options(
      timeout = 30,
      connecttimeout = 5,
      proxy = "http://proxy.example.com",
      useragent = "agent",
      referer = "http://referer.example.com",
      followlocation = TRUE,
      verbose = TRUE,
      cookiejar = "jar.txt",
      cookiefile = "file.txt"
    )
  expect_snapshot(cat(req_options_as_curl(req), sep = "\n"))
})

test_that("req_options_as_curl() drops disabled flags", {
  req <- request("https://example.com") |>
    req_options(followlocation = FALSE, verbose = FALSE)
  expect_null(req_options_as_curl(req))
})

test_that("req_options_as_curl() warns about untranslatable options", {
  req <- request("https://example.com") |>
    req_options(ssl_verifypeer = FALSE)
  expect_snapshot(out <- req_options_as_curl(req))
  expect_null(out)
})

test_that("curl_command() formats zero, one, and many arguments", {
  expect_equal(
    curl_command(NULL, "https://example.com"),
    'curl "https://example.com"'
  )
  expect_snapshot(
    cat(curl_command(
      c("-X POST", '-H "Accept: text/plain"'),
      "https://example.com"
    ))
  )
})
