# CopernicusMarine (0.4.7)

* GitHub: <https://github.com/pepijn-devries/CopernicusMarine>
* Email: <mailto:pepijn.devries@outlook.com>
* GitHub mirror: <https://github.com/cran/CopernicusMarine>

Run `revdepcheck::cloud_details(, "CopernicusMarine")` for more info

## Newly broken

*   checking examples ... ERROR
     ```
     ...
     The error most likely occurred in:
     
     > ### Name: cms_cite_product
     > ### Title: How to cite a Copernicus marine product
     > ### Aliases: cms_cite_product
     > 
     > ### ** Examples
     > 
     > cms_cite_product("SST_MED_PHY_SUBSKIN_L4_NRT_010_036")
     Error in `httr2::req_perform()`:
     ! Failed to perform HTTP request.
     Caused by error in `curl::curl_fetch_memory()`:
     ! Timeout was reached [s3.waw3-1.cloudferro.com]:
     Failed to connect to s3.waw3-1.cloudferro.com port 443 after 10002 ms: Timeout was reached
     Backtrace:
         ▆
      1. └─CopernicusMarine::cms_cite_product("SST_MED_PHY_SUBSKIN_L4_NRT_010_036")
      2.   └─CopernicusMarine::cms_product_details(product)
      3.     ├─httr2::resp_body_json(httr2::req_perform(httr2::request(product_url)))
      4.     │ └─httr2:::check_response(resp)
      5.     │   └─httr2:::is_response(resp)
      6.     └─httr2::req_perform(httr2::request(product_url))
      7.       └─httr2:::handle_resp(req, resp, error_call = error_call)
      8.         └─rlang::cnd_signal(resp)
     Execution halted
     ```

*   checking re-building of vignette outputs ... ERROR
     ```
     ...
      2. └─CopernicusMarine::cms_products_list2()
      3.   ├─httr2::resp_body_json(httr2::req_perform(httr2::request(clients$catalogues[[1]]$idMapping)))
      4.   │ └─httr2:::check_response(resp)
      5.   │   └─httr2:::is_response(resp)
      6.   └─httr2::req_perform(httr2::request(clients$catalogues[[1]]$idMapping))
     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     
     Error: processing vignette 'product-info.Rmd' failed with diagnostics:
     Failed to perform HTTP request.
     Caused by error in `curl::curl_fetch_memory()`:
     ! Timeout was reached [s3.waw3-1.cloudferro.com]:
     Failed to connect to s3.waw3-1.cloudferro.com port 443 after 10002 ms: Timeout was reached
     --- failed re-building ‘product-info.Rmd’
     
     --- re-building ‘proxy.Rmd’ using rmarkdown
     --- finished re-building ‘proxy.Rmd’
     
     --- re-building ‘translate.Rmd’ using rmarkdown
     --- finished re-building ‘translate.Rmd’
     
     SUMMARY: processing the following file failed:
       ‘product-info.Rmd’
     
     Error: Vignette re-building failed.
     Execution halted
     ```

