\name{testlet.yen.q3}
\alias{testlet.yen.q3}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
\eqn{Q_3} Statistic of Yen (1984) for Testlets
}
\description{
This function calculates the average \eqn{Q_3} statistic (Yen, 1984) within and
between testlets.
}
\usage{
testlet.yen.q3(q3.res, testlet.matrix)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{q3.res}{
An object generated by \code{\link{yen.q3}}
}
  \item{testlet.matrix}{
A matrix with two columns. The first column contains names of the testlets and
the second names of the items. See the examples for the definition of such 
matrices.
}
}
\value{
A list with following entries
  \item{testlet.q3}{Data frame with average \eqn{Q_3} statistics within testlets}
  \item{testlet.q3.korr}{Matrix of average \eqn{Q_3} statistics within and 
  	between testlets}
}
\references{
Yen, W. M. (1984). Effects of local item dependence on the fit and equating 
performance of the three-parameter logistic model. 
\emph{Applied Psychological Measurement}, \bold{8}, 125-145.
}
\author{
Alexander Robitzsch
}


%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{
For estimating all \eqn{Q_3} statistics between item pairs use 
\code{\link{yen.q3}}.
}
\examples{
#############################################################################
# EXAMPLE 1: data.read. The 12 items are arranged in 4 testlets
#############################################################################
data(data.read)

# estimate the Rasch model
mod <- rasch.mml2( data.read)
mod$item

# estmate WLEs
mod.wle <- wle.rasch( dat = data.read , b = mod$item$b )

# Yen's Q3 statistic
mod.q3 <- yen.q3( dat = data.read , theta = mod.wle$theta , b = mod$item$b )

# Yen's Q3 statistic with testlets
items <- colnames(data.read)
testlet.matrix <- cbind( substring(  items,1,1) , items )
mod.testletq3 <- testlet.yen.q3( q3.res=mod.q3,testlet.matrix=testlet.matrix)
mod.testletq3
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{Testlets}
\keyword{Local dependence}
\keyword{Q3}
%%\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
