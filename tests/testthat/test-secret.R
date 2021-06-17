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


test_that("can unobfuscate obfuscated string", {
  expect_snapshot({
    obfuscate("test")
    obfuscated("ZlWk7g")
  })

  x <- obfuscated("ZlWk7g")
  expect_equal(unobfuscate(x), "test")
})

test_that("unobfuscate serves as argument checker", {
  expect_equal(unobfuscate(NULL), NULL)
  expect_equal(unobfuscate("x"), "x")
  expect_snapshot(unobfuscate(1, "`x`"), error = TRUE)
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
