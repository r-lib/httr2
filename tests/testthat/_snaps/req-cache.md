# cache emits useful debugging info

    Code
      # Immutable
      invisible(cache_pre_fetch(req))
      invisible(cache_post_fetch(req, resp))
    Message
      Saving response to cache "f3805db63ff822b4743f247cfdde10a3"
    Code
      invisible(cache_pre_fetch(req))
    Message
      Pruning cache
      Found url in cache "f3805db63ff822b4743f247cfdde10a3"
      Cached value is fresh; retrieving response from cache

---

    Code
      # freshness check
      invisible(cache_pre_fetch(req))
    Message
      Pruning cache
      Found url in cache "f3805db63ff822b4743f247cfdde10a3"
      Cached value is stale; checking for updates
    Code
      invisible(cache_post_fetch(req, response(304)))
    Message
      Cached value still ok; retrieving body from cache
    Code
      invisible(cache_post_fetch(req, error_cnd()))
    Message
      Request errored; retrieving response from cache

