#' Add a progress bar to long downloads or uploads
#'
#' When uploading or downloading a large file, it's often useful to
#' provide a progress bar so that you know how long you have to wait.
#'
#' @inheritParams req_headers
#' @param type Type of progress to display: either number of bytes uploaded
#'   or downloaded.
#' @export
#' @examples
#' req <- request("https://r4ds.s3.us-west-2.amazonaws.com/seattle-library-checkouts.csv") |>
#'   req_progress()
#'
#' \dontrun{
#' path <- tempfile()
#' req |> req_perform(path = path)
#' }
req_progress <- function(req, type = c("down", "up")) {
  type <- arg_match(type)

  # https://curl.se/libcurl/c/CURLOPT_XFERINFOFUNCTION.html
  req_options(req, noprogress = FALSE, xferinfofunction = make_progress(type))
}

make_progress <- function(type, frame = caller_env()) {
  force(type)
  init <- FALSE

  function(down, up) {
    if (type == "down") {
      total <- down[[1]]
      now <- down[[2]]
      verb <- "Downloading"
    } else {
      total <- up[[1]]
      now <- up[[2]]
      verb <- "Uploading"
    }

    if (total == 0 && now == 0) {
      init <<- FALSE
      return(TRUE)
    }

    if (!init) {
      init <<- TRUE
      if (total == 0) {
        cli::cli_progress_bar(
          format = paste0(verb, " {cli::pb_spin}"),
          .envir = frame
        )
      } else {
        cli::cli_progress_bar(
          format = paste0(
            verb,
            " {cli::pb_percent} {cli::pb_bar} {cli::pb_eta}"
          ),
          total = total,
          .envir = frame
        )
      }
    }

    if (now < total && total > 0) {
      cli::cli_progress_update(set = now, .envir = frame)
    } else {
      cli::cli_progress_done(.envir = frame)
    }

    TRUE
  }
}
