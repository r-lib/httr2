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

test_that("JSON-encoded authorisation codes can be input manually", {
  state <- base64_url_rand(32)
  input <- list(state = state, code = "abc123")
  encoded <- openssl::base64_encode(jsonlite::toJSON(input))
  local_mocked_bindings(
    readline = function(prompt = "") encoded
  )
  expect_equal(oauth_flow_auth_code_read(state), "abc123")
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
