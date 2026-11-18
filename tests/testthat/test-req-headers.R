test_that("can add and remove headers", {
  req <- request("http://example.com")
  req <- req |> req_headers(x = 1)
  expect_equal(req$headers, new_headers(list(x = 1)))
  req <- req |> req_headers(x = NULL)
  expect_equal(req$headers, new_headers(list()))
})

test_that("simple vectors automatically converted to strings", {
  req <- request("http://example.com")
  req <- req |> req_headers(lgl = TRUE, int = 1L, dbl = 1.1, chr = "a")
  resp <- req_dry_run(req, quiet = TRUE)

  expect_equal(resp$headers$lgl, "TRUE")
  expect_equal(resp$headers$int, "1")
  expect_equal(resp$headers$dbl, "1.1")
  expect_equal(resp$headers$chr, "a")
})

test_that("bad inputs get clear error", {
  req <- request("http://example.com")
  expect_snapshot(error = TRUE, {
    req_headers(req, fun = mtcars)
    req_headers(req, 1)
  })
})

test_that("can add header called req", {
  req <- request("http://example.com")
  req <- req |> req_headers(req = 1)
  expect_equal(req$headers, new_headers(list(req = 1)))
})

test_that("can add repeated headers", {
  resp <- request_test() |>
    req_headers(a = c("a", "b")) |>
    req_dry_run(quiet = TRUE)
  # https://datatracker.ietf.org/doc/html/rfc7230#section-3.2.2
  expect_equal(resp$headers$a, "a,b")
})

test_that("replacing headers is case-insensitive", {
  req <- request("http://example.com")
  req <- req |> req_headers(A = 1)
  req <- req |> req_headers(a = 2)
  expect_equal(req$headers, new_headers(list(a = 2)))
})

# accessor ----------------------------------------------------------------

test_that("can control redaction", {
  req <- request("http://example.com")
  req <- req_headers(req, a = 1L, b = 2L, .redact = "a")

  expect_equal(req_get_headers(req, "drop"), list(b = "2"))
  expect_equal(req_get_headers(req, "redact"), list(a = "<REDACTED>", b = "2"))
  expect_equal(req_get_headers(req, "reveal"), list(a = "1", b = "2"))
})

test_that("empty redacted headers are always dropped", {
  req <- request("http://example.com")
  req <- req_headers(req, a = 1L, b = 2L, .redact = "a")
  req2 <- unserialize(serialize(req, NULL))

  expect_equal(req_get_headers(req2, "drop"), list(b = "2"))
  expect_equal(req_get_headers(req2, "redact"), list(b = "2"))
  expect_equal(req_get_headers(req2, "reveal"), list(b = "2"))
})

# redaction ---------------------------------------------------------------

test_that("can control which headers to redact", {
  req <- request("http://example.com")
  expect_redacted(req_headers(req, a = 1L, b = 2L), character())
  expect_redacted(req_headers(req, a = 1L, b = 2L, .redact = "a"), "a")
  expect_redacted(
    req_headers(req, a = 1L, b = 2L, .redact = c("a", "b")),
    c("a", "b")
  )
})

test_that("only redacts supplied headers", {
  req <- request("http://example.com")
  expect_redacted(req_headers(req, a = 1L, b = 2L, .redact = "d"), character())
})

test_that("redaction preserved across calls", {
  req <- request("http://example.com")
  req <- req_headers(req, a = 1L, .redact = "a")
  req <- req_headers(req, a = 2)
  expect_redacted(req, "a")
  expect_equal(headers_flatten(req$headers, FALSE), list(a = "2"))

  # and is reapplied regadless of case
  req <- req_headers(req, A = 3)
  expect_redacted(req, "A")
  expect_equal(headers_flatten(req$headers, FALSE), list(A = "3"))
})

test_that("req_headers_redacted redacts all headers", {
  req <- request("http://example.com")
  expect_redacted(req_headers_redacted(req, a = 1L, b = 2L), c("a", "b"))
})

