# Tests copied from
# https://github.com/lifion/lifion-aws-event-stream/blob/develop/lib/index.test.js
# https://github.com/lifion/lifion-aws-event-stream/blob/develop/lib/index.test.json

test_that("can parse empty object", {
  bytes <- hex_to_raw("000000100000000005c248eb7d98c8ff")
  expect_equal(
    parse_aws_event(bytes),
    list(headers = list(), body = "")
  )
})

test_that("can return various types of header", {
  bytes <- hex_to_raw("0000001500000001ba25f70d03666f6f013aa3e0d6")
  expect_equal(parse_aws_event(bytes)$headers, list(foo = FALSE))

  bytes <- hex_to_raw("0000001500000001ba25f70d03666f6f004da4d040")
  expect_equal(parse_aws_event(bytes)$headers, list(foo = TRUE))

  # byte
  bytes <- hex_to_raw("0000001600000001fd858ddd03666f6f02ffa44bfd93")
  expect_equal(parse_aws_event(bytes)$headers, list(foo = 255))

  # short
  bytes <- hex_to_raw("0000001700000001c0e5a46d03666f6f03fffff3b59291")
  expect_equal(parse_aws_event(bytes)$headers, list(foo = 65535))

  # integer
  bytes <- hex_to_raw("00000019000000017fd51a0c03666f6f04ffffffff853b65dd")
  expect_equal(parse_aws_event(bytes)$headers, list(foo = 4294967295))

  # long
  bytes <- hex_to_raw(
    "0000001d000000018a55bccc03666f6f050000ffffffffffff6b03c255"
  )
  expected <- structure(1.390671161567e-309, class = "integer64")
  expect_equal(parse_aws_event(bytes)$headers, list(foo = expected))

  # byte array
  bytes <- hex_to_raw(
    "0000001c00000001b735957c03666f6f0600050102030405cdda4038"
  )
  expect_equal(parse_aws_event(bytes)$headers, list(foo = as.raw(1:5)))

  # timestamp (hand-built: prelude + "foo" name + type 8 + 8-byte value; the
  # CRCs aren't validated, only the prelude length is)
  bytes <- hex_to_raw(
    "0000001d0000000d0000000003666f6f08000000000000000000000000"
  )
  expect_equal(
    parse_aws_event(bytes)$headers,
    list(foo = structure(0, class = "integer64"))
  )

  # character
  bytes <- hex_to_raw("0000001a00000001387560dc03666f6f0700036261725bb3cecf")
  expect_equal(parse_aws_event(bytes)$headers, list(foo = "bar"))

  # UUID
  bytes <- hex_to_raw(
    "00000025000000011b044f8b03666f6f093bfdac5cfe6c402983bfc1de7819f5316056148a"
  )
  expect_equal(
    parse_aws_event(
      bytes
    )$headers,
    list(foo = "3bfdac5cfe6c402983bfc1de7819f531")
  )
})

test_that("unknown header triggers error", {
  bytes <- hex_to_raw("0000001500000001ba25f70d03666f6fff60a63fcd")
  expect_snapshot(parse_aws_event(bytes), error = TRUE)
})

test_that("parse_aws_event() checks the prelude length", {
  expect_snapshot(parse_aws_event(as.raw(1:10)), error = TRUE)
})

test_that("can read aws events one at a time", {
  # Two empty-object events back to back (16 bytes each).
  req <- local_app_request(function(req, res) {
    event <- as.raw(c(
      0x00,
      0x00,
      0x00,
      0x10,
      0x00,
      0x00,
      0x00,
      0x00,
      0x05,
      0xc2,
      0x48,
      0xeb,
      0x7d,
      0x98,
      0xc8,
      0xff
    ))
    res$send_chunk(event)
    res$send_chunk(event)
  })
  resp <- req_perform_connection(req, blocking = TRUE)
  withr::defer(close(resp))

  expect_equal(resp_stream_aws(resp), list(headers = list(), body = ""))
  # The second event is decoded in the same read and queued.
  expect_false(resp_stream_is_complete(resp))
  expect_equal(resp_stream_aws(resp), list(headers = list(), body = ""))
  expect_equal(resp_stream_aws(resp), NULL)
  expect_true(resp_stream_is_complete(resp))
})

test_that("verbosity = 3 shows aws events", {
  # A single event with a "foo: bar" header and empty body.
  req <- local_app_request(function(req, res) {
    res$send_chunk(as.raw(c(
      0x00,
      0x00,
      0x00,
      0x1a,
      0x00,
      0x00,
      0x00,
      0x01,
      0x38,
      0x75,
      0x60,
      0xdc,
      0x03,
      0x66,
      0x6f,
      0x6f,
      0x07,
      0x00,
      0x03,
      0x62,
      0x61,
      0x72,
      0x5b,
      0xb3,
      0xce,
      0xcf
    )))
  })

  expect_output(resp <- req_perform_connection(req, verbosity = 3))
  withr::defer(close(resp))
  expect_snapshot(
    . <- resp_stream_aws(resp),
    transform = transform_verbose_response
  )
})

test_that("find_aws_event_boundaries splits a buffer into complete events", {
  event <- hex_to_raw("000000100000000005c248eb7d98c8ff")

  expect_equal(find_aws_event_boundaries(event), 17)
  expect_equal(find_aws_event_boundaries(c(event, event)), c(17, 33))
  expect_equal(
    find_aws_event_boundaries(c(event, event, event)),
    c(17, 33, 49)
  )
})

test_that("find_aws_event_boundaries ignores incomplete trailing events", {
  event <- hex_to_raw("000000100000000005c248eb7d98c8ff")

  # Nothing to split
  expect_equal(find_aws_event_boundaries(raw()), double())
  # Fewer than 16 bytes can't be a complete event
  expect_equal(find_aws_event_boundaries(event[1:10]), double())
  # Trailing partial event is excluded
  expect_equal(find_aws_event_boundaries(c(event, event[1:8])), 17)
  # Event claiming more bytes than are available is excluded
  big <- event
  big[1:4] <- hex_to_raw("00000100")
  expect_equal(find_aws_event_boundaries(c(event, big)), 17)
})

test_that("json content type automatically parsed", {
  bytes <- hex_to_raw(
    "
    000001c20000005bc1123f0b0b3a6576656e742d74797065070015537562736372696265546f
    53686172644576656e740d3a636f6e74656e742d747970650700106170706c69636174696f6e
    2f6a736f6e0d3a6d6573736167652d747970650700056576656e747b22436f6e74696e756174
    696f6e53657175656e63654e756d626572223a22343935383836333037393634323435313235
    3936363136333437353239313133373435393934373336323937343734373039373832353330
    222c224d696c6c6973426568696e644c6174657374223a302c225265636f726473223a5b7b22
    417070726f78696d6174654172726976616c54696d657374616d70223a312e35333831363032
    313936333645392c2244617461223a225632567a62475635222c22456e6372797074696f6e54
    797065223a6e756c6c2c22506172746974696f6e4b6579223a2231306463633930322d633839
    632d343036372d623433362d303566383863306662356566222c2253657175656e63654e756d
    626572223a223439353838363330373936343234353132353936363136333437353239313133
    373435393934373336323937343734373039373832353330227d5d7dd84c02f3
  "
  )
  parsed <- parse_aws_event(bytes)
  expect_type(parsed$body, "list")
})
