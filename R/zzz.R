.onLoad <- function(...) {
  .str_legacy <<- getRversion() < "4.7.0"
  otel_cache_tracer()
  cache_disk_prune()
}
