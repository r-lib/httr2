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
      
      [ FAIL 156 | WARN 0 | SKIP 2 | PASS 13 ]
      Error: Test failures
      Execution halted
    ```

# brickster

<details>

* Version: 0.2.8
* GitHub: https://github.com/databrickslabs/brickster
* Source code: https://github.com/cran/brickster
* Date/Publication: 2025-06-06 10:40:02 UTC
* Number of recursive dependencies: 70

Run `revdepcheck::cloud_details(, "brickster")` for more info

</details>

## Newly broken

*   checking tests ... ERROR
    ```
      Running ‘testthat.R’
    Running the tests in ‘tests/testthat.R’ failed.
    Complete output:
      > library(testthat)
      > library(brickster)
      > library(withr)
      > 
      > test_check("brickster")
      [ FAIL 1 | WARN 0 | SKIP 20 | PASS 517 ]
      
    ...
      ══ Failed tests ════════════════════════════════════════════════════════════════
      ── Failure ('test-request-helpers.R:30:3'): request helpers - building requests ──
      req$headers$Authorization (`actual`) not equal to paste("Bearer", token) (`expected`).
      
      `actual` is a weak reference
      `expected` is a character vector ('Bearer some_token')
      
      [ FAIL 1 | WARN 0 | SKIP 20 | PASS 517 ]
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
      ── Failure ('test-url_uri.R:19:5'): urls to uri works starter-pack ─────────────
      bs_url_to_uri(...) (`actual`) not equal to "at://did:plc:wpe35pganb6d4pg4ekmfy6u5/app.bsky.graph.starterpack/3lb3g5veo2z2r" (`expected`).
      
      actual vs expected
      - "at://NA/app.bsky.graph.starterpack/3lb3g5veo2z2r"
      + "at://did:plc:wpe35pganb6d4pg4ekmfy6u5/app.bsky.graph.starterpack/3lb3g5veo2z2r"
      
      [ FAIL 44 | WARN 0 | SKIP 0 | PASS 73 ]
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
      Error: [ENOENT] Failed to search directory '/root/.cache/R/comtradr_bulk': no such file or directory
      Backtrace:
          ▆
       1. └─fs::dir_delete(tools::R_user_dir("comtradr_bulk", which = "cache")) at test-utils.R:94:3
       2.   └─fs::dir_ls(old, type = "directory", recurse = TRUE, all = TRUE)
       3.     └─fs::dir_map(old, identity, all, recurse, type, fail)
      
      [ FAIL 11 | WARN 0 | SKIP 2 | PASS 95 ]
      Error: Test failures
      Execution halted
    ```

## In both

*   checking data for non-ASCII characters ... NOTE
    ```
      Note: found 11 marked UTF-8 strings
    ```

# congress

<details>

* Version: 0.0.3
* GitHub: https://github.com/christopherkenny/congress
* Source code: https://github.com/cran/congress
* Date/Publication: 2024-01-09 15:20:02 UTC
* Number of recursive dependencies: 53

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
       2.   └─httr2::req_perform(req)
       3.     └─httptest2 (local) mock(req)
       4.       └─httptest2::build_mock_url(get_current_redactor()(req))
       5.         └─httptest2:::get_request_method(req)
       6.           └─utils::getFromNamespace("req_method_get", "httr2")
       7.             └─base::get(x, envir = ns, inherits = FALSE)
      
      [ FAIL 52 | WARN 0 | SKIP 0 | PASS 18 ]
      Error: Test failures
      Execution halted
    ```

# consibiocloudclient

<details>

* Version: 1.0.0
* GitHub: NA
* Source code: https://github.com/cran/consibiocloudclient
* Date/Publication: 2024-07-30 19:20:08 UTC
* Number of recursive dependencies: 49

Run `revdepcheck::cloud_details(, "consibiocloudclient")` for more info

</details>

## Newly broken

