.onLoad <- function(...) {
  otel_cache_tracer()
  cache_disk_prune()
}
