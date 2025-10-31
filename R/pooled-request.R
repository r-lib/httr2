pooled_request <- function(
  req,
  path = NULL,
  on_success = NULL,
  on_failure = NULL,
  on_error = NULL,
  mock = NULL,
  error_call = caller_env()
) {
  check_request(req)
  check_string(path, allow_null = TRUE)
  check_function2(on_success, args = "resp", allow_null = TRUE)
  check_function2(on_failure, args = "error", allow_null = TRUE)
  check_function2(on_error, args = "error", allow_null = TRUE)

  PooledRequest$new(
    req = req,
    path = path,
    error_call = error_call,
    on_success = on_success,
    on_failure = on_failure,
    on_error = on_error,
    mock = mock
  )
}

# Wrap up all components of request -> response in a single object
PooledRequest <- R6Class(
  "Performance",
  public = list(
    req = NULL,
    resp = NULL,

    initialize = function(
      req,
      path = NULL,
      error_call = NULL,
      on_success = NULL,
      on_failure = NULL,
      on_error = NULL,
      mock = NULL
    ) {
      self$req <- req
      private$path <- path
      private$error_call <- error_call
      private$on_success <- on_success
      private$on_failure <- on_failure
      private$on_error <- on_error
      private$mock <- mock
    },

    submit = function(pool) {
      if (!is.null(private$mock)) {
        mock_resp <- private$mock(self$req)
        if (!is.null(mock_resp)) {
          private$handle_response(mock_resp, self$req)
          return()
        }
      }

      req <- cache_pre_fetch(self$req, private$path)
      if (is_response(req)) {
        private$handle_response(req, self$req)
        return()
      }

      private$req_prep <- req_prepare(req)
      private$handle <- req_handle(private$req_prep)
      if (otel_is_tracing) {
        # Note: we need to do this before we call handle_preflight() so that
        # request signing works correctly with the added headers.
        #
        # TODO: Support resend_count.
        private$req_prep <- req_with_span(
          private$req_prep,
          # Pooled request spans should not become the active span; we want
          # subsequent requests to be siblings rather than parents.
          activate = FALSE
        )
      }
      handle_preflight(private$req_prep, private$handle)

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
      if (!is.null(private$req_prep)) {
        req_record_span_status(private$req_prep)
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
    mock = NULL,

    # curl success could be httr2 success or httr2 failure
    succeed = function(curl_data) {
      private$handle <- NULL
      req_completed(private$req_prep)

      if (is.null(private$path)) {
        body <- curl_data$content
      } else {
        # Only needed with curl::multi_run()
        if (!file.exists(private$path)) {
          file.create(private$path)
        }
        body <- new_path(private$path)
      }

      resp <- create_response(self$req, curl_data, body)
      req_record_span_status(private$req_prep, resp)
      resp <- cache_post_fetch(self$req, resp, path = private$path)
      private$handle_response(resp, self$req)
    },

    handle_response = function(resp, req) {
      if (error_is_error(req, resp)) {
        cnd <- resp_failure_cnd(req, resp, error_call = private$error_call)
        private$on_failure(cnd)
      } else {
        private$on_success(resp)
      }
    },

    # curl failure = httr2 error
    fail = function(msg) {
      private$handle <- NULL
      req_completed(private$req_prep)

      error_class <- setdiff(class(msg), "character")
      curl_error <- error_cnd(message = msg, class = error_class, call = NULL)
      error <- curl_cnd(curl_error, call = private$error_call)
      error$request <- self$req
      req_record_span_status(private$req_prep, error)
      private$on_error(error)
    }
  )
)
