test_that("must be call to curl", {
  expect_snapshot(error = TRUE, curl_args("echo foo"))
})

test_that("captures key components of call", {
  expect_equal(curl_args("curl http://x.com"), list(`<url>` = "http://x.com"))

  # Quotes are stripped
  expect_equal(curl_args("curl 'http://x.com'"), list(`<url>` = "http://x.com"))
  expect_equal(curl_args('curl "http://x.com"'), list(`<url>` = "http://x.com"))

  # Url can come before or after arguments
  expect_equal(
    curl_args("curl -H 'A: 1' 'http://example.com'"),
    curl_args("curl 'http://example.com' -H 'A: 1'")
  )
  # long name and short name are equivalent
  expect_equal(
    curl_args("curl 'http://example.com' --header 'A: 1'"),
    curl_args("curl 'http://example.com' -H 'A: 1'")
  )

  # can repeat args
  expect_equal(
    curl_args("curl 'http://example.com' -H 'A: 1' -H 'B: 2'")$`--header`,
    c("A: 1", "B: 2")
  )

  # Captures flags
  expect_equal(curl_args("curl 'http://example.com' --verbose")$`--verbose`,  TRUE)
})

test_that("can handle line breaks", {
  expect_equal(
    curl_args("curl 'http://example.com' \\\n -H 'A: 1' \\\n -H 'B: 2'")$`--header`,
    c("A: 1", "B: 2")
  )
})

test_that("headers are parsed", {
  expect_equal(
    curl_normalize("curl http://x.com -H 'A: 1'")$headers,
    as_headers("A: 1")
  )
})

test_that("user-agent and referer become headers", {
  expect_equal(
    curl_normalize("curl http://x.com -A test")$headers,
    as_headers(list("user-agent" = "test"))
  )

  expect_equal(
    curl_normalize("curl http://x.com -e test")$headers,
    as_headers(list("referer" = "test"))
  )
})

test_that("common headers can be removed", {
  sec_fetch_headers <- "-H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors'"
  sec_ch_ua_headers <- "-H 'sec-ch-ua-mobile: ?0'"
  other_headers <- "-H 'Accept: application/vnd.api+json'"
  cmd <- paste("curl http://x.com -A agent -e ref", sec_fetch_headers, sec_ch_ua_headers, other_headers)
  headers <- curl_normalize(cmd)$headers
  expect_equal(
    curl_prepare_headers(headers, simplify_headers = TRUE),
    'req_headers(
  Accept = "application/vnd.api+json",
)'
  )
  expect_equal(
    curl_prepare_headers(headers, simplify_headers = FALSE),
    'req_headers(
  `Sec-Fetch-Dest` = "empty",
  `Sec-Fetch-Mode` = "cors",
  `sec-ch-ua-mobile` = "?0",
  Accept = "application/vnd.api+json",
  referer = "ref",
  `user-agent` = "agent",
)'
  )
})

test_that("extract user name and password", {
  expect_equal(
    curl_normalize("curl http://x.com -u name:pass")$auth,
    list(username = "name", password = "pass")
  )
  expect_equal(
    curl_normalize("curl http://x.com -u name")$auth,
    list(username = "name", password = "")
  )
})

test_that("can override default method", {
  expect_equal(curl_normalize("curl http://x.com")$method, NULL)
  expect_equal(curl_normalize("curl http://x.com --get")$method, "GET")
  expect_equal(curl_normalize("curl http://x.com --head")$method, "HEAD")
  expect_equal(curl_normalize("curl http://x.com -X PUT")$method, "PUT")
})

test_that("prefers explicit url", {
  expect_equal(curl_normalize("curl 'http://x.com'")$url, "http://x.com")
  expect_equal(curl_normalize("curl --url 'http://x.com'")$url, "http://x.com")

  # prefers explicit
  expect_equal(
    curl_normalize("curl 'http://x.com' --url 'http://y.com'")$url,
    "http://y.com"
  )
})

test_that("can translate to httr calls", {
  expect_snapshot({
    curl_translate("curl http://x.com")
    curl_translate("curl http://x.com -X DELETE")
    curl_translate("curl http://x.com -H A:1")
    curl_translate("curl http://x.com -H 'A B:1'")
    curl_translate("curl http://x.com -u u:p")
    curl_translate("curl http://x.com --verbose")
  })
})

test_that("can translate data", {
  expect_snapshot({
    curl_translate("curl http://example.com --data abcdef")
    curl_translate("curl http://example.com --data abcdef -H Content-Type:text/plain")
  })
})

test_that("can evaluate simple calls", {
  request_test() # hack to start server

  resp <- curl_translate_eval(glue("curl {the$test_app$url()}/get -H A:1"))
  body <- resp_body_json(resp)
  expect_equal(body$headers$A, "1")

  resp <- curl_translate_eval(glue("curl {the$test_app$url()}/post --data A=1"))
  body <- resp_body_json(resp)
  expect_equal(body$form$A, "1")

  resp <- curl_translate_eval(glue("curl {the$test_app$url()}/delete -X delete"))
  body <- resp_body_json(resp)
  expect_equal(body$method, "delete")

  resp <- curl_translate_eval(glue("curl {the$test_app$url()}//basic-auth/u/p -u u:p"))
  body <- resp_body_json(resp)
  expect_true(body$authenticated)
})
