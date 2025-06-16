test_that("RingBuffer initializes correctly", {
  # Test with default capacity
  rb <- RingBuffer$new()
  expect_equal(rb$size(), 0)
  expect_true(rb$is_empty())

  # Test with custom capacity
  rb <- RingBuffer$new(32)
  expect_equal(rb$capacity(), 32)
})

test_that("push and pop operations work correctly", {
  rb <- RingBuffer$new(10)

  # Push single byte
  rb$push(as.raw(0x01))
  expect_equal(rb$size(), 1)
  expect_false(rb$is_empty())

  # Pop single byte
  data <- rb$pop()
  expect_equal(data, as.raw(0x01))
  expect_equal(rb$size(), 0)
  expect_true(rb$is_empty())
})

test_that("pushing multiple bytes works correctly", {
  rb <- RingBuffer$new(10)

  # Push multiple bytes
  test_data <- as.raw(c(0x01, 0x02, 0x03, 0x04, 0x05))
  rb$push(test_data)
  expect_equal(rb$size(), 5)

  # Pop and verify
  result <- rb$pop(5)
  expect_equal(result, test_data)
  expect_true(rb$is_empty())
})

test_that("popping from empty buffer returns empty raw vector", {
  rb <- RingBuffer$new(10)

  # Pop from empty buffer
  result <- rb$pop()
  expect_equal(result, raw(0))

  # Pop multiple from empty buffer
  result <- rb$pop(5)
  expect_equal(result, raw(0))
})

test_that("pop respects available bytes", {
  rb <- RingBuffer$new(10)

  # Add 3 bytes
  rb$push(as.raw(c(0x01, 0x02, 0x03)))

  # Try to pop 5 bytes (should only get 3)
  result <- rb$pop(5)
  expect_equal(result, as.raw(c(0x01, 0x02, 0x03)))
  expect_equal(rb$size(), 0)
})

test_that("buffer wraps around correctly", {
  rb <- RingBuffer$new(5)

  # Fill buffer
  rb$push(as.raw(c(0x01, 0x02, 0x03)))

  # Pop one byte
  rb$pop()

  # Push more to force wrap
  rb$push(as.raw(c(0x04, 0x05, 0x06)))

  # Pop all and verify correct order
  result <- rb$pop(5)
  expect_equal(result, as.raw(c(0x02, 0x03, 0x04, 0x05, 0x06)))
})

test_that("buffer grows automatically", {
  rb <- RingBuffer$new(4)

  # Initial capacity
  expect_equal(rb$capacity(), 4)

  # Push data that fills buffer
  rb$push(as.raw(c(0x01, 0x02, 0x03, 0x04)))

  # Verify full but not grown
  expect_equal(rb$capacity(), 4)
  expect_equal(rb$size(), 4)

  # Push one more byte to force growth
  rb$push(as.raw(0x05))

  # Verify growth
  expect_equal(rb$capacity(), 8) # Should double
  expect_equal(rb$size(), 5)

  # Verify data integrity
  result <- rb$pop(5)
  expect_equal(result, as.raw(c(0x01, 0x02, 0x03, 0x04, 0x05)))
})

test_that("buffer grows to required size", {
  rb <- RingBuffer$new(4)

  # Push large chunk at once
  large_data <- as.raw(1:10)
  rb$push(large_data)

  # Verify grew enough to accommodate data
  expect_true(rb$capacity() >= 10)
  expect_equal(rb$size(), 10)

  # Verify data integrity
  result <- rb$pop(10)
  expect_equal(result, large_data)
})

test_that("wrapping with partial reads and writes works", {
  rb <- RingBuffer$new(6)

  # Fill buffer partially
  rb$push(as.raw(c(0x01, 0x02, 0x03, 0x04)))

  # Read part
  data1 <- rb$pop(2)
  expect_equal(data1, as.raw(c(0x01, 0x02)))

  # Add more to force wrap
  rb$push(as.raw(c(0x05, 0x06, 0x07, 0x08)))

  # Read across wrap boundary
  data2 <- rb$pop(4)
  expect_equal(data2, as.raw(c(0x03, 0x04, 0x05, 0x06)))

  # Read remaining
  data3 <- rb$pop(2)
  expect_equal(data3, as.raw(c(0x07, 0x08)))
})

test_that("push returns invisibly for method chaining", {
  rb <- RingBuffer$new(10)

  # Method chaining
  rb$push(as.raw(0x01))$push(as.raw(0x02))

  expect_equal(rb$size(), 2)
  expect_equal(rb$pop(2), as.raw(c(0x01, 0x02)))
})

test_that("extreme growth works", {
  # Start with tiny buffer
  rb <- RingBuffer$new(2)

  # Push large amount of data
  large_data <- rep(as.raw(1), 1000)
  rb$push(large_data)

  # Verify capacity and data
  expect_true(rb$capacity() >= 1000)
  expect_equal(rb$size(), 1000)
  expect_equal(rb$pop(1000), large_data)
})

test_that("buffer doubles in size when growing from capacity 1", {
  # Create a ring buffer with capacity 1 to test the max(1, private$.capacity * 2) line
  rb <- RingBuffer$new(1)
  expect_equal(rb$capacity(), 1)

  # Adding two bytes should trigger resize and double capacity from 1 to 2
  rb$push(as.raw(c(0x01, 0x02)))
  expect_equal(rb$capacity(), 2)

  # Data should remain intact
  expect_equal(rb$pop(2), as.raw(c(0x01, 0x02)))
})

