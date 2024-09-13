# arcgisgeocode

<details>

* Version: 0.2.1
* GitHub: https://github.com/r-arcgis/arcgisgeocode
* Source code: https://github.com/cran/arcgisgeocode
* Date/Publication: 2024-08-02 12:30:02 UTC
* Number of recursive dependencies: 64

Run `revdepcheck::cloud_details(, "arcgisgeocode")` for more info

</details>

## Newly broken

*   checking examples ... ERROR
    ```
    Running examples in ‘arcgisgeocode-Ex.R’ failed
    The error most likely occurred in:
    
    > ### Name: reverse_geocode
    > ### Title: Reverse Geocode Locations
    > ### Aliases: reverse_geocode
    > 
    > ### ** Examples
    > 
    > # Find addresses from locations
    ...
        ▆
     1. └─arcgisgeocode::reverse_geocode(c(-117.172, 34.052))
     2.   └─httr2::resps_data(all_resps, httr2::resp_body_string)
     3.     ├─vctrs::list_unchop(lapply(resps, resp_data))
     4.     └─base::lapply(resps, resp_data)
     5.       └─httr2 (local) FUN(resp = X[[i]])
     6.         └─httr2:::check_response(resp)
     7.           └─httr2:::stop_input_type(...)
     8.             └─rlang::abort(message, ..., call = call, arg = arg)
    Execution halted
    ```

## In both

*   checking installed package size ... NOTE
    ```
      installed size is  6.8Mb
      sub-directories of 1Mb or more:
        libs   6.5Mb
    ```

*   checking R code for possible problems ... NOTE
    ```
    sort_asap: no visible global function definition for ‘sort_by’
    Undefined global functions or variables:
      sort_by
    ```

