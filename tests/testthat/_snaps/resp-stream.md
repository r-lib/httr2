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
      s$split(charToRaw("abcdef"), max_size = 3)
    Condition
      Error in `s$split()`:
      ! Streaming read exceeded size limit of 3

---

    Code
      out <- s$finish(charToRaw("b"))
    Condition
      Warning:
      Premature end of input; ignoring final partial chunk

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
      

