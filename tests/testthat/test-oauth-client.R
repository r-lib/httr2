test_that("can check app has needed pieces", {
  client <- oauth_client("id", token_url = "http://example.com")
  expect_snapshot(error = TRUE, {
    oauth_flow_check("test", client, is_confidential = TRUE)
    oauth_flow_check("test", client, interactive = TRUE)
  })
})

test_that("client has useful print method", {
  expect_snapshot({
    oauth_client("x", token_url = "http://example.com")
    oauth_client("x", secret = "SECRET", token_url = "http://example.com")
  })
})

test_that("picks default auth", {
  expect_equal(
    oauth_client("x", "url", key = NULL)$auth,
    "oauth_client_req_auth_body")
  expect_equal(
    oauth_client("x", "url", key = "key", auth_params = list(claim = list()))$auth,
    "oauth_client_req_auth_jwt_sig"
  )
})


test_that("can authenticate using header or body", {
  client <- function(auth) {
    oauth_client(
      id = "id",
      secret = "secret",
      token_url = "http://example.com",
      auth = auth
    )
  }

  req <- request("http://example.com")
  req_h <- oauth_client_req_auth(req, client("header"))
  expect_equal(req_h$headers, structure(list(Authorization = "Basic aWQ6c2VjcmV0"), redact = "Authorization"))

  req_b <- oauth_client_req_auth(req, client("body"))
  expect_equal(req_b$body$data, list(client_id = "id", client_secret = "secret"))
})


test_that("can authenticate with client certificate", {
  if (FALSE) {
    ## To create a certificate:
    # openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 3650
    # pem phrase - abcd
    # email address: h.wickham@gmail.com

    ## Upload to https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationsListBlade

    cert <- openssl::read_cert("cert.pem")
    secret_write_rds(cert, test_path("azure-cert.rds"), "HTTR2_KEY")
    key <- openssl::read_key("key.pem")
    secret_write_rds(key, test_path("azure-key.rds"), "HTTR2_KEY")

    unlink(c("cert.pem", "key.pem"))
  }

  client_id <- "b7f5efee-1367-4302-a89a-048af3ba821a"
  cert <- secret_read_rds(test_path("azure-cert.rds"), "HTTR2_KEY")
  cert_x5t <- base64_url_encode(openssl::sha1(cert))
  key <- secret_read_rds(test_path("azure-key.rds"), "HTTR2_KEY")

  claim <- list(
    aud = "https://login.microsoftonline.com/common/v2.0",
    iss = client_id,
    sub = client_id
  )
  client <- oauth_client(
    id = client_id,
    key = key,
    token_url = "https://login.microsoftonline.com/common/oauth2/v2.0/token",
    name = "azure",
    auth_params = list(claim = claim, header = list(x5t = cert_x5t))
  )
  token <- oauth_flow_client_credentials(
    client = client,
    scope = "https://management.azure.com/.default"
  )
  expect_s3_class(token, "httr2_token")
})
