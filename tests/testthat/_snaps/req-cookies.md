# can read/write cookies

    Code
      readLines(cookie_path)[-(1:4)]
    Output
      [1] "127.0.0.1\tFALSE\t/\tFALSE\t0\tz\tc" "127.0.0.1\tFALSE\t/\tFALSE\t0\tx\ta"
      [3] "127.0.0.1\tFALSE\t/\tFALSE\t0\ty\tb"