test_that("contiguous data is correctly preserved when resizing", {
  rb <- RingBuffer$new(4)

  test_data <- as.raw(c(0x01, 0x02, 0x03, 0x04))
  rb$push(test_data)
  expect_equal(rb$size(), 4)
  expect_equal(rb$capacity(), 4)

  rb$push(as.raw(0x05))
  expect_equal(rb$capacity(), 8)
  expect_equal(rb$size(), 5)

  # Pop all data to verify it was preserved in correct order
  expect_equal(rb$pop(5), as.raw(c(0x01, 0x02, 0x03, 0x04, 0x05)))
})

test_that("contiguous data with head and tail in middle is preserved when resizing", {
  rb <- RingBuffer$new(10)

  # Add some initial data
  rb$push(as.raw(c(0x01, 0x02, 0x03, 0x04, 0x05)))
  # Remove some from the beginning to move the tail pointer
  rb$pop(2)
  # Add more data but not enough to wrap
  rb$push(as.raw(c(0x06, 0x07)))

  # Current state: [-, -, 0x03, 0x04, 0x05, 0x06, 0x07, -, -, -]
  #                     ^tail                     ^head
  # Internally: .tail = 3, .count = 5

  # Now add enough data to force resize
  rb$push(as.raw(c(0x08, 0x09, 0x0A, 0x0B, 0x0C)))

  # Verify data preserved after resize
  result <- rb$pop(10)
  expect_equal(
    result,
    as.raw(c(0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C))
  )
})

test_that("sequence indexing works correctly in contiguous case", {
  # This specifically tests the idx <- seq(from = private$.tail, length.out = private$.count) line
  rb <- RingBuffer$new(10)

  # Add some data
  test_data <- as.raw(c(0xA1, 0xA2, 0xA3, 0xA4, 0xA5))
  rb$push(test_data)

  # Pop some to move tail
  rb$pop(2)

  # Add more data that triggers resize and tests sequence indexing
  rb$push(as.raw(c(0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7, 0xB8)))

  # Data should be: [0xA3, 0xA4, 0xA5, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7, 0xB8]
  # Verify with partial pops to test sequence indexing worked correctly

  result1 <- rb$pop(3)
  expect_equal(result1, as.raw(c(0xA3, 0xA4, 0xA5)))

  result2 <- rb$pop(8)
  expect_equal(
    result2,
    as.raw(c(0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7, 0xB8))
  )
})

test_that("direct vector assignment in push works correctly", {
  # This tests the new_buffer[1:private$.count] <- private$.buffer[idx] line
  rb <- RingBuffer$new(5)

  # Fill buffer
  rb$push(as.raw(c(0x01, 0x02, 0x03, 0x04, 0x05)))

  # Pop some to move tail
  rb$pop(2)

  # Push more to cause resize
  rb$push(as.raw(c(0x06, 0x07, 0x08)))

  # Pop everything and check order
  result <- rb$pop(6)
  expect_equal(result, as.raw(c(0x03, 0x04, 0x05, 0x06, 0x07, 0x08)))

  # Check capacity doubled
  expect_equal(rb$capacity(), 10)
})

test_that("multiple resize operations maintain data integrity", {
  # This tests repeated execution of the resize method
  rb <- RingBuffer$new(2)

  # Initial data
  rb$push(as.raw(c(0x01, 0x02)))

  # First resize
  rb$push(as.raw(0x03))
  expect_equal(rb$capacity(), 4)

  # Second resize
  rb$push(as.raw(c(0x04, 0x05)))
  expect_equal(rb$capacity(), 8)

  # Third resize
  rb$push(as.raw(c(0x06, 0x07, 0x08, 0x09, 0x0A)))
  expect_equal(rb$capacity(), 16)

  # Verify all data maintained correctly
  result <- rb$pop(10)
  expect_equal(
    result,
    as.raw(c(0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A))
  )
})

test_that("buffer resizes to exact required size", {
  # This tests the resize with required_size parameter
  rb <- RingBuffer$new(5)

  # Add data until we have 3 elements
  rb$push(as.raw(c(0x01, 0x02, 0x03)))

  # Add a chunk that requires specific capacity (15 more elements, total 18)
  large_chunk <- as.raw(seq(0x10, 0x1E)) # 15 elements
  rb$push(large_chunk)

  # Verify capacity is large enough
  expect_true(rb$capacity() >= 18)

  # Verify data integrity
  result <- rb$pop(18)
  expect_equal(result[1:3], as.raw(c(0x01, 0x02, 0x03)))
  expect_equal(result[4:18], large_chunk)
})

test_that("peek works correctly", {
  rb <- RingBuffer$new()

  # Test empty buffer
  expect_null(rb$peek(1))

  # Test single byte peek
  rb$push(as.raw(c(1, 2, 3, 4)))
  expect_equal(rb$peek(1), as.raw(1))
  expect_equal(rb$peek(2), as.raw(2))
  expect_equal(rb$peek(4), as.raw(4))

  # Test peek beyond available data
  expect_null(rb$peek(5))

  # Test peek after some data removed
  rb$pop(2) # Remove first two bytes
  expect_equal(rb$peek(1), as.raw(3))
  expect_equal(rb$peek(2), as.raw(4))
  expect_null(rb$peek(3))

  # Test peek with wrapped buffer
  rb <- RingBuffer$new(5)
  rb$push(as.raw(c(1, 2, 3))) # [1,2,3,_,_]
  rb$pop(2) # [_,_,3,_,_]
  rb$push(as.raw(c(4, 5, 6))) # [5,6,3,4,_]

  expect_equal(rb$peek(1), as.raw(3))
  expect_equal(rb$peek(2), as.raw(4))
  expect_equal(rb$peek(3), as.raw(5))
  expect_equal(rb$peek(4), as.raw(6))
})
