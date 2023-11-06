# congress

<details>

* Version: 0.0.1
* GitHub: https://github.com/christopherkenny/congress
* Source code: https://github.com/cran/congress
* Date/Publication: 2022-10-12 08:02:32 UTC
* Number of recursive dependencies: 57

Run `revdepcheck::cloud_details(, "congress")` for more info

</details>

## Newly broken

*   checking tests ... ERROR
    ```
      Running ‘spelling.R’
      Running ‘testthat.R’
    Running the tests in ‘tests/testthat.R’ failed.
    Complete output:
      > # This file is part of the standard setup for testthat.
      > # It is recommended that you do not modify it.
      > #
      > # Where should you do additional test configuration?
      > # Learn more about the roles of various files in:
      > # * https://r-pkgs.org/tests.html
    ...
       3.     └─httptest2 (local) mock(req)
       4.       └─httptest2:::load_response(mockfile, req)
       5.         └─httr2::response(method = req$method)
       6.           └─httr2:::check_string(method)
       7.             └─httr2:::stop_input_type(...)
       8.               └─rlang::abort(message, ..., call = call, arg = arg)
      
      [ FAIL 11 | WARN 0 | SKIP 0 | PASS 0 ]
      Error: Test failures
      Execution halted
    ```

# feltr

<details>

* Version: 0.0.4
* GitHub: https://github.com/christopherkenny/feltr
* Source code: https://github.com/cran/feltr
* Date/Publication: 2023-11-05 20:30:02 UTC
* Number of recursive dependencies: 65

