# atrrr

<details>

* Version: 0.0.4
* GitHub: https://github.com/JBGruber/atrrr
* Source code: https://github.com/cran/atrrr
* Date/Publication: 2024-10-03 12:50:03 UTC
* Number of recursive dependencies: 98

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
       22.       │   └─httr2:::check_string(url, call = error_call)
       23.       │     └─httr2:::.rlang_check_is_string(...)
       24.       │       └─rlang::is_string(x)
       25.       └─httr2::url_build(url = list(scheme = "https", hostname = hostname, query = as.list(all_params)))
       26.         └─httr2:::stop_input_type(url, "a parsed URL")
       27.           └─rlang::abort(message, ..., call = call, arg = arg)
      
      [ FAIL 82 | WARN 0 | SKIP 2 | PASS 50 ]
      Error: Test failures
      Execution halted
    ```

# brickster

<details>

* Version: 0.2.5
* GitHub: https://github.com/databrickslabs/brickster
* Source code: https://github.com/cran/brickster
* Date/Publication: 2024-11-13 14:10:06 UTC
* Number of recursive dependencies: 76

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
      [ FAIL 26 | WARN 0 | SKIP 18 | PASS 241 ]
      
    ...
          ▆
       1. └─brickster::db_workspace_list(path = "some_path", perform_request = F) at test-workspace-folder.R:8:3
       2.   ├─brickster:::db_request(...)
       3.   └─brickster::db_host()
       4.     └─httr2::url_parse(host)
       5.       └─curl::curl_parse_url(url, baseurl = base_url)
      
      [ FAIL 26 | WARN 0 | SKIP 18 | PASS 241 ]
      Error: Test failures
      Execution halted
    ```

## In both

*   checking running R code from vignettes ... ERROR
    ```
    Errors in running code in vignettes:
    when running code in ‘cluster-management.Rmd’
      ...
    
    > library(brickster)
    
    > new_cluster <- db_cluster_create(name = "brickster-cluster", 
    +     spark_version = "9.1.x-scala2.12", num_workers = 2, node_type_id = "m5a.xlarge", .... [TRUNCATED] 
    
      When sourcing ‘cluster-management.R’:
    ...
    
      When sourcing ‘setup-auth.R’:
    Error: Environment variable `DATABRICKS_HOST` not found:
    ✖ Need to specify `DATABRICKS_HOST` environment variable.
    Execution halted
    
      ‘cluster-management.Rmd’ using ‘UTF-8’... failed
      ‘managing-jobs.Rmd’ using ‘UTF-8’... failed
      ‘remote-repl.Rmd’ using ‘UTF-8’... failed
      ‘setup-auth.Rmd’ using ‘UTF-8’... failed
    ```

# bskyr

<details>

* Version: 0.1.2
* GitHub: https://github.com/christopherkenny/bskyr
* Source code: https://github.com/cran/bskyr
* Date/Publication: 2024-01-09 21:00:09 UTC
* Number of recursive dependencies: 57

Run `revdepcheck::cloud_details(, "bskyr")` for more info

</details>

## Newly broken

*   checking examples ... ERROR
    ```
    Running examples in ‘bskyr-Ex.R’ failed
    The error most likely occurred in:
    
    > ### Name: bs_uri_to_url
    > ### Title: Convert Universal Resource Identifiers to Hypertext Transfer
    > ###   Protocol Secure URLs
    > ### Aliases: bs_uri_to_url
    > 
    > ### ** Examples
    > 
    > bs_uri_to_url('at://did:plc:ic6zqvuw5ulmfpjiwnhsr2ns/app.bsky.feed.post/3k7qmjev5lr2s')
    Error in curl::curl_parse_url(url, baseurl = base_url) : 
      Failed to parse URL: Port number was not a decimal number between 0 and 65535
    Calls: bs_uri_to_url -> <Anonymous> -> <Anonymous>
    Execution halted
    ```

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
       1. ├─testthat::expect_equal(...) at test-url_uri.R:2:3
       2. │ └─testthat::quasi_label(enquo(object), label, arg = "object")
       3. │   └─rlang::eval_bare(expr, quo_get_env(quo))
       4. └─bskyr::bs_uri_to_url("at://did:plc:ic6zqvuw5ulmfpjiwnhsr2ns/app.bsky.feed.post/3k7qmjev5lr2s")
       5.   └─httr2::url_parse(uri)
       6.     └─curl::curl_parse_url(url, baseurl = base_url)
      
      [ FAIL 1 | WARN 0 | SKIP 0 | PASS 53 ]
      Error: Test failures
      Execution halted
    ```

# chattr

<details>

* Version: 0.2.0
* GitHub: https://github.com/mlverse/chattr
* Source code: https://github.com/cran/chattr
* Date/Publication: 2024-07-29 15:40:02 UTC
* Number of recursive dependencies: 73

Run `revdepcheck::cloud_details(, "chattr")` for more info

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
       8.     └─curl::curl_parse_url(url, baseurl = base_url)
      
      [ FAIL 1 | WARN 0 | SKIP 33 | PASS 41 ]
      Deleting unused snapshots:
      • app-server/001.json
      • app-server/002.json
      • app-server/003.json
      • app-server/004.json
      Error: Test failures
      Execution halted
    ```

# healthyR.data

<details>

* Version: 1.1.1
* GitHub: https://github.com/spsanderson/healthyR.data
* Source code: https://github.com/cran/healthyR.data
* Date/Publication: 2024-07-04 11:50:02 UTC
* Number of recursive dependencies: 32

Run `revdepcheck::cloud_details(, "healthyR.data")` for more info

</details>

## Newly broken

*   checking examples ... ERROR
    ```
    Running examples in ‘healthyR.data-Ex.R’ failed
    The error most likely occurred in:
    
    > ### Name: fetch_provider_data
    > ### Title: Fetch Provider Data as Tibble or Download CSV
    > ### Aliases: fetch_provider_data
    > 
    > ### ** Examples
    > 
    > library(dplyr)
    ...
    
    > 
    > # Example usage:
    > data_url <- "069d-826b"
    > 
    > df_tbl <- fetch_provider_data(data_url, .limit = 1)
    Error in curl::curl_parse_url(url, baseurl = base_url) : 
      Failed to parse URL: Bad scheme
    Calls: fetch_provider_data -> is_valid_url -> <Anonymous> -> <Anonymous>
    Execution halted
    ```

