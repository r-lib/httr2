test_that("desktop style can't run in hosted environment", {
  client <- oauth_client("abc", "http://example.com")

  withr::local_options(rlang_interactive = TRUE)
  withr::local_envvar("RSTUDIO_PROGRAM_MODE" = "server")
  expect_snapshot(
    oauth_flow_auth_code(client, "http://localhost"),
    error = TRUE
  )
})

test_that("so-called 'hosted' sessions are detected correctly", {
  withr::with_envvar(c("RSTUDIO_PROGRAM_MODE" = "server"), {
    expect_true(is_hosted_session())
  })
  # Emulate running outside RStudio Server if we happen to be running our tests
  # under it.
  withr::with_envvar(c("RSTUDIO_PROGRAM_MODE" = NA), {
    expect_false(is_hosted_session())
  })
})

test_that("URL embedding authorisation code and state can be input manually", {
  local_mocked_bindings(
    readline = function(prompt = "") "https://x.com?code=code&state=state"
  )
  expect_equal(oauth_flow_auth_code_read("state"), "code")
  expect_error(oauth_flow_auth_code_read("invalid"), "state does not match")
})

test_that("JSON-encoded authorisation codes can be input manually", {
  input <- list(state = "state", code = "code")
  encoded <- openssl::base64_encode(jsonlite::toJSON(input))
  local_mocked_bindings(
    readline = function(prompt = "") encoded
  )
  expect_equal(oauth_flow_auth_code_read("state"), "code")
  expect_error(oauth_flow_auth_code_read("invalid"), "state does not match")
})

test_that("bare authorisation codes can be input manually", {
  state <- base64_url_rand(32)
  sent_code <- FALSE
  local_mocked_bindings(
    readline = function(prompt = "") {
      if (sent_code) {
        state
      } else {
        sent_code <<- TRUE
        "zyx987"
      }
    }
  )
  expect_equal(oauth_flow_auth_code_read(state), "zyx987")
  expect_error(oauth_flow_auth_code_read("invalid"), "state does not match")
})

# normalize_redirect_uri --------------------------------------------------

test_that("adds port to localhost url", {
  # Allow tests to run when is_hosted_session() is TRUE.
  local_mocked_bindings(is_hosted_session = function() FALSE)

  redirect <- normalize_redirect_uri("http://localhost")
  expect_false(is.null(url_parse(redirect$uri)$port))

  redirect <- normalize_redirect_uri("http://127.0.0.1")
  expect_false(is.null(url_parse(redirect$uri)$port))
})

test_that("old args are deprecated", {
  # Allow tests to run when is_hosted_session() is TRUE.
  local_mocked_bindings(is_hosted_session = function() FALSE)

  expect_snapshot(
    redirect <- normalize_redirect_uri("http://localhost", port = 1234)
  )
  expect_equal(redirect$uri, "http://localhost:1234")

  expect_snapshot(
    redirect <- normalize_redirect_uri("http://x.com", host_name = "y.com")
  )
  expect_equal(redirect$uri, "http://y.com")

  expect_snapshot(
    redirect <- normalize_redirect_uri("http://x.com", host_ip = "y.com")
  )

})

# ouath_flow_auth_code_parse ----------------------------------------------

test_that("forwards oauth error", {
  query1 <- query2 <- list(error = "123", error_description = "A bad error")
  query2$error_uri <- "http://example.com"
  query3 <- list(state = "def")

  expect_snapshot(error = TRUE, {
    oauth_flow_auth_code_parse(query1, "abc")
    oauth_flow_auth_code_parse(query2, "abc")
    oauth_flow_auth_code_parse(query3, "abc")
  })
})

# can_fetch_auth_code -----------------------------------------------------

test_that("external auth code sources are detected correctly", {
  # False by default.
  expect_false(can_fetch_oauth_code("http://localhost:8080/redirect"))

  # Only true in the presence of certain environment variables.
  env <- c(
    "HTTR2_OAUTH_CODE_SOURCE_URL" = "http://localhost:8080/code",
    "HTTR2_OAUTH_REDIRECT_URL" = "http://localhost:8080/redirect"
  )
  withr::with_envvar(env, {
    expect_true(can_fetch_oauth_code("http://localhost:8080/redirect"))

    # Non-matching redirect URLs should not count as external sources, either.
    expect_false(can_fetch_oauth_code("http://localhost:9090/redirect"))
  })
})

# oauth_flow_auth_code_fetch ----------------------------------------------

test_that("auth codes can be retrieved from an external source", {
  skip_on_cran()
  skip_on_covr()

  app <- webfakes::new_app()
  authorized <- FALSE

  # Error on first, and then respond on second
  app$get("/code", function(req, res) {
    if (!authorized) {
      authorized <<- TRUE
      res$
        set_status(404L)$
        set_type("text/plain")$
        send("Not found")
    } else {
      res$
        set_status(200L)$
        send_json(text = '{"code":"abc123"}')
    }
  })
  server <- webfakes::local_app_process(app)

  withr::local_envvar("HTTR2_OAUTH_CODE_SOURCE_URL" = server$url("/code"))
  expect_equal(oauth_flow_auth_code_fetch("ignored"), "abc123")
})
