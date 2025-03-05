## R CMD check results

0 errors | 0 warnings | 1 note

* NOTE: Missing dependency on R >= 4.1.0 because package code uses the pipe.
  This is a false positive; httr2 uses a trick (`configure` +
  `tools/examples.R`) to ensure the examples are not run on earlier versions of
  R.

## revdepcheck results

I saw 2 broken packages due to failing tests (that don't affect pacakge functionality). I supplied both packages with patches:

* happign: https://github.com/paul-carteron/happign/pull/34
* tidyllm: https://github.com/edubruell/tidyllm/pull/53
