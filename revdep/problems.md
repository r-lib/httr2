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

## Newly fixed

*   checking re-building of vignette outputs ... ERROR
    ```
    Error(s) in re-building vignettes:
    --- re-building ‘dataRetrieval.Rmd’ using rmarkdown
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
# eudata

<details>

* Version: 0.1.2
* GitHub: https://github.com/prokaj/eudata
* Source code: https://github.com/cran/eudata
* Date/Publication: 2025-07-09 11:00:03 UTC
* Number of recursive dependencies: 66

Run `revdepcheck::cloud_details(, "eudata")` for more info

</details>

## Newly broken

*   checking whether package ‘eudata’ can be installed ... ERROR
    ```
    Installation failed.
    See ‘/tmp/workdir/eudata/new/eudata.Rcheck/00install.out’ for details.
    ```

## Installation

### Devel

```
* installing *source* package ‘eudata’ ...
** package ‘eudata’ successfully unpacked and MD5 sums checked
** using staged installation
** R
** inst
** byte-compile and prepare package for lazy loading
Error: object ‘req_stream’ is not exported by 'namespace:httr2'
Execution halted
ERROR: lazy loading failed for package ‘eudata’
* removing ‘/tmp/workdir/eudata/new/eudata.Rcheck/eudata’


```
### CRAN

```
* installing *source* package ‘eudata’ ...
** package ‘eudata’ successfully unpacked and MD5 sums checked
** using staged installation
** R
** inst
** byte-compile and prepare package for lazy loading
** help
*** installing help indices
** building package indices
** installing vignettes
** testing if installed package can be loaded from temporary location
** testing if installed package can be loaded from final location
** testing if installed package keeps a record of temporary installation path
* DONE (eudata)


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

