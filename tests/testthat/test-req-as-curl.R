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
      req_options(verbose = TRUE, ssl_verifypeer = FALSE) |>
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
      req_as_curl()
  })
})

test_that("req_as_curl() puts a request with no arguments on a single line", {
  expect_snapshot({
    request("https://hb.cran.dev/get") |>
      req_options(followlocation = FALSE) |>
      req_as_curl()
  })
})

test_that("req_as_curl() validates input", {
  expect_snapshot(error = TRUE, {
    req_as_curl("not a request")
  })
})

test_that("req_as_curl() encodes raw bodies as binary", {
  expect_snapshot({
    request("https://hb.cran.dev/post") |>
      req_body_raw(
        as.raw(c(0x00, 0x68, 0x69, 0xff)),
        type = "application/octet-stream"
      ) |>
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

test_that("dquote() quotes only when needed", {
  # plain values are left alone
  expect_equal(dquote("https://example.com/get"), "https://example.com/get")
  # spaces and query-string metacharacters force quoting
  expect_equal(dquote("a b"), "'a b'")
  expect_equal(
    dquote("https://example.com?a=1&b=2"),
    "'https://example.com?a=1&b=2'"
  )
})

test_that("dquote() protects shell metacharacters", {
  expect_equal(dquote('a"b'), "'a\"b'")
  expect_equal(dquote("a'b"), "'a'\"'\"'b'")
  expect_equal(dquote("a$b`c`\\d"), "'a$b`c`\\d'")
})

test_that("curl_body_data() safely quotes strings and JSON", {
  expect_equal(
    curl_body_data("a'b$HOME", "string"),
    "--data 'a'\"'\"'b$HOME'"
  )
  expect_equal(
    curl_body_data(list(value = "a'b$HOME"), "json"),
    "--data '{\"value\":\"a'\"'\"'b$HOME\"}'"
  )
})

test_that("curl_body_data() uses the request's JSON parameters", {
  expect_equal(
    curl_body_data(
      list(x = 1.23456, y = NULL),
      "json",
      params = list(auto_unbox = TRUE, digits = 2, null = "list")
    ),
    "--data '{\"x\":1.23,\"y\":{}}'"
  )
})

test_that("curl_body_data() URL encodes form data", {
  expect_equal(
    curl_body_data(list(x = "a b&c=d", y = "x+y", z = "é"), "form"),
    "--data 'x=a%20b%26c%3Dd&y=x%2By&z=%C3%A9'"
  )
})

test_that("curl_body_data() translates multipart values", {
  path <- tempfile()
  writeLines("contents", path)

  body <- list(
    text = "@literal;value",
    file = curl::form_file(path, type = "text/plain", name = "name.txt"),
    data = curl::form_data("a b", type = "text/plain")
  )
  expect_equal(
    curl_body_data(body, "multipart"),
    c(
      "--form-string 'text=@literal;value'",
      paste0(
        "--form 'file=@\"",
        body$file$path,
        "\";type=text/plain;filename=\"name.txt\"'"
      ),
      "--form 'data=\"a b\";type=text/plain'"
    )
  )
})

test_that("curl_body_input() base64 encodes raw bodies", {
  req <- request("https://example.com") |>
    req_body_raw(as.raw(c(0x00, 0x41, 0xff)))

  expect_equal(
    curl_body_input(req),
    "printf %s AEH/ | base64 --decode | "
  )
  expect_equal(curl_body_data(req_get_body(req), "raw"), "--data-binary @-")
})

test_that("curl_method() only sets the method when curl can't infer it", {
  req <- request("https://example.com")

  # GET is the default, and curl infers POST from a body
  expect_null(curl_method(req))
  expect_null(curl_method(req_method(req, "POST"), has_body = TRUE))

  # HEAD has its own flag
  expect_equal(curl_method(req_method(req, "HEAD")), "--head")

  # a body-less POST and other methods need --request
  expect_equal(curl_method(req_method(req, "POST")), "--request POST")
  expect_equal(
    curl_method(req_method(req, "DELETE")),
    "--request DELETE"
  )
  # a body alone implies POST, but not PUT/DELETE/etc.
  expect_equal(
    curl_method(req_method(req, "PUT"), has_body = TRUE),
    "--request PUT"
  )
})

test_that("curl_headers() drops missing headers and reveals secrets", {
  expect_null(curl_headers(request("https://example.com")))

  req <- request("https://example.com") |>
    req_headers_redacted(Authorization = "secret")
  expect_equal(
    curl_headers(req, "redact"),
    "--header 'Authorization: <REDACTED>'"
  )
  expect_equal(
    curl_headers(req, "reveal"),
    "--header 'Authorization: secret'"
  )
})

test_that("curl_options() translates each known option", {
  req <- request("https://example.com") |>
    req_options(
      timeout_ms = 30000,
      connecttimeout = 5,
      proxy = "http://proxy.example.com",
      useragent = "agent",
      followlocation = TRUE,
      verbose = TRUE,
      cookiejar = "jar.txt",
      cookiefile = "file.txt"
    )
  expect_snapshot(cat(curl_options(req), sep = "\n"))
})

test_that("curl_options() translates options set by httr2 functions", {
  req <- request("https://example.com") |>
    req_timeout(30) |>
    req_proxy(
      "proxy.example.com",
      port = 8080,
      username = "u",
      password = "p"
    ) |>
    req_user_agent("agent") |>
    req_cookie_preserve("cookies.txt") |>
    req_cookies_set(session = "abc")
  expect_snapshot(cat(curl_options(req), sep = "\n"))
})

test_that("curl_options() follows redirects by default, unlike curl", {
  expect_equal(
    curl_options(request("https://example.com")),
    "--location"
  )

  req <- request("https://example.com") |>
    req_options(followlocation = FALSE)
  expect_null(curl_options(req))
})

test_that("curl_options() ignores options with no curl equivalent", {
  # req_verbose() also sets a debugfunction; req_progress() sets callbacks
  req <- request("https://example.com") |>
    req_options(followlocation = FALSE) |>
    req_verbose() |>
    req_progress()
  expect_no_warning(out <- curl_options(req))
  expect_equal(out, "--verbose")
})

test_that("curl_options() drops disabled flags", {
  req <- request("https://example.com") |>
    req_options(followlocation = FALSE, verbose = FALSE)
  expect_null(curl_options(req))
})

test_that("curl_options() warns about untranslatable options", {
  req <- request("https://example.com") |>
    req_options(followlocation = FALSE, ssl_verifypeer = FALSE)
  expect_snapshot(out <- curl_options(req))
  expect_null(out)
})
