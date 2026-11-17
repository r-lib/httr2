test_that("encryption and decryption of string is symmetric", {
  key <- secret_make_key()

  x <- "Testing 1...2...3..."
  enc <- secret_encrypt(x, key)
  dec <- secret_decrypt(enc, key)
  expect_equal(dec, x)
})

test_that("encryption and decryption of object is symmetric", {
  key <- secret_make_key()
  path <- withr::local_tempfile()

  x1 <- list(1:10, letters)
  secret_write_rds(x1, path, key)
  x2 <- secret_read_rds(path, key)
  expect_equal(x1, x2)
})

test_that("encryption and decryption of file is symmetric", {
  key <- secret_make_key()
  path <- withr::local_tempfile(lines = letters)

  secret_encrypt_file(path, key)

  local({
    path_dec <<- secret_decrypt_file(path, key)
    expect_equal(readLines(path_dec, warn = FALSE), letters)
  })
  expect_false(file.exists(path_dec))
})

test_that("decrypted file is read-only", {
  skip_on_os("windows")
  key <- secret_make_key()
  path <- withr::local_tempfile(lines = letters)
  secret_encrypt_file(path, key)

  path_dec <- secret_decrypt_file(path, key)
  expect_equal(format(file.mode(path_dec)), "400")
})

test_that("can reveal obfuscated string", {
  x <- obfuscated("qw6Ua_n2LR_xzuk2uqp2dhb5OaE")
  expect_equal(secrets_resolve(x), "test")
})

test_that("obfuscated strings are hidden", {
  expect_snapshot({
    x <- obfuscated("abcdef")
    x
    str(x)
  })
})

test_that("secrets_resolve operates recursively", {
  expect_equal(secrets_resolve(NULL), NULL)
  expect_equal(secrets_resolve("x"), "x")
  expect_equal(
    secrets_resolve(list(list(obfuscated("qw6Ua_n2LR_xzuk2uqp2dhb5OaE")))),
    list(list("test"))
  )
})

test_that("secrets_resolve can control behaviour", {
  x <- list(obfuscated("JKWA-5KOJpjZcuwVYjILoayq4A"))
  expect_equal(secrets_resolve(x, "reveal"), list("abc"))
  expect_equal(secrets_resolve(x, "redact"), list("<REDACTED (obfuscated)>"))
  expect_equal(secrets_resolve(x, "remove"), list(NULL))
})

# secret_value() ------------------------------------------------------------

test_that("secret_value reveals in memory and redacts on display", {
  x <- secret_value("abc")
  expect_equal(secret_reveal(x), "abc")
  expect_snapshot({
    x
    str(x)
  })
})

test_that("secret_value checks its input", {
  expect_snapshot(error = TRUE, secret_value(1))
})

test_that("secret_value doesn't survive serialization", {
  x <- secret_value("super-secret")

  bytes <- serialize(x, NULL)
  expect_false(any(grepl("super-secret", bytes, fixed = TRUE)))

  x2 <- unserialize(bytes)
  expect_true(is_secret_dropped(x2))
  expect_snapshot(error = TRUE, secret_reveal(x2))
})

# secret_envvar() -----------------------------------------------------------

test_that("secret_envvar resolves at reveal time", {
  x <- secret_envvar("SECRET_ENVVAR_THAT_DOESNT_EXIST")
  withr::local_envvar(SECRET_ENVVAR_THAT_DOESNT_EXIST = "abc")
  expect_equal(secret_reveal(x), "abc")
})

test_that("secret_envvar errors if env var is missing", {
  local_mocked_bindings(is_testing = function() FALSE)
  expect_snapshot(error = TRUE, secret_reveal(secret_envvar("DOESNT_EXIST")))
})

test_that("secret_envvar shows the env var name on display", {
  expect_snapshot({
    x <- secret_envvar("NYTIMES_KEY")
    x
    str(x)
  })
})

test_that("secret_envvar checks its input", {
  expect_snapshot(error = TRUE, {
    secret_envvar(1)
    secret_envvar("")
  })
})

# function secrets ------------------------------------------------------------

test_that("function secrets are resolved on demand", {
  x <- secrets_resolve(\() "abc")
  expect_equal(x, "abc")
})

test_that("secrets must resolve to a single string", {
  expect_snapshot(error = TRUE, {
    secret_reveal(\() 1)
    secret_reveal(\() letters)
  })
})

test_that("function secrets redact on display", {
  expect_equal(secret_format(\() "x"), "<REDACTED (on-demand)>")
})

# secret_map() --------------------------------------------------------------

test_that("secret_map passes plain values through", {
  expect_equal(secret_map("x", toupper), "X")
})

test_that("secret_map preserves secret type", {
  withr::local_envvar(SECRET_ENVVAR_TEST = "abc")

  x <- secret_map(secret_envvar("SECRET_ENVVAR_TEST"), toupper)
  expect_true(is_secret_envvar(x))
  expect_equal(secret_reveal(x), "ABC")
  expect_equal(secret_format(x), "<REDACTED (env: SECRET_ENVVAR_TEST)>")

  x <- secret_map(secret_value("abc"), toupper)
  expect_true(is_secret_value(x))
  expect_equal(secret_reveal(x), "ABC")

  x <- secret_map(obfuscated("JKWA-5KOJpjZcuwVYjILoayq4A"), toupper)
  expect_true(is_obfuscated(x))
  expect_equal(secret_reveal(x), "ABC")

  x <- secret_map(\() "abc", toupper)
  expect_true(is.function(x))
  expect_equal(secret_reveal(x), "ABC")
})

test_that("secret_map maps compose in order", {
  x <- secret_map(\() "a", \(x) paste0(x, "b"))
  x <- secret_map(x, toupper)
  expect_equal(secret_reveal(x), "AB")
})

test_that("mapped secret_envvar survives serialization", {
  path <- withr::local_tempfile()
  x <- secret_map(secret_envvar("SECRET_ENVVAR_TEST"), toupper)
  saveRDS(x, path)

  withr::local_envvar(SECRET_ENVVAR_TEST = "abc")
  expect_equal(secret_reveal(readRDS(path)), "ABC")
})

test_that("secret_has_key returns FALSE/TRUE", {
  withr::local_envvar(ENVVAR_THAT_DOES_EXIST = "1")
  expect_equal(secret_has_key("ENVVAR_THAT_DOESNT_EXIST"), FALSE)
  expect_equal(secret_has_key("ENVVAR_THAT_DOES_EXIST"), TRUE)
})


test_that("can coerce to a key", {
  expect_equal(as_key(I("YWJj")), charToRaw("abc"))
  expect_equal(as_key(as.raw(c(1, 2, 3))), as.raw(c(1, 2, 3)))

  withr::local_envvar(KEY = "YWJj", TESTTHAT = "false")
  expect_equal(as_key("KEY"), charToRaw("abc"))

  expect_snapshot(error = TRUE, {
    as_key("ENVVAR_THAT_DOESNT_EXIST")
    as_key(1)
  })
})
