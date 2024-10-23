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
  bytes <- hex_to_raw("0000001d000000018a55bccc03666f6f050000ffffffffffff6b03c255")
  expected <- structure(1.390671161567e-309, class = "integer64")
  expect_equal(parse_aws_event(bytes)$headers, list(foo = expected))

  # byte array
  bytes <- hex_to_raw("0000001c00000001b735957c03666f6f0600050102030405cdda4038")
  expect_equal(parse_aws_event(bytes)$headers, list(foo = as.raw(1:5)))

  # character
  bytes <- hex_to_raw("0000001a00000001387560dc03666f6f0700036261725bb3cecf")
  expect_equal(parse_aws_event(bytes)$headers, list(foo = "bar"))

  # UUID
  bytes <- hex_to_raw("00000025000000011b044f8b03666f6f093bfdac5cfe6c402983bfc1de7819f5316056148a")
  expect_equal(parse_aws_event(
    bytes
  )$headers, list(foo = "3bfdac5cfe6c402983bfc1de7819f531"))

})

test_that("unknown header triggers error", {
  bytes <- hex_to_raw("0000001500000001ba25f70d03666f6fff60a63fcd")
  expect_snapshot(parse_aws_event(bytes), error = TRUE)
})

test_that("json content type automatically parsed", {
  bytes <- hex_to_raw("
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
  ")
  parsed <- parse_aws_event(bytes)
  expect_type(parsed$body, "list")
})
