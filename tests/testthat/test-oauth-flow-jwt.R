# 1. Create service account
# 2. Add key and download json
# 3. json <- jsonlite::read_json(path)
# 4. secret_write_rds(json, "tests/testthat/test-oauth-flow-jwt-google.rds",
#      secret_get_key("HTTR2_KEY"))

test_that("can generate token and use it automatically", {
  secrets <- secret_read_rds(test_path("test-oauth-flow-jwt-google.rds"), "HTTR2_KEY")

  app <- oauth_app(
    client = oauth_client(secrets$client_id),
    endpoints = c(token = secrets$token_uri)
  )
  claims <- list2(
    iss = secrets$client_email,
    scope = "https://www.googleapis.com/auth/userinfo.email",
    aud = "https://oauth2.googleapis.com/token"
  )

  # Can generate token
  token <- oauth_flow_jwt(app, claims, "jwt_sign_rs256", list(private_key = secrets$private_key))
  expect_s3_class(token, "httr2_token")

  # Can use it in request
  resp <- request("https://openidconnect.googleapis.com/v1/userinfo") %>%
    req_oauth_jwt(app, claims, "jwt_sign_rs256", list(private_key = secrets$private_key)) %>%
    req_fetch() %>%
    resp_body_json()

  expect_type(resp, "list")
  expect_equal(resp$email_verified, TRUE)
})
