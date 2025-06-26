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

test_that("can unobfuscate obfuscated string", {
  x <- obfuscated("qw6Ua_n2LR_xzuk2uqp2dhb5OaE")
  expect_equal(unobfuscate(x), "test")
})

test_that("obfuscated strings are hidden", {
  expect_snapshot({
    x <- obfuscated("abcdef")
    x
    str(x)
  })
})

test_that("unobfuscate operates recursively", {
  expect_equal(unobfuscate(NULL), NULL)
  expect_equal(unobfuscate("x"), "x")
  expect_equal(
    unobfuscate(list(list(obfuscated("qw6Ua_n2LR_xzuk2uqp2dhb5OaE")))),
    list(list("test"))
  )
})

test_that("unobfuscated can control behaviour", {
  x <- list(obfuscated("JKWA-5KOJpjZcuwVYjILoayq4A"))
  expect_equal(unobfuscate(x, "reveal"), list("abc"))
  expect_equal(unobfuscate(x, "redact"), list("<REDACTED>"))
  expect_equal(unobfuscate(x, "remove"), list(NULL))
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
