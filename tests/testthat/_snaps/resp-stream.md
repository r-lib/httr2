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
      

