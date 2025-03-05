# happign

<details>

* Version: 0.3.2
* GitHub: https://github.com/paul-carteron/happign
* Source code: https://github.com/cran/happign
* Date/Publication: 2025-01-24 09:30:05 UTC
* Number of recursive dependencies: 116

Run `revdepcheck::cloud_details(, "happign")` for more info

</details>

## Newly broken

*   checking tests ... ERROR
    ```
      Running ‘testthat.R’
    Running the tests in ‘tests/testthat.R’ failed.
    Complete output:
      > library(testthat)
      > library(happign)
      Please make sure you have an internet connection.
      Use happign::get_last_news() to display latest geoservice news.
      > 
      > test_check("happign")
      Linking to GEOS 3.12.1, GDAL 3.8.4, PROJ 9.4.0; sf_use_s2() is TRUE
    ...
        'test-get_wmts.R:40:4', 'test-get_wmts.R:51:4', 'test-hit_api.R:12:7',
        'test-utils.R:3:4', 'test-utils.R:18:4', 'test-utils.R:90:7'
      
      ══ Failed tests ════════════════════════════════════════════════════════════════
      ── Failure ('test-get_iso.R:40:4'): build_iso_query works ──────────────────────
      `req` has length 8, not length 7.
      
      [ FAIL 1 | WARN 0 | SKIP 38 | PASS 87 ]
      Error: Test failures
      Execution halted
    ```

## In both

*   checking data for non-ASCII characters ... NOTE
    ```
      Note: found 15185 marked UTF-8 strings
    ```

# tidyllm

<details>

* Version: 0.3.1
* GitHub: https://github.com/edubruell/tidyllm
* Source code: https://github.com/cran/tidyllm
* Date/Publication: 2025-02-24 19:20:02 UTC
* Number of recursive dependencies: 127

Run `revdepcheck::cloud_details(, "tidyllm")` for more info

</details>

## Newly broken

*   checking tests ... ERROR
    ```
      Running ‘testthat.R’
    Running the tests in ‘tests/testthat.R’ failed.
    Complete output:
      > # This file is part of the standard setup for testthat.
      > # It is recommended that you do not modify it.
      > #
      > # Where should you do additional test configuration?
      > # Learn more about the roles of various files in:
      > # * https://r-pkgs.org/testing-design.html#sec-tests-files-overview
      > # * https://testthat.r-lib.org/articles/special-files.html
    ...
      ══ Failed tests ════════════════════════════════════════════════════════════════
      ── Failure ('test_api_claude.R:29:3'): claude function constructs a correct request and dry runs it ──
      "accept-encoding" %in% names(headers) is not TRUE
      
      `actual`:   FALSE
      `expected`: TRUE 
      
      [ FAIL 1 | WARN 0 | SKIP 0 | PASS 214 ]
      Error: Test failures
      Execution halted
    ```