*   checking tests ... ERROR
    ```
      Running ‘testthat.R’
    Running the tests in ‘tests/testthat.R’ failed.
    Complete output:
      > start_test <- function() {
      +   if (!requireNamespace("testthat", quietly = TRUE)) {
      +     message("testthat package is not installed, please install it before running tests.")
      +     return()
      +   }
      + 
      +   library(testthat)
    ...
       2.   └─consibiocloudclient:::client_req_perform(url, error_msg = "Failed to get devices")
       3.     └─base::tryCatch(...)
       4.       └─base (local) tryCatchList(expr, classes, parentenv, handlers)
       5.         └─base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
       6.           └─value[[3L]](cond)
       7.             └─consibiocloudclient:::halt("An error occurred: ", conditionMessage(e))
      
      [ FAIL 10 | WARN 0 | SKIP 3 | PASS 50 ]
      Error: Test failures
      Execution halted
    ```

# dataRetrieval

<details>

* Version: 2.7.19
* GitHub: https://github.com/DOI-USGS/dataRetrieval
* Source code: https://github.com/cran/dataRetrieval
* Date/Publication: 2025-06-27 16:20:17 UTC
* Number of recursive dependencies: 84

Run `revdepcheck::cloud_details(, "dataRetrieval")` for more info

</details>

## Newly broken

*   checking whether package ‘dataRetrieval’ can be installed ... ERROR
    ```
    Installation failed.
    See ‘/tmp/workdir/dataRetrieval/new/dataRetrieval.Rcheck/00install.out’ for details.
    ```

## Installation

### Devel

```
* installing *source* package ‘dataRetrieval’ ...
** package ‘dataRetrieval’ successfully unpacked and MD5 sums checked
** using staged installation
** R
** inst
** byte-compile and prepare package for lazy loading
** help
*** installing help indices
*** copying figures
** building package indices
...
** installing vignettes
** testing if installed package can be loaded from temporary location
Error: package or namespace load failed for ‘dataRetrieval’:
 .onLoad failed in loadNamespace() for 'dataRetrieval', details:
  call: httr2::req_perform(check_endpoints_req)
  error: HTTP 404 Not Found.
Error: loading failed
Execution halted
ERROR: loading failed
* removing ‘/tmp/workdir/dataRetrieval/new/dataRetrieval.Rcheck/dataRetrieval’


```
### CRAN

```
* installing *source* package ‘dataRetrieval’ ...
** package ‘dataRetrieval’ successfully unpacked and MD5 sums checked
** using staged installation
** R
** inst
** byte-compile and prepare package for lazy loading
** help
*** installing help indices
*** copying figures
** building package indices
** installing vignettes
** testing if installed package can be loaded from temporary location
** testing if installed package can be loaded from final location
** testing if installed package keeps a record of temporary installation path
* DONE (dataRetrieval)


```
# feltr

<details>

* Version: 0.0.4
* GitHub: https://github.com/christopherkenny/feltr
* Source code: https://github.com/cran/feltr
* Date/Publication: 2023-11-05 20:30:02 UTC
* Number of recursive dependencies: 61

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
        5.   └─httr2::req_perform(req)
        6.     └─httptest2 (local) mock(req)
        7.       └─httptest2::build_mock_url(get_current_redactor()(req))
        8.         └─httptest2:::get_request_method(req)
        9.           └─utils::getFromNamespace("req_method_get", "httr2")
       10.             └─base::get(x, envir = ns, inherits = FALSE)
      
      [ FAIL 3 | WARN 0 | SKIP 1 | PASS 0 ]
      Error: Test failures
      Execution halted
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
       22. │                         └─httr2::req_perform(http_request)
       23. │                           └─httptest2 (local) mock(req)
       24. │                             └─httptest2::build_mock_url(get_current_redactor()(req))
       25. │                               └─httptest2:::get_request_method(req)
       26. │                                 └─utils::getFromNamespace("req_method_get", "httr2")
       27. │                                   └─base::get(x, envir = ns, inherits = FALSE)
       28. └─base::.handleSimpleError(...)
       29.   └─testthat (local) h(simpleError(msg, call))
       30.     └─rlang::abort(...)
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

