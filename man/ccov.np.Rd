\name{ccov.np}
\alias{ccov.np}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Nonparametric Estimation of Conditional Covariances of Item Pairs
}
\description{
This function estimates conditional covariances of itempairs
(Stout, Habing, Douglas & Kim, 1996; Zhang & Stout,
1999a). The function is used for the estimation of the DETECT index.
}
\usage{
ccov.np(data, score, bwscale = 1.1, thetagrid = seq(-3, 3, len = 200), 
    progress = TRUE)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{data}{
An \eqn{N \times I} data frame of dichotomous responses.
Missing responses are allowed.
}
  \item{score}{
An ability estimate, e.g. the WLE
}
  \item{bwscale}{
Bandwidth factor for calculation of conditional covariance. The bandwidth
used in the estimation is \code{bwscale} times \eqn{N^{-1/5}}.
}
  \item{thetagrid}{
A vector which contains theta values where conditional 
covariances are evaluated.
}
  \item{progress}{
Display progress?
}
}

\references{
Stout, W., Habing, B., Douglas, J., & Kim, H. R. (1996). 
Conditional covariance-based nonparametric multidimensionality assessment. 
\emph{Applied Psychological Measurement}, \bold{20}, 331-354.

Zhang, J., & Stout, W. (1999). Conditional covariance structure 
of generalized compensatory multidimensional items, 
\emph{Psychometrika}, \bold{64}, 129-152.
}
\author{
Alexander Robitzsch
}
\note{
This function is used in \code{\link{conf.detect}} and \code{\link{expl.detect}}.
}

%% ~Make other sections like Warning with \section{Warning }{....} ~

% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{DETECT}
%\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
