# happign

<details>

* Version: 0.2.0
* GitHub: https://github.com/paul-carteron/happign
* Source code: https://github.com/cran/happign
* Date/Publication: 2023-08-07 19:10:02 UTC
* Number of recursive dependencies: 120

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
      Linking to GEOS 3.8.0, GDAL 3.0.4, PROJ 6.3.1; sf_use_s2() is TRUE
    ...
        6. │     └─rlang::eval_bare(quo_get_expr(.quo), quo_get_env(.quo))
        7. └─happign:::build_req(path, "test")
        8.   └─httr2::req_url_query(...)
        9.     └─httr2:::query_build(dots)
       10.       └─cli::cli_abort("Query must be a named list.", call = error_call)
       11.         └─rlang::abort(...)
      
      [ FAIL 1 | WARN 21 | SKIP 24 | PASS 64 ]
      Error: Test failures
      Execution halted
    ```

## In both

*   checking data for non-ASCII characters ... NOTE
    ```
      Note: found 7592 marked UTF-8 strings
    ```

