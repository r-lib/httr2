# can determine if incomplete data is complete

    Code
      expect_equal(resp_stream_sse(con), NULL)
    Condition
      Warning:
      Premature end of input; ignoring final partial chunk

# can't read from a closed connection

    Code
      resp_stream_raw(resp, 1)
    Condition
      Error in `resp_stream_raw()`:
      ! `resp` has already been closed.

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
      

