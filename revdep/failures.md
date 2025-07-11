# arcgisplaces

<details>

* Version: 0.1.2
* GitHub: NA
* Source code: https://github.com/cran/arcgisplaces
* Date/Publication: 2025-04-10 16:20:02 UTC
* Number of recursive dependencies: 42

Run `revdepcheck::cloud_details(, "arcgisplaces")` for more info

</details>

## In both

*   checking whether package ‘arcgisplaces’ can be installed ... ERROR
    ```
    Installation failed.
    See ‘/tmp/workdir/arcgisplaces/new/arcgisplaces.Rcheck/00install.out’ for details.
    ```

## Installation

### Devel

```
* installing *source* package ‘arcgisplaces’ ...
** package ‘arcgisplaces’ successfully unpacked and MD5 sums checked
** using staged installation
Using cargo 1.75.0
Using rustc 1.75.0 (82e1608df 2023-12-21) (built from a source tarball)
Building for CRAN.
Writing `src/Makevars`.
`tools/config.R` has finished.
** libs
using C compiler: ‘gcc (Ubuntu 13.3.0-6ubuntu2~24.04) 13.3.0’
...
export CARGO_HOME=/tmp/workdir/arcgisplaces/new/arcgisplaces.Rcheck/00_pkg_src/arcgisplaces/src/.cargo && \
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.cargo/bin" && \
RUSTFLAGS=" --print=native-static-libs" cargo build -j 2 --offline --lib --release --manifest-path=./rust/Cargo.toml --target-dir ./rust/target
error: package `zerofrom v0.1.6` cannot be built because it requires rustc 1.81 or newer, while the currently active rustc version is 1.75.0
Either upgrade to rustc 1.81 or newer, or use
cargo update zerofrom@0.1.6 --precise ver
where `ver` is the latest version of `zerofrom` supporting rustc 1.75.0
make: *** [Makevars:28: rust/target/release/libarcgisplaces.a] Error 101
ERROR: compilation failed for package ‘arcgisplaces’
* removing ‘/tmp/workdir/arcgisplaces/new/arcgisplaces.Rcheck/arcgisplaces’


```
### CRAN

```
* installing *source* package ‘arcgisplaces’ ...
** package ‘arcgisplaces’ successfully unpacked and MD5 sums checked
** using staged installation
Using cargo 1.75.0
Using rustc 1.75.0 (82e1608df 2023-12-21) (built from a source tarball)
Building for CRAN.
Writing `src/Makevars`.
`tools/config.R` has finished.
** libs
using C compiler: ‘gcc (Ubuntu 13.3.0-6ubuntu2~24.04) 13.3.0’
...
export CARGO_HOME=/tmp/workdir/arcgisplaces/old/arcgisplaces.Rcheck/00_pkg_src/arcgisplaces/src/.cargo && \
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.cargo/bin" && \
RUSTFLAGS=" --print=native-static-libs" cargo build -j 2 --offline --lib --release --manifest-path=./rust/Cargo.toml --target-dir ./rust/target
error: package `litemap v0.7.5` cannot be built because it requires rustc 1.81 or newer, while the currently active rustc version is 1.75.0
Either upgrade to rustc 1.81 or newer, or use
cargo update litemap@0.7.5 --precise ver
where `ver` is the latest version of `litemap` supporting rustc 1.75.0
make: *** [Makevars:28: rust/target/release/libarcgisplaces.a] Error 101
ERROR: compilation failed for package ‘arcgisplaces’
* removing ‘/tmp/workdir/arcgisplaces/old/arcgisplaces.Rcheck/arcgisplaces’


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
