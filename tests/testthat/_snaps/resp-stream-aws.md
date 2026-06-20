# unknown header triggers error

    Code
      parse_aws_event(aws_event(aws_header("foo", "unknown")))
    Condition
      Error in `type_enum()`:
      ! Unsupported type 255.
      i This is an internal error that was detected in the httr2 package.
        Please report it at <https://github.com/r-lib/httr2/issues> with a reprex (<https://tidyverse.org/help/>) and the full backtrace.

# parse_aws_event() checks the prelude length

    Code
      parse_aws_event(as.raw(1:10))
    Condition
      Error in `parse_aws_event()`:
      ! AWS event metadata doesn't match supplied bytes
      i This is an internal error that was detected in the httr2 package.
        Please report it at <https://github.com/r-lib/httr2/issues> with a reprex (<https://tidyverse.org/help/>) and the full backtrace.

# verbosity = 3 shows aws events

    Code
      . <- resp_stream_aws(resp)
    Output
      *  -- Buffer ----------------------------------------------------------------------
      *  Received chunk: 00 00 00 1a 00 00 00 0a af a7 b9 54 03 66 6f 6f 07 00 03 62 61 72 c0 c0 6d f5
      << foo: bar
      << ""
      

