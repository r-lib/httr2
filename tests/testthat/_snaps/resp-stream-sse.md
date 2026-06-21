# can determine if incomplete data is complete

    Code
      expect_equal(resp_stream_sse(con), NULL)
    Condition
      Warning:
      Premature end of input; ignoring final partial chunk

# verbosity = 3 shows raw sse events

    Code
      . <- resp_stream_sse(resp)
    Output
      *  -- Buffer ----------------------------------------------------------------------
      *  Received chunk: 3a 20 63 6f 6d 6d 65 6e 74 0a 0a 64 61 74 61 3a 20 31 0a 0a
      *  -- Raw server sent event -------------------------------------------------------
      *  : comment
      *  
      *  
      *  -- Raw server sent event -------------------------------------------------------
      *  data: 1
      *  
      *  
      << type: message
      << data: 1
      << id: 
      

