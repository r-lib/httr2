# atrrr

<details>

* Version: 0.1.0
* GitHub: https://github.com/JBGruber/atrrr
* Source code: https://github.com/cran/atrrr
* Date/Publication: 2025-01-20 11:30:42 UTC
* Number of recursive dependencies: 96

Run `revdepcheck::cloud_details(, "atrrr")` for more info

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
       33. │               └─httr2::url_build(...)
       34. │                 └─curl::curl_modify_url(...)
       35. └─base::.handleSimpleError(...)
       36.   └─purrr (local) h(simpleError(msg, call))
       37.     └─cli::cli_abort(...)
       38.       └─rlang::abort(...)
      
      [ FAIL 101 | WARN 0 | SKIP 2 | PASS 68 ]
      Error: Test failures
      Execution halted
    ```

# bskyr

<details>

* Version: 0.3.0
* GitHub: https://github.com/christopherkenny/bskyr
* Source code: https://github.com/cran/bskyr
* Date/Publication: 2025-05-02 23:10:02 UTC
* Number of recursive dependencies: 73

Run `revdepcheck::cloud_details(, "bskyr")` for more info

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
      > # * https://r-pkgs.org/testing-design.html#sec-tests-files-overview
    ...
       4.     │ └─httr2:::check_response(resp)
       5.     │   └─httr2:::is_response(resp)
       6.     └─httr2::req_perform(...)
       7.       └─httptest2 (local) mock(req)
       8.         └─httptest2:::stop_request(req)
       9.           └─rlang::abort(out, mockfile = req$mockfile, class = "httptest2_request")
      
      [ FAIL 15 | WARN 0 | SKIP 0 | PASS 102 ]
      Error: Test failures
      Execution halted
    ```

# comtradr

<details>

* Version: 1.0.3
* GitHub: https://github.com/ropensci/comtradr
* Source code: https://github.com/cran/comtradr
* Date/Publication: 2024-11-15 17:40:08 UTC
* Number of recursive dependencies: 93

Run `revdepcheck::cloud_details(, "comtradr")` for more info

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
       3. └─comtradr::ct_get_data(...) at test-ct_get_data.R:73:7
       4.   └─comtradr:::ct_perform_request(...)
       5.     └─httr2::req_perform(...)
       6.       └─httptest2 (local) mock(req)
       7.         └─httptest2:::stop_request(req)
       8.           └─rlang::abort(out, mockfile = req$mockfile, class = "httptest2_request")
      
      [ FAIL 7 | WARN 0 | SKIP 2 | PASS 107 ]
      Error: Test failures
      Execution halted
    ```

## In both

*   checking data for non-ASCII characters ... NOTE
    ```
      Note: found 11 marked UTF-8 strings
    ```

# forcis

<details>

* Version: 1.0.1
* GitHub: https://github.com/ropensci/forcis
* Source code: https://github.com/cran/forcis
* Date/Publication: 2025-05-23 12:02:02 UTC
* Number of recursive dependencies: 93

Run `revdepcheck::cloud_details(, "forcis")` for more info

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
       17.                         │ │   └─base::eval(expr, p)
       18.                         │ └─httptest2::with_mock_api(expr)
       19.                         │   └─base::eval.parent(expr)
       20.                         │     └─base::eval(expr, p)
       21.                         └─forcis:::get_metadata() at tests/testthat/setup.R:31:5
       22.                           └─httr2::req_perform(http_request)
       23.                             └─httptest2 (local) mock(req)
       24.                               └─httptest2:::stop_request(req)
       25.                                 └─rlang::abort(out, mockfile = req$mockfile, class = "httptest2_request")
      Execution halted
    ```

## In both

*   checking installed package size ... NOTE
    ```
      installed size is  5.6Mb
      sub-directories of 1Mb or more:
        R      2.1Mb
        doc    1.3Mb
        help   1.0Mb
    ```

# gtexr

<details>

* Version: 0.2.0
* GitHub: https://github.com/ropensci/gtexr
* Source code: https://github.com/cran/gtexr
* Date/Publication: 2025-04-23 21:30:02 UTC
* Number of recursive dependencies: 65

