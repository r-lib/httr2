test_that("can set path", {
  req <- req("http://test.com") %>% req_template("/x")
  expect_equal(req$url, "http://test.com/x")
})

test_that("can set method and path", {
  req <- req("http://test.com") %>% req_template("PATCH /x")
  expect_equal(req$url, "http://test.com/x")
  expect_equal(req$method, "PATCH")
})

test_that("can use args or env", {
  x <- "x"
  req <- req("http://test.com") %>% req_template("/:x")
  expect_equal(req$url, "http://test.com/x")

  req <- req("http://test.com") %>% req_template("/:x", x = "y")
  expect_equal(req$url, "http://test.com/y")
})

test_that("generates useful errors", {
  req <- req("http://test.com")

  expect_snapshot(error = TRUE, {
    req_template(req, 1)
    req_template(req, "x", 1)
    req_template(req, "A B C")
  })
})

# templating --------------------------------------------------------------

test_that("template_process looks in args & env", {
  a <- 1
  expect_equal(template_process(":a"), "1")
  expect_equal(template_process(":a", list(a = 2)), "2")
})

test_that("template produces useful errors", {
  expect_snapshot(error = TRUE, {
    template_process(":b")
    template_process(":b", list(b = sum))
  })
})

test_that("supports three template styles", {
  x <- "x"
  expect_equal(template_process("/:x/"), "/x/")
  expect_equal(template_process("/{x}/"), "/x/")
  expect_equal(template_process("/constant"), "/constant")
})
