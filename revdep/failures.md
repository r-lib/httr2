# arcgisplaces (0.1.2)

* Email: <mailto:josiah.parry@gmail.com>
* GitHub mirror: <https://github.com/cran/arcgisplaces>

Run `revdepcheck::cloud_details(, "arcgisplaces")` for more info

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
** this is package ‘arcgisplaces’ version ‘0.1.2’
** package ‘arcgisplaces’ successfully unpacked and MD5 sums checked
** using staged installation
Using cargo 1.75.0
Using rustc 1.75.0 (82e1608df 2023-12-21) (built from a source tarball)
Building for CRAN.
Writing `src/Makevars`.
`tools/config.R` has finished.
** libs
...
export CARGO_HOME=/tmp/workdir/arcgisplaces/new/arcgisplaces.Rcheck/00_pkg_src/arcgisplaces/src/.cargo && \
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/tmp/home/.cargo/bin" && \
RUSTFLAGS=" --print=native-static-libs" cargo build -j 2 --offline --lib --release --manifest-path=./rust/Cargo.toml --target-dir ./rust/target
error: package `litemap v0.7.5` cannot be built because it requires rustc 1.81 or newer, while the currently active rustc version is 1.75.0
Either upgrade to rustc 1.81 or newer, or use
cargo update litemap@0.7.5 --precise ver
where `ver` is the latest version of `litemap` supporting rustc 1.75.0
make: *** [Makevars:28: rust/target/release/libarcgisplaces.a] Error 101
ERROR: compilation failed for package ‘arcgisplaces’
* removing ‘/tmp/workdir/arcgisplaces/new/arcgisplaces.Rcheck/arcgisplaces’


```
### CRAN

```
* installing *source* package ‘arcgisplaces’ ...
** this is package ‘arcgisplaces’ version ‘0.1.2’
** package ‘arcgisplaces’ successfully unpacked and MD5 sums checked
** using staged installation
Using cargo 1.75.0
Using rustc 1.75.0 (82e1608df 2023-12-21) (built from a source tarball)
Building for CRAN.
Writing `src/Makevars`.
`tools/config.R` has finished.
** libs
...
export CARGO_HOME=/tmp/workdir/arcgisplaces/old/arcgisplaces.Rcheck/00_pkg_src/arcgisplaces/src/.cargo && \
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/tmp/home/.cargo/bin" && \
RUSTFLAGS=" --print=native-static-libs" cargo build -j 2 --offline --lib --release --manifest-path=./rust/Cargo.toml --target-dir ./rust/target
error: package `native-tls v0.2.14` cannot be built because it requires rustc 1.80.0 or newer, while the currently active rustc version is 1.75.0
Either upgrade to rustc 1.80.0 or newer, or use
cargo update native-tls@0.2.14 --precise ver
where `ver` is the latest version of `native-tls` supporting rustc 1.75.0
make: *** [Makevars:28: rust/target/release/libarcgisplaces.a] Error 101
ERROR: compilation failed for package ‘arcgisplaces’
* removing ‘/tmp/workdir/arcgisplaces/old/arcgisplaces.Rcheck/arcgisplaces’


```
# libipldr (0.1.1)

* GitHub: <https://github.com/JBGruber/libipldr>
* Email: <mailto:JohannesB.Gruber@gmail.com>
* GitHub mirror: <https://github.com/cran/libipldr>

Run `revdepcheck::cloud_details(, "libipldr")` for more info

## In both

*   checking whether package ‘libipldr’ can be installed ... ERROR
     ```
     Installation failed.
     See ‘/tmp/workdir/libipldr/new/libipldr.Rcheck/00install.out’ for details.
     ```

## Installation

### Devel

```
* installing *source* package ‘libipldr’ ...
** this is package ‘libipldr’ version ‘0.1.1’
** package ‘libipldr’ successfully unpacked and MD5 sums checked
** using staged installation
Using cargo 1.75.0
Using rustc 1.75.0 (82e1608df 2023-12-21) (built from a source tarball)
Building for CRAN.
Writing `src/Makevars`.
`tools/config.R` has finished.
** libs
...
export CARGO_HOME=/tmp/workdir/libipldr/new/libipldr.Rcheck/00_pkg_src/libipldr/src/.cargo && \
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/tmp/home/.cargo/bin" && \
RUSTFLAGS=" --print=native-static-libs" cargo build -j 2 --offline --lib --release --manifest-path=./rust/Cargo.toml --target-dir ./rust/target 
error: failed to parse lock file at: /tmp/workdir/libipldr/new/libipldr.Rcheck/00_pkg_src/libipldr/src/rust/Cargo.lock

Caused by:
  lock file version 4 requires `-Znext-lockfile-bump`
make: *** [Makevars:26: rust/target/release/liblibipldr.a] Error 101
ERROR: compilation failed for package ‘libipldr’
* removing ‘/tmp/workdir/libipldr/new/libipldr.Rcheck/libipldr’


```
### CRAN

```
* installing *source* package ‘libipldr’ ...
** this is package ‘libipldr’ version ‘0.1.1’
** package ‘libipldr’ successfully unpacked and MD5 sums checked
** using staged installation
Using cargo 1.75.0
Using rustc 1.75.0 (82e1608df 2023-12-21) (built from a source tarball)
Building for CRAN.
Writing `src/Makevars`.
`tools/config.R` has finished.
** libs
...
export CARGO_HOME=/tmp/workdir/libipldr/old/libipldr.Rcheck/00_pkg_src/libipldr/src/.cargo && \
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/tmp/home/.cargo/bin" && \
RUSTFLAGS=" --print=native-static-libs" cargo build -j 2 --offline --lib --release --manifest-path=./rust/Cargo.toml --target-dir ./rust/target 
error: failed to parse lock file at: /tmp/workdir/libipldr/old/libipldr.Rcheck/00_pkg_src/libipldr/src/rust/Cargo.lock

Caused by:
  lock file version 4 requires `-Znext-lockfile-bump`
make: *** [Makevars:26: rust/target/release/liblibipldr.a] Error 101
ERROR: compilation failed for package ‘libipldr’
* removing ‘/tmp/workdir/libipldr/old/libipldr.Rcheck/libipldr’


```
