#' RingBuffer Class
#'
#' An implementation of a ring buffer using a raw vector as the underlying storage.
#' The buffer has a user-specified initial size and can grow when full.
#'
#' @examples
#' rb <- RingBuffer$new(10)
#' rb$push(as.raw(1:5))
#' data <- rb$pop(3)
#' @noRd
RingBuffer <- R6::R6Class(
  "RingBuffer",
  private = list(
    .buffer = raw(),

    # Next position to write to
    .head = 0,
    # Next position to read from
    .tail = 0,
    # Elements currently in the buffer
    .count = 0,
    # Current capacity of the buffer
    .capacity = 0,

    .resize = function(required_size = NULL) {
      # If required_size is provided, ensure we grow to at least that size
      new_capacity <- max(1, required_size, private$.capacity * 2)
      new_buffer <- raw(new_capacity)

      # Copy data from old buffer to new buffer, starting from tail
      if (private$.count > 0) {
        if (private$.tail < private$.head) {
          # Simple case: tail to head is contiguous
          idx <- seq(private$.tail, length.out = private$.count)
          new_buffer[1:private$.count] <- private$.buffer[idx]
        } else {
          # Wrapped case: tail to end, then start to head
          n_end <- private$.capacity - private$.tail + 1
          idx1 <- seq(private$.tail, private$.capacity)
          new_buffer[1:n_end] <- private$.buffer[idx1]

          if (private$.head > 1) {
            idx2 <- seq_len(private$.head - 1)
            new_buffer[(n_end + 1):private$.count] <- private$.buffer[idx2]
          }
        }
      }

      # Update buffer and pointers
      private$.buffer <- new_buffer
      private$.tail <- 1
      private$.head <- private$.count + 1
      if (private$.count == 0) private$.head <- 1
      private$.capacity <- new_capacity
    }
  ),

  public = list(
    initialize = function(initial_capacity = 32 * 1024) {
      check_number_whole(initial_capacity, min = 1)

      private$.capacity <- as.integer(initial_capacity)
      private$.buffer <- raw(private$.capacity)
      private$.head <- 1
      private$.tail <- 1
      private$.count <- 0
    },

    push = function(data) {
      data_length <- length(data)

      # Check if we need to resize
      if (data_length + private$.count > private$.capacity) {
        private$.resize(data_length + private$.count)
      }

      # Add data to buffer using vectorized operations where possible
      if (private$.head + data_length - 1 <= private$.capacity) {
        # Contiguous space available
        idx <- seq(private$.head, length.out = data_length)
        private$.buffer[idx] <- data
        private$.head <- (private$.head + data_length - 1) %%
          private$.capacity +
          1
      } else {
        # Need to wrap around
        space_to_end <- private$.capacity - private$.head + 1

        # First part - fill to the end
        idx1 <- seq(from = private$.head, to = private$.capacity)
        private$.buffer[idx1] <- data[1:space_to_end]

        # Second part - start from beginning
        remaining <- data_length - space_to_end
        if (remaining > 0) {
          idx2 <- seq(from = 1, length.out = remaining)
          private$.buffer[idx2] <- data[(space_to_end + 1):data_length]
          private$.head <- remaining + 1
        } else {
          private$.head <- 1
        }
      }

      private$.count <- private$.count + data_length
      invisible(self)
    },

    pop = function(n = self$size()) {
      n <- as.integer(n)
      if (n <= 0) return(raw(0))

      # Limit to available items
      n <- min(n, private$.count)
      if (n == 0) return(raw(0))

      # Create result vector
      result <- raw(n)

      # Extract data using vectorized operations
      if (private$.tail + n - 1 <= private$.capacity) {
        # Contiguous read
        idx <- seq(from = private$.tail, length.out = n)
        result <- private$.buffer[idx]
        private$.tail <- (private$.tail + n - 1) %% private$.capacity + 1
      } else {
        # Wrapped read
        elements_to_end <- private$.capacity - private$.tail + 1

        # First part - read to the end
        idx1 <- seq(from = private$.tail, to = private$.capacity)
        result[1:elements_to_end] <- private$.buffer[idx1]

        # Second part - read from beginning
        remaining <- n - elements_to_end
        if (remaining > 0) {
          idx2 <- seq(from = 1, length.out = remaining)
          result[(elements_to_end + 1):n] <- private$.buffer[idx2]
          private$.tail <- remaining + 1
        } else {
          private$.tail <- 1
        }
      }

      private$.count <- private$.count - n
      result
    },

    # Peek at a single byte
    peek = function(i = 1) {
      if (i > private$.count) {
        return(NULL) # Not enough data
      }

      pos <- (private$.tail + i - 2) %% private$.capacity + 1
      private$.buffer[pos]
    },

    peek_all = function() {
      if (private$.count == 0) return(raw(0))

      result <- raw(private$.count)

      if (private$.tail < private$.head) {
        # Simple case: data is contiguous
        idx <- seq(from = private$.tail, length.out = private$.count)
        result <- private$.buffer[idx]
      } else {
        # Wrapped case: need to read in two parts
        elements_to_end <- private$.capacity - private$.tail + 1

        # First part - read to the end
        idx1 <- seq(from = private$.tail, to = private$.capacity)
        result[1:elements_to_end] <- private$.buffer[idx1]

        # Second part - read from beginning
        remaining <- private$.count - elements_to_end
        if (remaining > 0) {
          idx2 <- seq(from = 1, length.out = remaining)
          result[(elements_to_end + 1):private$.count] <- private$.buffer[idx2]
        }
      }

      result
    },

    is_empty = function() {
      private$.count == 0
    },

    size = function() {
      private$.count
    },

    capacity = function() {
      private$.capacity
    }
  )
)
