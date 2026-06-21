test_that("fetches and parses metadata", {
  local_mocked_responses(list(response_json(
    body = list(
      issuer = "https://example.com",
      authorization_endpoint = "https://example.com/authorize",
      token_endpoint = "https://example.com/token",
      scopes_supported = c("openid", "email")
    )
  )))

  meta <- oauth_server_metadata("https://example.com")
  expect_s3_class(meta, "httr2_oauth_server_metadata")
  expect_equal(meta$token_endpoint, "https://example.com/token")
  # unadvertised endpoints are absent
  expect_null(meta$device_authorization_endpoint)
  # string arrays are simplified to character vectors, not lists
  expect_equal(meta$scopes_supported, c("openid", "email"))
})

test_that("builds well-known metadata URLs", {
  expect_equal(
    oauth_metadata_url("https://example.com", "openid"),
    "https://example.com/.well-known/openid-configuration"
  )
  expect_equal(
    oauth_metadata_url("https://example.com/", "openid"),
    "https://example.com/.well-known/openid-configuration"
  )
  expect_equal(
    oauth_metadata_url("https://example.com", "oauth"),
    "https://example.com/.well-known/oauth-authorization-server"
  )
})

test_that("multi-tenant issuers place the suffix differently", {
  expect_equal(
    oauth_metadata_url("https://example.com/tenant1", "openid"),
    "https://example.com/tenant1/.well-known/openid-configuration"
  )
  expect_equal(
    oauth_metadata_url("https://example.com/tenant1", "oauth"),
    "https://example.com/.well-known/oauth-authorization-server/tenant1"
  )
})

test_that("validates issuer against the returned document", {
  local_mocked_responses(list(response_json(
    body = list(
      issuer = "https://evil.com",
      token_endpoint = "https://evil.com/token"
    )
  )))

  expect_snapshot(oauth_server_metadata("https://example.com"), error = TRUE)
})

test_that("url override skips issuer validation when issuer is omitted", {
  local_mocked_responses(list(response_json(
    body = list(
      issuer = "https://example.com",
      token_endpoint = "https://example.com/token"
    )
  )))

  meta <- oauth_server_metadata(url = "https://example.com/metadata")
  expect_equal(meta$token_endpoint, "https://example.com/token")
})

test_that("requires either issuer or url", {
  expect_snapshot(oauth_server_metadata(), error = TRUE)
})

test_that("has a useful print method", {
  meta <- structure(
    list(
      issuer = "https://example.com",
      authorization_endpoint = "https://example.com/authorize",
      token_endpoint = "https://example.com/token",
      response_types_supported = c("code", "token"),
      scopes_supported = c("openid", "email"),
      authorization_response_iss_parameter_supported = TRUE
    ),
    class = "httr2_oauth_server_metadata"
  )
  expect_snapshot(meta)
})