Run `revdepcheck::cloud_details(, "gtexr")` for more info

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
      > # * https://r-pkgs.org/testing-design.html#sec-tests-files-overview
    ...
       15.       │   └─httr2:::is_response(resp)
       16.       └─gtexr:::perform_gtex_request(gtex_request, call = call)
       17.         └─httr2::req_perform(...)
       18.           └─httptest2 (local) mock(req)
       19.             └─httptest2:::stop_request(req)
       20.               └─rlang::abort(out, mockfile = req$mockfile, class = "httptest2_request")
      
      [ FAIL 4 | WARN 0 | SKIP 54 | PASS 46 ]
      Error: Test failures
      Execution halted
    ```

# httptest2

<details>

* Version: 1.1.0
* GitHub: https://github.com/nealrichardson/httptest2
* Source code: https://github.com/cran/httptest2
* Date/Publication: 2024-04-26 13:40:02 UTC
* Number of recursive dependencies: 53

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
      [ FAIL 2 | WARN 0 | SKIP 1 | PASS 233 ]
      
      ══ Skipped tests (1) ═══════════════════════════════════════════════════════════
    ...
       3. │   └─base::eval(expr, p)
       4. ├─... %>% req_perform() at test-redact.R:147:3
       5. └─httr2::req_perform(.)
       6.   └─httptest2 (local) mock(req)
       7.     └─httptest2:::stop_request(req)
       8.       └─rlang::abort(out, mockfile = req$mockfile, class = "httptest2_request")
      
      [ FAIL 2 | WARN 0 | SKIP 1 | PASS 233 ]
      Error: Test failures
      Execution halted
    ```

# locateip

<details>

* Version: 0.1.2
* GitHub: NA
* Source code: https://github.com/cran/locateip
* Date/Publication: 2023-06-06 07:40:05 UTC
* Number of recursive dependencies: 54

Run `revdepcheck::cloud_details(, "locateip")` for more info

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
      ── Failure ('test-locate.R:70:3'): create request works ────────────────────────
      req[["url"]] (`actual`) not equal to "http://ip-api.com/csv/132.203.167.188?fields=status%2Cmessage%2Ccountry%2Ccity&header=true" (`expected`).
      
      actual vs expected
      - "http://ip-api.com/csv/132.203.167.188?fields=status%2cmessage%2ccountry%2ccity&header=true"
      + "http://ip-api.com/csv/132.203.167.188?fields=status%2Cmessage%2Ccountry%2Ccity&header=true"
      
      [ FAIL 5 | WARN 0 | SKIP 0 | PASS 5 ]
      Error: Test failures
      Execution halted
    ```

# osmapiR

<details>

* Version: 0.2.3
* GitHub: https://github.com/ropensci/osmapiR
* Source code: https://github.com/cran/osmapiR
* Date/Publication: 2025-04-15 08:50:02 UTC
* Number of recursive dependencies: 64

Run `revdepcheck::cloud_details(, "osmapiR")` for more info

</details>

## Newly broken

*   checking examples ... ERROR
    ```
    Running examples in ‘osmapiR-Ex.R’ failed
    The error most likely occurred in:
    
    > ### Name: osm_get_changesets
    > ### Title: Get changesets
    > ### Aliases: osm_get_changesets
    > 
    > ### ** Examples
    > 
    > chaset <- osm_get_changesets(changeset_id = 137595351, include_discussion = TRUE)
    ...
      5.         └─httr2:::resp_failure_cnd(req, resp, error_call = error_call)
      6.           ├─rlang::catch_cnd(...)
      7.           │ ├─rlang::eval_bare(...)
      8.           │ ├─base::tryCatch(...)
      9.           │ │ └─base (local) tryCatchList(expr, classes, parentenv, handlers)
     10.           │ │   └─base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
     11.           │ │     └─base (local) doTryCatch(return(expr), name, parentenv, handler)
     12.           │ └─base::force(expr)
     13.           └─rlang::abort(...)
    Execution halted
    ```

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
        8. └─osmapiR::osm_get_user_details(...) at test-user_data.R:78:5
        9.   └─osmapiR:::osm_details_users(user_ids = user_id, format = format)
       10.     └─httr2::req_perform(req)
       11.       └─httptest2 (local) mock(req)
       12.         └─httptest2:::stop_request(req)
       13.           └─rlang::abort(out, mockfile = req$mockfile, class = "httptest2_request")
      
      [ FAIL 18 | WARN 0 | SKIP 8 | PASS 887 ]
      Error: Test failures
      Execution halted
    ```

# riem

<details>

