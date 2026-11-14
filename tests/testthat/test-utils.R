test_that("modify list adds, removes, and overrides", {
  x <- list(x = 1)
  expect_equal(modify_list(x), x)
  expect_equal(modify_list(x, x = NULL), list())
  expect_equal(modify_list(x, x = 2), list(x = 2))
  expect_equal(modify_list(x, y = 3), list(x = 1, y = 3))
  expect_equal(modify_list(NULL, x = 2), list(x = 2))

  expect_snapshot(modify_list(x, a = 1, 2), error = TRUE)
})

test_that("replacement affects all components with name", {
  x <- list(a = 1, a = 2)
  expect_equal(modify_list(x, a = NULL), list())
  expect_equal(modify_list(x, a = 3), list(a = 3))
  expect_equal(modify_list(x, a = 3, a = 4), list(a = 3, a = 4))
})

test_that("progress bar suppressed in tests", {
  expect_snapshot(sys_sleep(0.1, "in test"))
})


test_that("dir_create_private() creates directory only accessible to user", {
  path <- file.path(withr::local_tempdir(), "a", "b")
  dir_create_private(path)
  expect_true(dir.exists(path))

  # On Windows Sys.chmod() only affects the read-only attribute
  skip_on_os("windows")
  expect_equal(file.mode(path), as.octmode("700"))
})

test_that("dir_create_private() only changes existing directory if forced", {
  # On Windows Sys.chmod() only affects the read-only attribute
  skip_on_os("windows")
  path <- withr::local_tempdir()
  Sys.chmod(path, "0755")

  dir_create_private(path)
  expect_equal(file.mode(path), as.octmode("755"))

  dir_create_private(path, force = TRUE)
  expect_equal(file.mode(path), as.octmode("700"))
})

test_that("file_write_private() replaces file with one only readable by user", {
  dir <- withr::local_tempdir()
  path <- file.path(dir, "x")
  writeLines("old", path)
  Sys.chmod(path, "0644")

  file_write_private(path, \(tmp) writeLines("new", tmp))
  expect_equal(readLines(path), "new")
  expect_equal(dir(dir, all.files = TRUE, no.. = TRUE), "x")

  skip_on_os("windows")
  expect_equal(file.mode(path), as.octmode("600"))
})

test_that("file_write_private() leaves existing file untouched on failure", {
  dir <- withr::local_tempdir()
  path <- file.path(dir, "x")
  writeLines("old", path)

  expect_error(file_write_private(path, \(tmp) stop("!")), "!")
  expect_equal(readLines(path), "old")
  expect_equal(dir(dir, all.files = TRUE, no.. = TRUE), "x")
})

test_that("has a working slice", {
  x <- letters[1:5]
  expect_identical(slice(x), x)
  expect_identical(slice(x, 1, length(x) + 1), x)

  # start is inclusive, end is exclusive
  expect_identical(slice(x, 1, length(x)), head(x, -1))
  # zero-length slices are fine
  expect_identical(slice(x, 1, 1), character())
  # starting off the end is fine
  expect_identical(slice(x, length(x) + 1), character())
  expect_identical(slice(x, length(x) + 1, length(x) + 1), character())
  # slicing zero-length is fine
  expect_identical(slice(character()), character())

  # out of bounds
  expect_error(slice(x, 0, 1))
  expect_error(slice(x, length(x) + 2))
  expect_error(slice(x, end = length(x) + 2))
  # end too small relative to start
  expect_error(slice(x, 2, 1))
})