# genesysr

<details>

* Version: 2.1.1
* GitHub: NA
* Source code: https://github.com/cran/genesysr
* Date/Publication: 2024-02-23 09:10:06 UTC
* Number of recursive dependencies: 52

Run `revdepcheck::cloud_details(, "genesysr")` for more info

</details>

## Newly broken

*   checking dependencies in R code ... WARNING
    ```
    Missing or unexported object: ‘httr2::req_stream’
    ```

# gptzeror

<details>

* Version: 0.0.1
* GitHub: https://github.com/christopherkenny/gptzeror
* Source code: https://github.com/cran/gptzeror
* Date/Publication: 2023-06-05 08:30:02 UTC
* Number of recursive dependencies: 44

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
        5.   └─httr2::req_perform(req)
        6.     └─httptest2 (local) mock(req)
        7.       └─httptest2::build_mock_url(get_current_redactor()(req))
        8.         └─httptest2:::get_request_method(req)
        9.           └─utils::getFromNamespace("req_method_get", "httr2")
       10.             └─base::get(x, envir = ns, inherits = FALSE)
      
      [ FAIL 2 | WARN 0 | SKIP 0 | PASS 0 ]
      Error: Test failures
      Execution halted
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
       17.         └─httr2::req_perform(...)
       18.           └─httptest2 (local) mock(req)
       19.             └─httptest2::build_mock_url(get_current_redactor()(req))
       20.               └─httptest2:::get_request_method(req)
       21.                 └─utils::getFromNamespace("req_method_get", "httr2")
       22.                   └─base::get(x, envir = ns, inherits = FALSE)
      
      [ FAIL 7 | WARN 0 | SKIP 54 | PASS 42 ]
      Error: Test failures
      Execution halted
    ```

# hackeRnews

<details>

* Version: 0.2.1
* GitHub: https://github.com/szymanskir/hackeRnews
* Source code: https://github.com/cran/hackeRnews
* Date/Publication: 2025-04-08 07:10:02 UTC
* Number of recursive dependencies: 61

Run `revdepcheck::cloud_details(, "hackeRnews")` for more info

</details>

## Newly broken

*   checking tests ... ERROR
    ```
      Running ‘spelling.R’
      Running ‘testthat.R’
    Running the tests in ‘tests/testthat.R’ failed.
    Complete output:
      > library(testthat)
      > library(hackeRnews)
      > 
      > test_check("hackeRnews")
      [ FAIL 21 | WARN 0 | SKIP 0 | PASS 3 ]
      
    ...
       12.     └─httr2::req_perform(request)
       13.       └─httptest2 (local) mock(req)
       14.         └─httptest2::build_mock_url(get_current_redactor()(req))
       15.           └─httptest2:::get_request_method(req)
       16.             └─utils::getFromNamespace("req_method_get", "httr2")
       17.               └─base::get(x, envir = ns, inherits = FALSE)
      
      [ FAIL 21 | WARN 0 | SKIP 0 | PASS 3 ]
      Error: Test failures
      Execution halted
    ```

# hakaiApi

<details>

* Version: 1.0.3
* GitHub: https://github.com/HakaiInstitute/hakai-api-client-r
* Source code: https://github.com/cran/hakaiApi
* Date/Publication: 2025-05-27 23:10:05 UTC
* Number of recursive dependencies: 67

Run `revdepcheck::cloud_details(, "hakaiApi")` for more info

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
      `expected` is a character vector ('detoo')
      ── Failure ('test-utils.R:28:3'): base_request uses user agent from environment variable ──
      req$headers$Authorization (`actual`) not equal to "detoo" (`expected`).
      
      `actual` is a weak reference
      `expected` is a character vector ('detoo')
      
      [ FAIL 2 | WARN 0 | SKIP 0 | PASS 29 ]
      Error: Test failures
      Execution halted
    ```

