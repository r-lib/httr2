% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/req-options.R
\name{req_timeout}
\alias{req_timeout}
\title{Set time limit for a request}
\usage{
req_timeout(req, seconds)
}
\arguments{
\item{req}{A httr2 \link{request} object.}

\item{seconds}{Maximum number of seconds to wait}
}
\value{
A modified HTTP \link{request}.
}
\description{
An error will be thrown if the request does not complete in the time limit.
}
\examples{
# Give up after at most 10 seconds
request("http://example.com") |> req_timeout(10)
}
