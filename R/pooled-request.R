pooled_request <- function(
  req,
  path = NULL,
  on_success = NULL,
  on_failure = NULL,
  on_error = NULL,
  tracer = default_tracer(),
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
    tracer = tracer
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
      tracer = NULL
    ) {
      self$req <- req
      private$path <- path
      private$error_call <- error_call
      private$on_success <- on_success
      private$on_failure <- on_failure
      private$on_error <- on_error
      private$tracer <- tracer
    },

    submit = function(pool) {
      req <- cache_pre_fetch(self$req, private$path)
      if (is_response(req)) {
        private$on_success(req)
        return()
      }

      # TODO: This throws after we call deactivate_session() anywhere else in
      # the program.
      if (!is.null(private$tracer)) {
        if (!private$tracer$get_active_span_context()$is_valid()) {
          cli::cli_abort(
            "No parent span context: {.str {req_method_get(req)}} {.str {req$url}}"
          )
        }
      }

      # TODO: Support resend_count.
      req <- req_with_span(
        req,
        tracer = private$tracer,
        scope = NULL,
        # Because pooled requests enable a form of concurrency, we need to do
        # some extra work to ensure that the Open Telemetry span tree takes the
        # correct form:
        #
        # 1. We start a fresh otel "session" to ensure that request spans have
        #    the parent context when submit() was called, as users would expect.
        #
        # 2. We then "deactivate" this session when exiting the scope of
        #    submit() so that other spans started while the request is in-flight
        #    are *siblings* of this request span rather than *children*.
        session = TRUE
      )
      on.exit(private$deactivate_session())
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
      if (!is.null(private$req_prep)) {
        private$req_completed()
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

    tracer = NULL,

    deactivate_session = function() {
      if (is.null(private$tracer) || is.null(private$req_prep)) {
        return()
      }
      span <- private$req_prep$state$span
      if (is.null(private$span) || !private$span$is_recording()) {
        return()
      }
      span$deactivate_session()
    },

    req_completed = function(resp = NULL) {
      req_completed(private$req_prep, resp)
      private$deactivate_session()
    },

    # curl success could be httr2 success or httr2 failure
    succeed = function(curl_data) {
      private$handle <- NULL

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
      on.exit(private$req_completed(resp))
      resp <- cache_post_fetch(self$req, resp, path = private$path)

      if (error_is_error(self$req, resp)) {
        cnd <- resp_failure_cnd(self$req, resp, error_call = private$error_call)
        private$on_failure(cnd)
      } else {
        private$on_success(resp)
      }
    },

    # curl failure = httr2 error
    fail = function(msg) {
      private$handle <- NULL

      error_class <- setdiff(class(msg), "character")
      curl_error <- error_cnd(message = msg, class = error_class, call = NULL)
      error <- curl_cnd(curl_error, call = private$error_call)
      error$request <- self$req
      on.exit(private$req_completed(error))
      private$on_error(error)
    }
  )
)