# happign

<details>

* Version: 0.3.3
* GitHub: https://github.com/paul-carteron/happign
* Source code: https://github.com/cran/happign
* Date/Publication: 2025-03-28 12:50:05 UTC
* Number of recursive dependencies: 123

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
       10.   └─httr2::req_perform(req)
       11.     └─httptest2 (local) mock(req)
       12.       └─httptest2::build_mock_url(get_current_redactor()(req))
       13.         └─httptest2:::get_request_method(req)
       14.           └─utils::getFromNamespace("req_method_get", "httr2")
       15.             └─base::get(x, envir = ns, inherits = FALSE)
      
      [ FAIL 4 | WARN 0 | SKIP 39 | PASS 81 ]
      Error: Test failures
      Execution halted
    ```

## In both

*   checking data for non-ASCII characters ... NOTE
    ```
      Note: found 15185 marked UTF-8 strings
    ```

# httptest2

<details>

* Version: 1.2.0
* GitHub: https://github.com/nealrichardson/httptest2
* Source code: https://github.com/cran/httptest2
* Date/Publication: 2025-06-27 19:20:02 UTC
* Number of recursive dependencies: 53

Run `revdepcheck::cloud_details(, "httptest2")` for more info

</details>

## Newly broken

*   checking examples ... ERROR
    ```
    Running examples in ‘httptest2-Ex.R’ failed
    The error most likely occurred in:
    
    > ### Name: expect_verb
    > ### Title: Expectations for mocked HTTP requests
    > ### Aliases: expect_verb expect_GET expect_POST expect_PUT expect_PATCH
    > ###   expect_DELETE expect_no_request
    > 
    > ### ** Examples
    > 
    ...
    +       req_method("PUT") %>%
    +       req_body_json(list(a = 1)) %>%
    +       req_perform()
    +   )
    +   expect_no_request(rnorm(5))
    + })
    Error in get(x, envir = ns, inherits = FALSE) : 
      object 'req_method_get' not found
    Calls: without_internet ... get_request_method -> <Anonymous> -> get -> .handleSimpleError -> h
    Execution halted
    ```

*   checking tests ... ERROR
    ```
      Running ‘spelling.R’
      Running ‘testthat.R’
    Running the tests in ‘tests/testthat.R’ failed.
    Complete output:
      > library(testthat)
      > test_check("httptest2")
      Loading required package: httptest2
      Using redact.R from "testpkg"
      [ FAIL 43 | WARN 4 | SKIP 0 | PASS 95 ]
      
    ...
       13. │   ├─base::paste(get_request_method(req), req$url)
       14. │   └─httptest2:::get_request_method(req)
       15. │     └─utils::getFromNamespace("req_method_get", "httr2")
       16. │       └─base::get(x, envir = ns, inherits = FALSE)
       17. └─base::.handleSimpleError(...)
       18.   └─httptest2 (local) h(simpleError(msg, call))
      
      [ FAIL 43 | WARN 4 | SKIP 0 | PASS 95 ]
      Error: Test failures
      Execution halted
    ```

*   checking dependencies in R code ... WARNING
    ```
    Missing or unexported object: ‘httr2::with_mock’
    ```

# insight

<details>

* Version: 1.3.1
* GitHub: https://github.com/easystats/insight
* Source code: https://github.com/cran/insight
* Date/Publication: 2025-06-30 22:10:02 UTC
* Number of recursive dependencies: 429

Run `revdepcheck::cloud_details(, "insight")` for more info

</details>

## Newly broken

*   checking tests ... ERROR
    ```
      Running ‘testthat.R’
    Running the tests in ‘tests/testthat.R’ failed.
    Complete output:
      > library(testthat)
      > library(insight)
      > test_check("insight")
      Starting 2 test processes
      [ FAIL 1 | WARN 0 | SKIP 85 | PASS 3491 ]
      
      ══ Skipped tests (85) ══════════════════════════════════════════════════════════
    ...
      • works interactively (2): 'test-coxph-panel.R:34:3', 'test-coxph.R:38:3'
      • {bigglm} is not installed (1): 'test-model_info.R:24:3'
      
      ══ Failed tests ════════════════════════════════════════════════════════════════
      ── Failure ('test-download_model.R:7:5'): we can successfully get existing model ──
      `model` is not an S3 object
      
      [ FAIL 1 | WARN 0 | SKIP 85 | PASS 3491 ]
      Error: Test failures
      Execution halted
    ```

# lgrExtra

<details>

* Version: 0.1.0
* GitHub: NA
* Source code: https://github.com/cran/lgrExtra
* Date/Publication: 2025-06-20 19:20:02 UTC
* Number of recursive dependencies: 87

Run `revdepcheck::cloud_details(, "lgrExtra")` for more info

</details>

## Newly broken

*   checking tests ... ERROR
    ```
      Running ‘testthat.R’
    Running the tests in ‘tests/testthat.R’ failed.
    Complete output:
      > library(testthat)
      > library(lgrExtra)
      > 
      > test_check("lgrExtra")
      [ FAIL 1 | WARN 0 | SKIP 6 | PASS 113 ]
      
      ══ Skipped tests (6) ═══════════════════════════════════════════════════════════
    ...
        'test_AppenderDbi.R:251:7'
      
      ══ Failed tests ════════════════════════════════════════════════════════════════
      ── Failure ('test_AppenderDynatrace.R:34:3'): AppenderDynatrace: appending works ──
      sent_request$headers[["Authorization"]] not identical to "Api-Token hashbaz".
      target is weakref, current is character
      
      [ FAIL 1 | WARN 0 | SKIP 6 | PASS 113 ]
      Error: Test failures
      Execution halted
    ```

# mmequiv

<details>

* Version: 1.0.0
* GitHub: https://github.com/KennethATaylor/mmequiv
* Source code: https://github.com/cran/mmequiv
* Date/Publication: 2025-05-19 23:50:03 UTC
* Number of recursive dependencies: 48

Run `revdepcheck::cloud_details(, "mmequiv")` for more info

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
       2.   └─httr2::req_perform(req)
       3.     └─httptest2 (local) mock(req)
       4.       └─httptest2::build_mock_url(get_current_redactor()(req))
       5.         └─httptest2:::get_request_method(req)
       6.           └─utils::getFromNamespace("req_method_get", "httr2")
       7.             └─base::get(x, envir = ns, inherits = FALSE)
      
      [ FAIL 12 | WARN 0 | SKIP 15 | PASS 29 ]
      Error: Test failures
      Execution halted
    ```