test_that("is case insensitive", {
  req <- request("http://example.com")
  req <- req_headers(req, a = 1L, .redact = "A")
  expect_redacted(req, "a")
  expect_snapshot(req)

  # Test the other direction too, just to be safe
  req <- request("http://example.com")
  req <- req_headers(req, A = 1L, .redact = "a")
  expect_redacted(req, "A")
})

test_that("authorization is always redacted", {
  req <- request("http://example.com")
  expect_redacted(req_headers(req, Authorization = "X"), "Authorization")
})

test_that("checks input types", {
  req <- request("http://example.com")
  expect_snapshot(error = TRUE, {
    req_headers(req, a = 1L, b = 2L, .redact = 1L)
  })
})

# secrets ---------------------------------------------------------------------

test_that("secret headers display redacted", {
  req <- request("http://example.com") |>
    req_headers(
      a = secret_envvar("SECRET_HEADER_TEST"),
      b = secret_value("abc"),
      c = \() "abc",
      d = obfuscated("ZdYJeG8zwISodg0nu4UxBhs")
    )
  expect_snapshot(req)
})

test_that("secret headers are resolved on the wire", {
  withr::local_envvar(SECRET_HEADER_TEST = "from-env")

  req <- request_test("/headers") |>
    req_headers(
      `x-env` = secret_envvar("SECRET_HEADER_TEST"),
      `x-fun` = \() "from-function",
      `x-obf` = obfuscated("ZdYJeG8zwISodg0nu4UxBhs")
    )
  headers <- req_perform(req) |> resp_body_json() |> _$headers
  expect_equal(headers$`x-env`, "from-env")
  expect_equal(headers$`x-fun`, "from-function")
  expect_equal(headers$`x-obf`, "y")
})

test_that("obfuscated() header is no longer sent as ciphertext", {
  req <- request_test("/headers") |>
    req_headers(`x-obf` = obfuscated("ZdYJeG8zwISodg0nu4UxBhs"))
  headers <- req_perform(req) |> resp_body_json() |> _$headers
  expect_equal(headers$`x-obf`, "y")
})

test_that("secrets in last_request() remain unresolved", {
  withr::local_envvar(SECRET_HEADER_TEST = "from-env")

  resp <- request_test("/get") |>
    req_headers(`x-env` = secret_envvar("SECRET_HEADER_TEST")) |>
    req_perform()
  expect_true(is_secret_envvar(resp$request$headers$`x-env`))
})

test_that("performed request doesn't serialize resolved secret headers", {
  resp <- request_test("/status/200") |>
    req_auth_bearer_token("SECRET_BEARER_TOKEN") |>
    req_perform()

  bytes <- serialize(resp, NULL)
  expect_false(any(grepl("SECRET_BEARER_TOKEN", bytes, fixed = TRUE)))
})

test_that("secret_envvar headers survive serialization", {
  path <- withr::local_tempfile()
  req <- request("http://example.com") |>
    req_headers(`x-env` = secret_envvar("SECRET_HEADER_TEST"))
  saveRDS(req, path)

  req <- readRDS(path)
  expect_true(is_secret_envvar(req$headers$`x-env`))
  withr::local_envvar(SECRET_HEADER_TEST = "abc")
  expect_equal(
    headers_flatten(req$headers, redact = FALSE),
    list(`x-env` = "abc")
  )
})

test_that("req_get_headers handles secrets", {
  withr::local_envvar(SECRET_HEADER_TEST = "abc")
  req <- request("http://example.com") |>
    req_headers(a = "x", b = secret_envvar("SECRET_HEADER_TEST"))

  expect_equal(req_get_headers(req, "drop"), list(a = "x"))
  expect_equal(
    req_get_headers(req, "redact"),
    list(a = "x", b = "<REDACTED (env: SECRET_HEADER_TEST)>")
  )
  expect_equal(req_get_headers(req, "reveal"), list(a = "x", b = "abc"))
})
