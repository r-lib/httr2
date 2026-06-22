test_that("httr2_translate() works with basic GET requests", {
  local_mocked_user_agent()
  expect_snapshot({
    request("https://hb.cran.dev/get") |>
      httr2_translate()
  })
})

test_that("httr2_translate() works with POST methods", {
  local_mocked_user_agent()
  expect_snapshot({
    request("https://hb.cran.dev/post") |>
      req_method("POST") |>
      httr2_translate()
  })
})

test_that("httr2_translate() works with headers", {
  local_mocked_user_agent()
  expect_snapshot({
    request("https://hb.cran.dev/get") |>
      req_headers(
        "Accept" = "application/json",
        "User-Agent" = "httr2/1.0"
      ) |>
      httr2_translate()
  })
})

test_that("httr2_translate() works with JSON bodies", {
  local_mocked_user_agent()
  expect_snapshot({
    request("https://hb.cran.dev/post") |>
      req_body_json(list(name = "test", value = 123)) |>
      httr2_translate()
  })
})

test_that("httr2_translate() works with form bodies", {
  local_mocked_user_agent()
  expect_snapshot({
    request("https://hb.cran.dev/post") |>
      req_body_form(name = "test", value = "123") |>
      httr2_translate()
  })
})

test_that("httr2_translate() works with multipart bodies", {
  local_mocked_user_agent()
  expect_snapshot({
    request("https://hb.cran.dev/post") |>
      req_body_multipart(name = "test", value = "123") |>
      httr2_translate()
  })
})

test_that("httr2_translate() works with string bodies", {
  local_mocked_user_agent()
  expect_snapshot({
    request("https://hb.cran.dev/post") |>
      req_body_raw("test data", type = "text/plain") |>
      httr2_translate()
  })
})

test_that("httr2_translate() works with file bodies", {
  local_mocked_user_agent()
  path <- tempfile()
  writeLines("test content", path)

  # normalize the path
  path <- normalizePath(path, winslash = "/")

  expect_snapshot(
    {
      request("https://hb.cran.dev/post") |>
        req_body_file(path, type = "text/plain") |>
        httr2_translate()
    },
    transform = function(x) {
      gsub(path, "<tempfile>", x, fixed = TRUE)
    }
  )
})

test_that("httr2_translate() works with custom content types", {
  local_mocked_user_agent()
  expect_snapshot({
    request("https://hb.cran.dev/post") |>
      req_body_json(
        list(test = "data"),
        type = "application/vnd.api+json"
      ) |>
      httr2_translate()
  })
})

test_that("httr2_translate() works with options", {
  local_mocked_user_agent()
  expect_snapshot({
    request("https://hb.cran.dev/get") |>
      req_options(verbose = TRUE, ssl_verifypeer = FALSE) |>
      httr2_translate()
  })
})

test_that("httr2_translate() works with cookies", {
  local_mocked_user_agent()
  cookie_file <- tempfile()

  # create the tempfile
  file.create(cookie_file)

  # normalize the path
  cookie_file <- normalizePath(cookie_file, winslash = "/")

  expect_snapshot(
    {
      request("https://hb.cran.dev/cookies") |>
        req_options(cookiejar = cookie_file, cookiefile = cookie_file) |>
        httr2_translate()
    },
    transform = function(x) {
      gsub(cookie_file, "<cookie-file>", x, fixed = TRUE)
    }
  )
})

test_that("httr2_translate() works with obfuscated values in headers", {
  local_mocked_user_agent()
  expect_snapshot({
    request("https://hb.cran.dev/get") |>
      req_headers("Authorization" = obfuscated("ZdYJeG8zwISodg0nu4UxBhs")) |>
      httr2_translate()
  })
})

test_that("httr2_translate() can reveal obfuscated values", {
  local_mocked_user_agent()
  expect_snapshot({
    request("https://hb.cran.dev/get") |>
      req_headers_redacted(Authorization = "secret-token") |>
      httr2_translate(obfuscated = "reveal")
  })
})

test_that("httr2_translate() works with obfuscated values in JSON body", {
  local_mocked_user_agent()
  expect_snapshot({
    request("https://hb.cran.dev/post") |>
      req_body_json(list(
        username = "test",
        password = obfuscated("ZdYJeG8zwISodg0nu4UxBhs")
      )) |>
      httr2_translate()
  })
})

test_that("httr2_translate() works with obfuscated values in form body", {
  local_mocked_user_agent()
  expect_snapshot({
    request("https://hb.cran.dev/post") |>
      req_body_form(
        username = "test",
        password = obfuscated("ZdYJeG8zwISodg0nu4UxBhs")
      ) |>
      httr2_translate()
  })
})

test_that("httr2_translate() works with complex requests", {
  local_mocked_user_agent()
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
      httr2_translate()
  })
})

test_that("httr2_translate() puts a request with no arguments on a single line", {
  local_mocked_user_agent()
  expect_snapshot({
    request("https://hb.cran.dev/get") |>
      req_options(followlocation = FALSE) |>
      httr2_translate()
  })
})

test_that("httr2_translate() validates input", {
  expect_snapshot(error = TRUE, {
    httr2_translate("not a request")
  })
})

test_that("httr2_translate() signs AWS requests", {
  req <- request("https://sts.us-east-1.amazonaws.com/") |>
    req_body_form(
      Action = "GetCallerIdentity",
      Version = "2011-06-15"
    ) |>
    req_auth_aws_v4(
      aws_access_key_id = "AKIAIOSFODNN7EXAMPLE",
      aws_secret_access_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
    )

  command <- as.character(httr2_translate(req, obfuscated = "reveal"))
  expect_match(
    command,
    "Authorization: AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/"
  )
  expect_match(
    command,
    "SignedHeaders=host;x-amz-date"
  )
  expect_match(command, "--header 'x-amz-date: [0-9]{8}T[0-9]{6}Z'")
})

test_that("httr2_translate() errors for raw bodies", {
  req <- request("https://hb.cran.dev/post") |>
    req_body_raw(as.raw(c(0x00, 0x68, 0x69, 0xff)))
  expect_snapshot(httr2_translate(req), error = TRUE)
})

test_that("an explicit Content-Type header isn't duplicated by the body", {
  local_mocked_user_agent()
  expect_snapshot({
    request("https://hb.cran.dev/post") |>
      req_headers("Content-Type" = "application/json") |>
      req_body_raw("{}") |>
      httr2_translate()
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
  path <- file.path(withr::local_tempdir(), "contents")
  writeLines("contents", path)

  body <- list(
    text = "@literal;value",
    file = curl::form_file(path, type = "text/plain", name = "name.txt"),
    data = curl::form_data("a b", type = "text/plain")
  )
  expect_snapshot(
    writeLines(curl_body_data(body, "multipart")),
    # the temp file path varies and uses (escaped) \ on Windows
    transform = function(x) gsub('@"[^"]+"', '@"<tmppath>"', x)
  )
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