# MolgenisArmadillo

<details>

* Version: 2.9.1
* GitHub: https://github.com/molgenis/molgenis-r-armadillo
* Source code: https://github.com/cran/MolgenisArmadillo
* Date/Publication: 2025-06-13 13:10:02 UTC
* Number of recursive dependencies: 83

Run `revdepcheck::cloud_details(, "MolgenisArmadillo")` for more info

</details>

## Newly broken

*   checking tests ... ERROR
    ```
      Running ‘testthat.R’
    Running the tests in ‘tests/testthat.R’ failed.
    Complete output:
      > library(testthat)
      > library(tibble)
      > library(MolgenisArmadillo)
      > library(webmockr)
      > 
      > test_check("MolgenisArmadillo")
      crul not installed, skipping enable
    ...
        5.         └─waldo:::compare_structure(x, y, paths = c(x_arg, y_arg), opts = opts)
        6.           └─waldo:::compare_by_name(x, y, paths, opts)
        7.             └─waldo:::compare_structure(...)
        8.               └─waldo:::compare_by_name(x, y, paths, opts)
        9.                 └─waldo:::compare_structure(...)
       10.                   └─rlang::abort(...)
      
      [ FAIL 1 | WARN 4 | SKIP 0 | PASS 241 ]
      Error: Test failures
      Execution halted
    ```

