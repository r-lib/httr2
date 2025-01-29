pooled_request <- function(
  req,
  path = NULL,
  on_success = NULL,
  on_failure = NULL,
  on_error = NULL,
  error_call = caller_env()
) {

  check_request(req)
  check_string(path, allow_null = TRUE)
  check_function2(on_success, args = c("resp", "tries"), allow_null = TRUE)
  check_function2(on_failure, args = c("error", "tries"), allow_null = TRUE)
  check_function2(on_error, args = c("error", "tries"), allow_null = TRUE)

  PooledRequest$new(
    req = req,
    path = path,
    error_call = error_call,
    on_success = on_success,
    on_failure = on_failure,
    on_error = on_error
  )
}

# Wrap up all components of request -> response in a single object
PooledRequest <- R6Class(
  "Performance",
  public = list(
    req = NULL,
    resp = NULL,
    tries = 0,

    initialize = function(
      req,
      path = NULL,
      error_call = NULL,
      on_success = NULL,
      on_failure = NULL,
      on_error = NULL
    ) {
      self$req <- req
      private$path <- path
      private$error_call <- error_call
      private$on_success <- on_success
      private$on_failure <- on_failure
      private$on_error <- on_error
    },

    submit = function(pool) {
      self$tries <- self$tries + 1

      req <- auth_sign(self$req)
      req <- cache_pre_fetch(req, private$path)
      if (is_response(req)) {
        private$on_success(req, self$tries)
        return()
      }

      private$req_prep <- req_prepare(req)
      private$handle <- req_handle(private$req_prep)

      curl::multi_add(
        handle = private$handle,
        pool = pool,
        data = private$path,
        done = private$succeed,
        fail = private$fail
      )

      invisible(self)
    },

    cancel = function() {
      # No handle if response was cached
      if (!is.null(private$handle)) {
        curl::multi_cancel(private$handle)
      }
    }

  ),
  private = list(
    path = NULL,
    error_call = NULL,
    pool = NULL,

    req_prep = NULL,
    handle = NULL,

    on_success = NULL,
    on_failure = NULL,
    on_error = NULL,

    succeed = function(res) {
      private$handle <- NULL
      req_completed(private$req_prep)

      if (is.null(private$path)) {
        body <- res$content
      } else {
        # Only needed with curl::multi_run()
        if (!file.exists(private$path)) {
          file.create(private$path)
        }
        body <- new_path(private$path)
      }

      resp <- new_response(
        method = req_method_get(self$req),
        url = res$url,
        status_code = res$status_code,
        headers = as_headers(res$headers),
        body = body,
        request = self$req
      )
      resp <- cache_post_fetch(self$req, resp, path = private$path)

      if (is_error(resp)) {
        private$on_error(resp, tries = self$tries)
      } else if (error_is_error(self$req, resp)) {
        cnd <- resp_failure_cnd(self$req, resp)
        private$on_failure(cnd, tries = self$tries)
      } else {
        private$on_success(resp)
      }
    },

    fail = function(msg) {
      private$handle <- NULL
      req_completed(private$req_prep)

      error <- error_cnd(
        "httr2_failure",
        message = msg,
        request = self$req
      )
      private$on_error(error, tries = self$tries)
    }

  )
)
