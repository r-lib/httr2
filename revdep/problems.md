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
      [ FAIL 2 | WARN 0 | SKIP 2 | PASS 237 ]
      
      ══ Skipped tests (2) ═══════════════════════════════════════════════════════════
    ...
        9. │         └─rlang::eval_bare(quo_get_expr(.quo), quo_get_env(.quo))
       10. ├─r %>% req_body_file(file_to_upload) %>% req_perform()
       11. └─httr2::req_perform(.)
       12.   └─httptest2 (local) mock(req)
       13.     └─httptest2:::stop_request(req)
       14.       └─rlang::abort(out, mockfile = req$mockfile, class = "httptest2_request")
      
      [ FAIL 2 | WARN 0 | SKIP 2 | PASS 237 ]
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
       10. │   └─rlang::eval_bare(expr, quo_get_env(quo))
       11. └─osmapiR::osm_set_preferences_user(all_prefs = preferences)
       12.   └─httr2::req_perform(req)
       13.     └─httptest2 (local) mock(req)
       14.       └─httptest2:::stop_request(req)
       15.         └─rlang::abort(out, mockfile = req$mockfile, class = "httptest2_request")
      
      [ FAIL 8 | WARN 0 | SKIP 13 | PASS 1760 ]
      Error: Test failures
      Execution halted
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
       3.   │ └─httr2:::check_response(resp)
       4.   │   └─httr2:::is_response(resp)
       5.   └─httr2::req_perform(req)
       6.     └─httptest2 (local) mock(req)
       7.       └─httptest2:::stop_request(req)
       8.         └─rlang::abort(out, mockfile = req$mockfile, class = "httptest2_request")
      
      [ FAIL 1 | WARN 0 | SKIP 0 | PASS 4 ]
      Error: Test failures
      Execution halted
    ```

# spanishoddata

<details>

* Version: 0.2.0
* GitHub: https://github.com/rOpenSpain/spanishoddata
* Source code: https://github.com/cran/spanishoddata
* Date/Publication: 2025-06-15 23:20:02 UTC
* Number of recursive dependencies: 162

Run `revdepcheck::cloud_details(, "spanishoddata")` for more info

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
      Error in ``$<-`(`*tmp*`, "remote_file_size_mb", value = numeric(0))`: Assigned data `round(files_table$file_size_bytes/1024^2, 2)` must be compatible with existing data.
      x Existing data has 1872 rows.
      x Assigned data has 0 rows.
      i Only vectors of size 1 are recycled.
      Caused by error in `vectbl_recycle_rhs_rows()`:
      ! Can't recycle input of size 0 to size 1872.
      
      [ FAIL 10 | WARN 10 | SKIP 1 | PASS 7 ]
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