# nixtlar

<details>

* Version: 0.6.2
* GitHub: https://github.com/Nixtla/nixtlar
* Source code: https://github.com/cran/nixtlar
* Date/Publication: 2024-10-28 23:10:02 UTC
* Number of recursive dependencies: 91

Run `revdepcheck::cloud_details(, "nixtlar")` for more info

</details>

## Newly broken

*   checking re-building of vignette outputs ... ERROR
    ```
    Error(s) in re-building vignettes:
    --- re-building ‘anomaly-detection.Rmd’ using rmarkdown
    
    Quitting from anomaly-detection.Rmd:50-53 [unnamed-chunk-3]
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    <error/rlang_error>
    Error in `get()`:
    ! object 'req_method_get' not found
    ---
    Backtrace:
    ...
    --- failed re-building ‘special-topics.Rmd’
    
    SUMMARY: processing the following files failed:
      ‘anomaly-detection.Rmd’ ‘azure-quickstart.Rmd’ ‘cross-validation.Rmd’
      ‘exogenous-variables.Rmd’ ‘get-started.Rmd’ ‘historical-forecast.Rmd’
      ‘long-horizon.Rmd’ ‘prediction-intervals.Rmd’ ‘quantiles.Rmd’
      ‘special-topics.Rmd’
    
    Error: Vignette re-building failed.
    Execution halted
    ```

# openeo

<details>

* Version: 1.4.0
* GitHub: https://github.com/Open-EO/openeo-r-client
* Source code: https://github.com/cran/openeo
* Date/Publication: 2025-05-13 20:00:01 UTC
* Number of recursive dependencies: 98

Run `revdepcheck::cloud_details(, "openeo")` for more info

</details>

## Newly broken

*   checking whether package ‘openeo’ can be installed ... WARNING
    ```
    Found the following significant warnings:
      Note: possible error in 'oauth_flow_auth_code(client = private$oauth_client, ': unused argument (port = 1410) 
    See ‘/tmp/workdir/openeo/new/openeo.Rcheck/00install.out’ for details.
    Information on the location(s) of code generating the ‘Note’s can be
    obtained by re-running with environment variable R_KEEP_PKG_SOURCE set
    to ‘yes’.
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
        9.   └─httr2::req_perform(req)
       10.     └─httptest2 (local) mock(req)
       11.       └─httptest2::build_mock_url(get_current_redactor()(req))
       12.         └─httptest2:::get_request_method(req)
       13.           └─utils::getFromNamespace("req_method_get", "httr2")
       14.             └─base::get(x, envir = ns, inherits = FALSE)
      
      [ FAIL 52 | WARN 0 | SKIP 0 | PASS 119 ]
      Error: Test failures
      Execution halted
    ```

# osmdata

<details>