* Version: 1.0.0
* GitHub: https://github.com/ropensci/riem
* Source code: https://github.com/cran/riem
* Date/Publication: 2025-01-31 09:10:02 UTC
* Number of recursive dependencies: 88

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
      [ FAIL 4 | WARN 0 | SKIP 9 | PASS 31 ]
      
      ══ Skipped tests (9) ═══════════════════════════════════════════════════════════
    ...
       15. │ └─riem:::perform_riem_request(...)
       16. │   └─... %>% httr2::req_perform()
       17. └─httr2::req_perform(.)
       18.   └─httptest2 (local) mock(req)
       19.     └─httptest2:::stop_request(req)
       20.       └─rlang::abort(out, mockfile = req$mockfile, class = "httptest2_request")
      
      [ FAIL 4 | WARN 0 | SKIP 9 | PASS 31 ]
      Error: Test failures
      Execution halted
    ```

# rirods

<details>

* Version: 0.2.0
* GitHub: https://github.com/irods/irods_client_library_rirods
* Source code: https://github.com/cran/rirods
* Date/Publication: 2024-03-15 18:30:02 UTC
* Number of recursive dependencies: 81

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
          ▆
       1. └─rirods::ils(metadata = TRUE) at test-navigation.R:173:5
       2.   └─httr2::req_perform(...)
       3.     └─httptest2 (local) mock(req)
       4.       └─httptest2:::stop_request(req)
       5.         └─rlang::abort(out, mockfile = req$mockfile, class = "httptest2_request")
      
      [ FAIL 28 | WARN 0 | SKIP 8 | PASS 50 ]
      Error: Test failures
      Execution halted
    ```

# rlandfire

<details>

* Version: 2.0.0
* GitHub: https://github.com/bcknr/rlandfire
* Source code: https://github.com/cran/rlandfire
* Date/Publication: 2025-04-28 22:30:02 UTC
* Number of recursive dependencies: 68

Run `revdepcheck::cloud_details(, "rlandfire")` for more info

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
      ── Failure ('test-landfireAPI.R:120:5'): `landfireAPIv2()` formats priority requests correctly ──
      output$request$url (`actual`) not identical to "https://lfps.usgs.gov/api/job/submit?Email=example%40domain.com&Layer_List=ELEV2020%3BSLPD2020%3BASP2020%3B230FBFM40%3B230CC%3B230CH%3B230CBH%3B230CBD&Area_of_Interest=-113.79%2042.148%20-113.56%2042.29&Priority_Code=K3LS9F" (`expected`).
      
      actual vs expected
      - "https://lfps.usgs.gov/api/job/submit?Email=example%40domain.com&Layer_List=ELEV2020%3bSLPD2020%3bASP2020%3b230FBFM40%3b230CC%3b230CH%3b230CBH%3b230CBD&Area_of_Interest=-113.79%2042.148%20-113.56%2042.29&Priority_Code=K3LS9F"
      + "https://lfps.usgs.gov/api/job/submit?Email=example%40domain.com&Layer_List=ELEV2020%3BSLPD2020%3BASP2020%3B230FBFM40%3B230CC%3B230CH%3B230CBH%3B230CBD&Area_of_Interest=-113.79%2042.148%20-113.56%2042.29&Priority_Code=K3LS9F"
      
      [ FAIL 1 | WARN 0 | SKIP 2 | PASS 78 ]
      Error: Test failures
      Execution halted
    ```

# tidyllm

<details>

* Version: 0.3.4
* GitHub: https://github.com/edubruell/tidyllm
* Source code: https://github.com/cran/tidyllm
* Date/Publication: 2025-03-27 11:40:01 UTC
* Number of recursive dependencies: 124

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
      ── Failure ('test_api_gemini.R:24:3'): gemini_chat function constructs a correct request and dry runs it ──
      grepl("/v1beta/models/gemini-2.0-flash:generateContent", dry_run$path) is not TRUE
      
      `actual`:   FALSE
      `expected`: TRUE 
      
      [ FAIL 1 | WARN 0 | SKIP 0 | PASS 279 ]
      Error: Test failures
      Execution halted
    ```

# wbwdi

<details>

* Version: 1.0.1
* GitHub: https://github.com/tidy-intelligence/r-wbwdi
* Source code: https://github.com/cran/wbwdi
* Date/Publication: 2025-03-25 21:00:01 UTC
* Number of recursive dependencies: 59

Run `revdepcheck::cloud_details(, "wbwdi")` for more info

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
      ── Failure ('tests-perform_request.R:80:3'): create_request constructs a request with parameters ──
      req$url (`actual`) not equal to paste0("https://api.worldbank.org/v2/en/lendingTypes", "?format=json&per_page=500&date=2000%3A2020&source=2") (`expected`).
      
      actual vs expected
      - "https://api.worldbank.org/v2/en/lendingTypes?format=json&per_page=500&date=2000%3a2020&source=2"
      + "https://api.worldbank.org/v2/en/lendingTypes?format=json&per_page=500&date=2000%3A2020&source=2"
      
      [ FAIL 1 | WARN 0 | SKIP 25 | PASS 123 ]
      Error: Test failures
      Execution halted
    ```

