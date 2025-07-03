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

*   checking tests ... ERROR
    ```
      Running ‘spelling.R’
      Running ‘testthat.R’
    Running the tests in ‘tests/testthat.R’ failed.
    Complete output:
      > library(testthat)
      > test_check("httptest2")
      Loading required package: httptest2
      [ FAIL 1 | WARN 0 | SKIP 2 | PASS 237 ]
      
      ══ Skipped tests (2) ═══════════════════════════════════════════════════════════
    ...
        6.     └─httptest2:::get_string_request_body(req)
        7.       └─httr2 (local) body_apply(req)
        8.         └─httr2::req_get_body_type(req = req)
        9.           └─httr2:::check_request(req)
       10.             └─httr2:::stop_input_type(...)
       11.               └─rlang::abort(message, ..., call = call, arg = arg)
      
      [ FAIL 1 | WARN 0 | SKIP 2 | PASS 237 ]
      Error: Test failures
      Execution halted
    ```

*   checking dependencies in R code ... WARNING
    ```
    Missing or unexported object: ‘httr2::with_mock’
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
       19.       │ ├─base::tryCatch(...)
       20.       │ │ └─base (local) tryCatchList(expr, classes, parentenv, handlers)
       21.       │ │   └─base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
       22.       │ │     └─base (local) doTryCatch(return(expr), name, parentenv, handler)
       23.       │ └─base::force(expr)
       24.       └─rlang::abort(...)
      
      [ FAIL 3 | WARN 0 | SKIP 13 | PASS 1821 ]
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

