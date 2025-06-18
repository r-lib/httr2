# 1. Create service account
# 2. Add key and download json
# 3. json <- jsonlite::read_json(path)
# 4. secret_write_rds(json, "tests/testthat/test-oauth-flow-jwt-google.rds", "HTTR2_KEY")

test_that("can generate token and use it automatically", {
  secrets <- secret_read_rds(
    test_path("test-oauth-flow-jwt-google.rds"),
    "HTTR2_KEY"
  )

  client <- oauth_client(
    id = secrets$client_id,
    key = secrets$private_key,
    token_url = secrets$token_uri,
    auth = "body"
  )
  claim <- list(
    iss = secrets$client_email,
    scope = "https://www.googleapis.com/auth/userinfo.email",
    aud = "https://oauth2.googleapis.com/token"
  )

  # Can generate token
  token <- oauth_flow_bearer_jwt(client, claim)
  expect_s3_class(token, "httr2_token")

  # Can use it in request
  resp <- request("https://openidconnect.googleapis.com/v1/userinfo") |>
    req_oauth_bearer_jwt(client, claim) |>
    req_perform() |>
    resp_body_json()

  expect_type(resp, "list")
  expect_equal(resp$email_verified, TRUE)
})

test_that("validates inputs", {
  client1 <- oauth_client("test", "http://example.com")
  expect_snapshot(oauth_flow_bearer_jwt(client1), error = TRUE)

  client2 <- oauth_client(
    "test",
    "http://example.com",
    key = "abc",
    auth_params = list(claim = "123")
  )
  expect_snapshot(oauth_flow_bearer_jwt(client2, claim = NULL), error = TRUE)
})
