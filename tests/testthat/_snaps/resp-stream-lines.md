# verbosity = 3 shows buffer info

    Code
      while (!resp_stream_is_complete(con)) {
        resp_stream_lines(con, 1)
      }
    Output
      *  -- Buffer ----------------------------------------------------------------------
      *  Received chunk: 6c 69 6e 65 20 31 0a 6c 69 6e 65 20 32 0a
      << line 1
      << line 2

# LineSplitter flushes a trailing line and warns

    Code
      out <- s$finish(charToRaw("tail"))
    Condition
      Warning:
      incomplete final line found

# stream_split_lines() enforces max_size

    Code
      stream_split_lines(charToRaw("aaaaa"), "UTF-8", eat_lf = FALSE, max_size = 3)
    Condition
      Error in `stream_split_lines()`:
      ! Streaming read exceeded size limit of 3

---

    Code
      stream_split_lines(charToRaw("aaaaa\n"), "UTF-8", eat_lf = FALSE, max_size = 3)
    Condition
      Error in `stream_split_lines()`:
      ! Streaming read exceeded size limit of 3

