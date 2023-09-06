# vec_chop_by_size() can chop into chunks

    Code
      chunk_size <- 1.5
      vec_chop_by_size(1:5, chunk_size)
    Condition
      Error:
      ! `chunk_size` must be a whole number, not the number 1.5.

