test_that("can parse empty object", {
  expect_equal(
    parse_aws_event(aws_event()),
    list(headers = list(), body = "")
  )
})


test_that("can return various types of header", {
  headers <- function(...) parse_aws_event(aws_event(aws_header(...)))$headers

  expect_equal(headers("foo", "false"), list(foo = FALSE))
  expect_equal(headers("foo", "true"), list(foo = TRUE))
  expect_equal(headers("foo", "bytes", as.raw(1:5)), list(foo = as.raw(1:5)))
  expect_equal(headers("foo", "string", "bar"), list(foo = "bar"))

  # byte, short, and integer are signed (two's complement)
  expect_equal(headers("foo", "byte", 127), list(foo = 127))
  expect_equal(headers("foo", "byte", -1), list(foo = -1))
  expect_equal(headers("foo", "short", -2), list(foo = -2))
  expect_equal(headers("foo", "integer", -3), list(foo = -3))

  # long and timestamp are 64-bit integers, returned as bit64::integer64 (see
  # the reference test below for a non-trivial long value)
  expect_equal(
    headers("foo", "timestamp", 0),
    list(foo = structure(0, class = "integer64"))
  )

  # UUID is returned as a hex string
  uuid <- as.raw(1:16)
  expect_equal(headers("foo", "uuid", uuid), list(foo = raw_to_hex(uuid)))
})


test_that("unknown header triggers error", {
  expect_snapshot(
    parse_aws_event(aws_event(aws_header("foo", "unknown"))),
    error = TRUE
  )
})

test_that("parse_aws_event() checks the prelude length", {
  expect_snapshot(parse_aws_event(as.raw(1:10)), error = TRUE)
})

test_that("can read aws events one at a time", {
  # Two empty-object events back to back.
  event <- aws_event()
  req <- local_app_request(function(req, res) {
    res$send_chunk(event)
    res$send_chunk(event)
  })
  resp <- req_perform_connection(req, blocking = TRUE)
  withr::defer(close(resp))

  expect_equal(resp_stream_aws(resp), list(headers = list(), body = ""))
  expect_equal(resp_stream_aws(resp), list(headers = list(), body = ""))
  expect_equal(resp_stream_aws(resp), NULL)
})

test_that("verbosity = 3 shows aws events", {
  # A single event with a "foo: bar" header and empty body.
  event <- aws_event(aws_header("foo", "string", "bar"))
  req <- local_app_request(function(req, res) {
    res$send_chunk(event)
  })

  expect_output(resp <- req_perform_connection(req, verbosity = 3))
  withr::defer(close(resp))
  expect_snapshot(
    . <- resp_stream_aws(resp),
    transform = transform_verbose_response
  )
})

test_that("find_aws_event_boundaries splits a buffer into complete events", {
  event <- aws_event()

  expect_equal(find_aws_event_boundaries(event), 17)
  expect_equal(find_aws_event_boundaries(c(event, event)), c(17, 33))
  expect_equal(
    find_aws_event_boundaries(c(event, event, event)),
    c(17, 33, 49)
  )
})

test_that("find_aws_event_boundaries ignores incomplete trailing events", {
  event <- aws_event()

  # Nothing to split
  expect_equal(find_aws_event_boundaries(raw()), double())
  # Fewer than 16 bytes can't be a complete event
  expect_equal(find_aws_event_boundaries(event[1:10]), double())
  # Trailing partial event is excluded
  expect_equal(find_aws_event_boundaries(c(event, event[1:8])), 17)
  # Event claiming more bytes than are available is excluded
  big <- event
  big[1:4] <- aws_uint(256, 4L)
  expect_equal(find_aws_event_boundaries(c(event, big)), 17)
})

test_that("json content type automatically parsed", {
  event <- aws_event(
    c(
      aws_header(":event-type", "string", "SubscribeToShardEvent"),
      aws_header(":content-type", "string", "application/json"),
      aws_header(":message-type", "string", "event")
    ),
    body = charToRaw('{"records": []}')
  )
  parsed <- parse_aws_event(event)
  expect_equal(parsed$body, list(records = list()))
})

# aws_event() ------------------------------------------------------------------

test_that("aws_event() produces spec-valid bytes, including CRCs", {
  # Using values from a reference implementation at
  # https://github.com/lifion/lifion-aws-event-stream
  expect_equal(aws_event(), hex_to_raw("000000100000000005c248eb7d98c8ff"))
})

test_that("aws_event() agrees with the reference implementation", {
  # Messages captured from the lifion JS reference implementation:
  # https://github.com/lifion/lifion-aws-event-stream. These vectors encode a
  # non-spec header length (always 1), so their bytes differ from aws_event()'s,
  # but a reference message and the equivalent aws_event() must decode the same.
  agrees <- function(reference, header) {
    expect_equal(
      parse_aws_event(hex_to_raw(reference)),
      parse_aws_event(aws_event(header))
    )
  }

  agrees(
    "0000001500000001ba25f70d03666f6f013aa3e0d6",
    aws_header("foo", "false")
  )
  agrees(
    "0000001500000001ba25f70d03666f6f004da4d040",
    aws_header("foo", "true")
  )
  agrees(
    "0000001600000001fd858ddd03666f6f02ffa44bfd93",
    aws_header("foo", "byte", -1) # 0xff
  )
  agrees(
    "0000001700000001c0e5a46d03666f6f03fffff3b59291",
    aws_header("foo", "short", -1) # 0xffff
  )
  agrees(
    "00000019000000017fd51a0c03666f6f04ffffffff853b65dd",
    aws_header("foo", "integer", -1) # 0xffffffff
  )
  agrees(
    "0000001d000000018a55bccc03666f6f050000ffffffffffff6b03c255",
    aws_header("foo", "long", 281474976710655) # 0x0000ffffffffffff
  )
  agrees(
    "0000001a00000001387560dc03666f6f0700036261725bb3cecf",
    aws_header("foo", "string", "bar")
  )
  agrees(
    "0000001c00000001b735957c03666f6f0600050102030405cdda4038",
    aws_header("foo", "bytes", as.raw(1:5))
  )
  agrees(
    "00000025000000011b044f8b03666f6f093bfdac5cfe6c402983bfc1de7819f5316056148a",
    aws_header("foo", "uuid", hex_to_raw("3bfdac5cfe6c402983bfc1de7819f531"))
  )
})