Run `revdepcheck::cloud_details(, "feltr")` for more info

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
      > # * https://r-pkgs.org/tests.html
      > # * https://testthat.r-lib.org/reference/test_package.html#special-files
    ...
        6.     └─httptest2 (local) mock(req)
        7.       └─httptest2:::load_response(mockfile, req)
        8.         └─httr2::response(method = req$method)
        9.           └─httr2:::check_string(method)
       10.             └─httr2:::stop_input_type(...)
       11.               └─rlang::abort(message, ..., call = call, arg = arg)
      
      [ FAIL 3 | WARN 0 | SKIP 1 | PASS 0 ]
      Error: Test failures
      Execution halted
    ```

# gptzeror

<details>

* Version: 0.0.1
* GitHub: https://github.com/christopherkenny/gptzeror
* Source code: https://github.com/cran/gptzeror
* Date/Publication: 2023-06-05 08:30:02 UTC
* Number of recursive dependencies: 48

Run `revdepcheck::cloud_details(, "gptzeror")` for more info

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
      > # * https://r-pkgs.org/tests.html
      > # * https://testthat.r-lib.org/reference/test_package.html#special-files
    ...
        6.     └─httptest2 (local) mock(req)
        7.       └─httptest2:::load_response(mockfile, req)
        8.         └─httr2::response(method = req$method)
        9.           └─httr2:::check_string(method)
       10.             └─httr2:::stop_input_type(...)
       11.               └─rlang::abort(message, ..., call = call, arg = arg)
      
      [ FAIL 2 | WARN 0 | SKIP 0 | PASS 0 ]
      Error: Test failures
      Execution halted
    ```

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
      
      [ FAIL 5 | WARN 21 | SKIP 24 | PASS 58 ]
      Error: Test failures
      Execution halted
    ```

## In both

*   checking data for non-ASCII characters ... NOTE
    ```
      Note: found 7592 marked UTF-8 strings
    ```

# httptest2

<details>

* Version: 0.1.0
* GitHub: https://github.com/nealrichardson/httptest2
* Source code: https://github.com/cran/httptest2
* Date/Publication: 2022-01-10 08:52:45 UTC
* Number of recursive dependencies: 62

Run `revdepcheck::cloud_details(, "httptest2")` for more info

</details>

## Newly broken

*   checking tests ... ERROR
    ```
      Running ‘spelling.R’
      Running ‘testthat.R’
    Running the tests in ‘tests/testthat.R’ failed.
    Complete output:
      > library(testthat)
      > test_check("httptest2")
      Loading required package: httptest2
      Reading /tmp/workdir/httptest2/new/httptest2.Rcheck/tests/testthat/example.com/login-712027-POST.R
      Writing /tmp/RtmpPx69aP/filee6563a5e193/example.com/login-712027-POST.R
      Using redact.R from "testpkg"
    ...
       13.   └─httptest2 (local) mock(req)
       14.     └─httptest2:::load_response(mockfile, req)
       15.       └─httr2::response(method = req$method)
       16.         └─httr2:::check_string(method)
       17.           └─httr2:::stop_input_type(...)
       18.             └─rlang::abort(message, ..., call = call, arg = arg)
      
      [ FAIL 23 | WARN 20 | SKIP 8 | PASS 153 ]
      Error: Test failures
      Execution halted
    ```

# osmdata

<details>

* Version: 0.2.5
* GitHub: https://github.com/ropensci/osmdata
* Source code: https://github.com/cran/osmdata
* Date/Publication: 2023-08-14 11:40:08 UTC
* Number of recursive dependencies: 88

Run `revdepcheck::cloud_details(, "osmdata")` for more info

</details>

## Newly broken

*   checking tests ... ERROR
    ```
      Running ‘testthat.R’
    Running the tests in ‘tests/testthat.R’ failed.
    Complete output:
      > library(testthat)
      > library(osmdata)
      Data (c) OpenStreetMap contributors, ODbL 1.0. https://www.openstreetmap.org/copyright
      > 
      > test_check("osmdata")
      [ FAIL 8 | WARN 0 | SKIP 0 | PASS 535 ]
      
    ...
       13.           └─httptest2 (local) mock(req)
       14.             └─httptest2:::load_response(mockfile, req)
       15.               └─httr2::response(method = req$method)
       16.                 └─httr2:::check_string(method)
       17.                   └─httr2:::stop_input_type(...)
       18.                     └─rlang::abort(message, ..., call = call, arg = arg)
      
      [ FAIL 8 | WARN 0 | SKIP 0 | PASS 535 ]
      Error: Test failures
      Execution halted
    ```

## In both

*   checking installed package size ... NOTE
    ```
      installed size is 21.9Mb
      sub-directories of 1Mb or more:
        doc    5.0Mb
        libs  16.2Mb
    ```

# riem

<details>

* Version: 0.3.0
* GitHub: https://github.com/ropensci/riem
* Source code: https://github.com/cran/riem
* Date/Publication: 2022-02-08 13:40:02 UTC
* Number of recursive dependencies: 104

Run `revdepcheck::cloud_details(, "riem")` for more info

</details>

## Newly broken

*   checking tests ... ERROR
    ```
      Running ‘testthat.R’
    Running the tests in ‘tests/testthat.R’ failed.
    Complete output:
      > library(testthat)
      > library(riem)
      > 
      > test_check("riem")
      [ FAIL 3 | WARN 1 | SKIP 3 | PASS 1 ]
      
      ══ Skipped tests (3) ═══════════════════════════════════════════════════════════
    ...
       14.   └─httptest2 (local) mock(req)
       15.     └─httptest2:::load_response(mockfile, req)
       16.       └─httr2::response(method = req$method)
       17.         └─httr2:::check_string(method)
       18.           └─httr2:::stop_input_type(...)
       19.             └─rlang::abort(message, ..., call = call, arg = arg)
      
      [ FAIL 3 | WARN 1 | SKIP 3 | PASS 1 ]
      Error: Test failures
      Execution halted
    ```

# rirods

<details>

* Version: 0.1.2
* GitHub: https://github.com/irods/irods_client_library_rirods
* Source code: https://github.com/cran/rirods
* Date/Publication: 2023-11-02 18:40:02 UTC
* Number of recursive dependencies: 89

Run `revdepcheck::cloud_details(, "rirods")` for more info

</details>

## Newly broken

*   checking tests ... ERROR
    ```
      Running ‘spelling.R’
      Running ‘testthat.R’
    Running the tests in ‘tests/testthat.R’ failed.
    Complete output:
      > # This file is part of the standard setup for testthat.
      > # It is recommended that you do not modify it.
      > #
      > # Where should you do additional test configuration?
      > # Learn more about the roles of various files in:
      > # * https://r-pkgs.org/tests.html
    ...
        6. └─rirods::ils()
        7.   └─rirods:::irods_rest_call("list", "GET", args, verbose)
        8.     └─httr2::req_perform(req)
        9.       └─httptest2 (local) mock(req)
       10.         └─httptest2:::stop_request(req)
       11.           └─rlang::abort(out, mockfile = req$mockfile, class = "httptest2_request")
      
      [ FAIL 23 | WARN 0 | SKIP 7 | PASS 32 ]
      Error: Test failures
      Execution halted
    ```

