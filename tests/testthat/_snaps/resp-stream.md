# can't read from a closed connection

    Code
      resp_stream_raw(resp, 1)
    Condition
      Error in `resp_stream_raw()`:
      ! `resp` has already been closed.

# streaming functions require a streaming response

    Code
      resp_stream_raw(response())
    Condition
      Error in `resp_stream_raw()`:
      ! `resp` must be a streaming HTTP response object, not a <httr2_response> object.

# resp_stream_raw() validates kb

    Code
      resp_stream_raw(resp, kb = -1)
    Condition
      Error in `resp_stream_raw()`:
      ! `kb` must be a number larger than or equal to 0, not the number -1.

---

    Code
      resp_stream_raw(resp, kb = Inf)
    Condition
      Error in `resp_stream_raw()`:
      ! `kb` must be a number, not `Inf`.

# resp_stream_is_complete() requires an open streaming response

    Code
      resp_stream_is_complete(response())
    Condition
      Error in `resp_stream_is_complete()`:
      ! `resp` must be a streaming HTTP response object, not a <httr2_response> object.

---

    Code
      resp_stream_is_complete(resp)
    Condition
      Error in `resp_stream_is_complete()`:
      ! `resp` has already been closed.

# streaming responses use only one reader

    Code
      resp_stream_raw(resp)
    Condition
      Error in `resp_stream_raw()`:
      ! Can't use resp_stream_raw() after resp_stream_lines() on the same response.

# BoundarySplitter splits, caps reads, and discards trailers

    Code
      out <- s$finish(charToRaw("b"))
    Condition
      Warning:
      Premature end of input; ignoring final partial chunk

# verbosity = 3 logs the buffered chunk

    Code
      while (!resp_stream_is_complete(con)) {
        resp_stream_lines(con, 1)
      }
    Output
      *  -- Buffer ----------------------------------------------------------------------
      *  Received chunk: 6c 69 6e 65 20 31 0a 6c 69 6e 65 20 32 0a
      << line 1
      << line 2

# verbosity = 2 streams request bodies

    Code
      stream_all(req, resp_stream_lines, 1)
    Output
      << line 1
      << line 2
    Code
      stream_all(req, resp_stream_raw, 5 / 1024)
    Output
      << Streamed 5 bytes
      
      << Streamed 5 bytes
      
      << Streamed 4 bytes
      