* Version: 0.2.5
* GitHub: https://github.com/ropensci/osmdata
* Source code: https://github.com/cran/osmdata
* Date/Publication: 2023-08-14 11:40:08 UTC
* Number of recursive dependencies: 85

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
      [ FAIL 10 | WARN 0 | SKIP 0 | PASS 513 ]
      
    ...
       12.         └─httr2::req_perform(req)
       13.           └─httptest2 (local) mock(req)
       14.             └─httptest2::build_mock_url(get_current_redactor()(req))
       15.               └─httptest2:::get_request_method(req)
       16.                 └─utils::getFromNamespace("req_method_get", "httr2")
       17.                   └─base::get(x, envir = ns, inherits = FALSE)
      
      [ FAIL 10 | WARN 0 | SKIP 0 | PASS 513 ]
      Error: Test failures
      Execution halted
    ```

## In both

*   checking installed package size ... NOTE
    ```
      installed size is 15.4Mb
      sub-directories of 1Mb or more:
        doc    5.0Mb
        libs   9.8Mb
    ```

# planscorer

<details>

* Version: 0.0.2
* GitHub: https://github.com/christopherkenny/planscorer
* Source code: https://github.com/cran/planscorer
* Date/Publication: 2024-09-24 14:50:02 UTC
* Number of recursive dependencies: 81

Run `revdepcheck::cloud_details(, "planscorer")` for more info

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
        5.   └─httr2::req_perform(req)
        6.     └─httptest2 (local) mock(req)
        7.       └─httptest2::build_mock_url(get_current_redactor()(req))
        8.         └─httptest2:::get_request_method(req)
        9.           └─utils::getFromNamespace("req_method_get", "httr2")
       10.             └─base::get(x, envir = ns, inherits = FALSE)
      
      [ FAIL 3 | WARN 0 | SKIP 0 | PASS 2 ]
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
      [ FAIL 6 | WARN 0 | SKIP 9 | PASS 0 ]
      
      ══ Skipped tests (9) ═══════════════════════════════════════════════════════════
    ...
       13. └─httr2::req_perform(.)
       14.   └─httptest2 (local) mock(req)
       15.     └─httptest2::build_mock_url(get_current_redactor()(req))
       16.       └─httptest2:::get_request_method(req)
       17.         └─utils::getFromNamespace("req_method_get", "httr2")
       18.           └─base::get(x, envir = ns, inherits = FALSE)
      
      [ FAIL 6 | WARN 0 | SKIP 9 | PASS 0 ]
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
       2.   └─httr2::req_perform(...)
       3.     └─httptest2 (local) mock(req)
       4.       └─httptest2::build_mock_url(get_current_redactor()(req))
       5.         └─httptest2:::get_request_method(req)
       6.           └─utils::getFromNamespace("req_method_get", "httr2")
       7.             └─base::get(x, envir = ns, inherits = FALSE)
      
      [ FAIL 32 | WARN 0 | SKIP 8 | PASS 40 ]
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
        7.     ├─httptest2::save_response(...)
        8.     │ └─base::file.path(.mockPaths()[1], file)
        9.     └─httptest2::build_mock_url(redactor(req))
       10.       └─httptest2:::get_request_method(req)
       11.         └─utils::getFromNamespace("req_method_get", "httr2")
       12.           └─base::get(x, envir = ns, inherits = FALSE)
      
      [ FAIL 10 | WARN 0 | SKIP 2 | PASS 65 ]
      Error: Test failures
      Execution halted
    ```

# rosv

<details>

* Version: 0.5.1
* GitHub: https://github.com/al-obrien/rosv
* Source code: https://github.com/cran/rosv
* Date/Publication: 2023-12-04 17:40:02 UTC
* Number of recursive dependencies: 55

Run `revdepcheck::cloud_details(, "rosv")` for more info

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
       21.         └─httr2::req_perform(reqs[[i]], path = paths[[i]], mock = mock)
       22.           └─httptest2 (local) mock(req)
       23.             └─httptest2::build_mock_url(get_current_redactor()(req))
       24.               └─httptest2:::get_request_method(req)
       25.                 └─utils::getFromNamespace("req_method_get", "httr2")
       26.                   └─base::get(x, envir = ns, inherits = FALSE)
      
      [ FAIL 8 | WARN 0 | SKIP 1 | PASS 42 ]
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
      ── Failure ('test_api_ollama.R:59:3'): ollama_embedding function constructs a correct request and dry runs it ──
      Names of `dry_run` ('method', 'path', 'body', 'headers') don't match 'method', 'path', 'headers'
      ── Failure ('test_api_openai.R:17:3'): openai function constructs a correct request and dry runs it ──
      Names of `dry_run` ('method', 'path', 'body', 'headers') don't match 'method', 'path', 'headers'
      ── Failure ('test_api_perplexity.R:15:3'): perplexity function constructs a correct request and dry runs it ──
      Names of `dry_run` ('method', 'path', 'body', 'headers') don't match 'method', 'path', 'headers'
      
      [ FAIL 11 | WARN 0 | SKIP 0 | PASS 269 ]
      Error: Test failures
      Execution halted
    ```

