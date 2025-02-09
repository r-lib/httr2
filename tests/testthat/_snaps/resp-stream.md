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
      

# verbosity = 3 shows buffer info

    Code
      while (!resp_stream_is_complete(con)) {
        resp_stream_lines(con, 1)
      }
    Output
      *  -- Buffer ----------------------------------------------------------------------
      *  Buffer to parse: 
      *  Received chunk: 6c 69 6e 65 20 31 0a 6c 69 6e 65 20 32 0a
      *  Combined buffer: 6c 69 6e 65 20 31 0a 6c 69 6e 65 20 32 0a
      *  Buffer to parse: 6c 69 6e 65 20 31 0a 6c 69 6e 65 20 32 0a
      *  Matched data: 6c 69 6e 65 20 31 0a
      *  Remaining buffer: 6c 69 6e 65 20 32 0a
      << line 1
      *  -- Buffer ----------------------------------------------------------------------
      *  Buffer to parse: 6c 69 6e 65 20 32 0a
      *  Matched data: 6c 69 6e 65 20 32 0a
      *  Remaining buffer: 
      << line 2

# verbosity = 3 shows raw sse events

    Code
      . <- resp_stream_sse(resp)
    Output
      *  -- Buffer ----------------------------------------------------------------------
      *  Buffer to parse: 
      *  Received chunk: 3a 20 63 6f 6d 6d 65 6e 74 0a 0a 64 61 74 61 3a 20 31 0a 0a
      *  Combined buffer: 3a 20 63 6f 6d 6d 65 6e 74 0a 0a 64 61 74 61 3a 20 31 0a 0a
      *  Buffer to parse: 3a 20 63 6f 6d 6d 65 6e 74 0a 0a 64 61 74 61 3a 20 31 0a 0a
      *  Matched data: 3a 20 63 6f 6d 6d 65 6e 74 0a 0a
      *  Remaining buffer: 64 61 74 61 3a 20 31 0a 0a
      *  -- Raw server sent event -------------------------------------------------------
      *  : comment
      *  
      *  
      *  -- Buffer ----------------------------------------------------------------------
      *  Buffer to parse: 64 61 74 61 3a 20 31 0a 0a
      *  Matched data: 64 61 74 61 3a 20 31 0a 0a
      *  Remaining buffer: 
      *  -- Raw server sent event -------------------------------------------------------
      *  data: 1
      *  
      *  
      << type: message
      << data: 1
      << id: 
      

