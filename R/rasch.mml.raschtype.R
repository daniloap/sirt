


# 1.01  2012-11-yy	O collect all raschtype function into this file



# 1.0x  2012-11-yy
################################################################



#*************************************************************************************
# E Step Rasch Model                                                        #
.e.step.rasch <- function( dat1 , dat2 , dat2.resp , theta.k , pi.k , I , n , b ,
                                fixed.a , fixed.c , pure.rasch ){
    # probabilities of correct item at theta_k
    if ( pure.rasch == 1 ){   pjk <- .prob.rasch( theta.k , b ) } else {   
                    pjk <- .prob.3pl( theta = theta.k , b = b  , a = fixed.a , c = fixed.c ) }
    f.yi.qk <- sapply( 1:( length(theta.k) ) , FUN = function(vv){
            pjk.vv <- outer( rep(1,nrow(dat2)) , pjk[vv,] ) ;
            rowProds( ( pjk.vv^dat2 * ( 1 - pjk.vv )^(1-dat2 ) )^(dat2.resp) )
                } )
    f.qk.yi <- f.yi.qk * outer( rep( 1 , nrow(dat2) ) , pi.k )
    f.qk.yi <- f.qk.yi / rowSums( f.qk.yi )
    # expected counts at theta.k
    n.k <- colSums( dat1[,2] * f.qk.yi  )
    # expected counts at theta.k and item j
    n.jk <- ( t(dat2.resp) * outer( rep(1,I) , dat1[,2] ) ) %*% f.qk.yi
    # compute r.jk (expected counts for correct item responses at theta.k for item j
    r.jk <- ( t(dat2) * t( dat2.resp) * outer( rep(1,I) , dat1[,2] ) ) %*% f.qk.yi
    # compute log-Likelihood
    ll <- sum( dat1[,2] * log( rowSums( f.yi.qk * outer( rep(1,nrow(f.yi.qk)) , pi.k ) ) ) )
    list( "n.k" = n.k , "n.jk" = n.jk , "r.jk" = r.jk , "f.qk.yi" = f.qk.yi , "pjk" = pjk  ,
            "f.yi.qk" = f.yi.qk , "ll" = ll )
    }
#*************************************************************************************


#*************************************************************************************
# E Step Raschtype Model                                                        #
.e.step.raschtype <- function( dat1 , dat2 , dat2.resp , 
		theta.k , pi.k , I , 
		n , b , fixed.a , fixed.c ,  fixed.d , 
        alpha1 , alpha2 , group , f.qk.yi=NULL ){
    #...................................                    
    # arrange groups
    if ( is.null(group) ){ group <- rep( 1 , nrow(dat1)) }
    G <- length( unique( group) )    
    # probabilities of correct item at theta_k
    pjk <- .prob.raschtype.genlogis( theta.k , b , alpha1 , alpha2 , fixed.a )
    fixed.c.M <- outer( rep(1,nrow(pjk)) , fixed.c )
    fixed.d.M <- outer( rep(1,nrow(pjk)) , fixed.d )
    pjk <- fixed.c.M + ( fixed.d.M - fixed.c.M) * pjk
	if ( is.null( f.qk.yi ) ){
		#***
		# array notation of probabilities
		pjkL <- array( NA , dim=c(2 , nrow(pjk) , ncol(pjk) ) )
		pjkL[1,,] <- 1 - pjk
		pjkL[2,,] <- pjk	
		f.yi.qk <- matrix( 1 , nrow(dat2) , length(theta.k) )
		for (ii in 1:ncol(dat2)){
		#	ii <- 1
			ind.ii <- which( dat2.resp[,ii] == 1 )
			f.yi.qk[ind.ii,] <- f.yi.qk[ind.ii,] * pjkL[ dat2[ind.ii,ii]+1 , ,ii]
						}
		#******
    f.qk.yi <- 0 * f.yi.qk
    if ( G==1 ){ pi.k <- matrix( pi.k , ncol=1 ) }
    for ( gg in 1:G){ 
        f.qk.yi[ group == gg , ] <- f.yi.qk[ group == gg , ] * outer( rep( 1 , nrow(dat2[ group==gg,]) ) , pi.k[,gg] )
                    }				
    f.qk.yi <- f.qk.yi / rowSums( f.qk.yi )		
				}
    # expected counts at theta.k
    n.k <- matrix( 0 , length(theta.k) , G )
    r.jk <- n.jk <- array( 0 , dim=c( ncol(dat2) , length(theta.k) , G) )
    ll <- rep(0,G)
    for (gg in 1:G){ 
        n.k[,gg] <- colSums( dat1[group==gg,2] * f.qk.yi[group==gg,]  )
        # expected counts at theta.k and item j
        n.jk[,,gg] <- ( t(dat2.resp[group==gg,]) * outer( rep(1,I) , dat1[group==gg,2] ) ) %*% f.qk.yi[group==gg, ]
        # compute r.jk (expected counts for correct item responses at theta.k for item j
        r.jk[,,gg] <- ( t(dat2[group==gg,]) * t( dat2.resp[group==gg,]) * outer( rep(1,I) , dat1[group==gg,2] ) ) %*% f.qk.yi[ group==gg,]
        # compute log-Likelihood
        ll[gg] <- sum( dat1[group==gg,2] * log( rowSums( f.yi.qk[group==gg,] * outer( rep(1,nrow(f.yi.qk[group==gg,])) , pi.k[,gg] ) ) ) )
        }
    res <- list( "n.k" = n.k , "n.jk" = n.jk , "r.jk" = r.jk , "f.qk.yi" = f.qk.yi , "pjk" = pjk  ,
            "f.yi.qk" = f.yi.qk , "ll" = sum(ll) )
    return(res)
    }
#*************************************************************************************


#*************************************************************************************
# M Step Rasch Model                                                                  
.m.step.rasch <- function( theta.k , b , n.k , n , n.jk , r.jk , I , conv1 , constraints , mitermax ,
                            fixed.a , fixed.c , pure.rasch , trait.weights ){
    abs.change <- 1
    miter <- 0
    # update pi.k 
    if (is.null( trait.weights) ){ pi.k <- n.k / n  } else { pi.k <- dnorm( theta.k) ; pi.k <- pi.k/sum(pi.k) }
    while( abs.change > conv1 & miter < mitermax ){
        b0 <- b       
        if (pure.rasch == 1){        
            pjk <- .prob.rasch( theta.k , b )
            pjk.M <- t(pjk)
            qjk.M <- 1 - pjk.M
            # update item parameter
            # first order derivative
            d1 <- rowSums(  - r.jk + n.jk * pjk.M  )
            # second order derivative
            d2 <- - rowSums( n.jk * pjk.M * qjk.M )
            } else {
            pjk <- .prob.3pl( theta = theta.k , b = b , a = fixed.a , c = fixed.c )
            pjk.M <- t(pjk)
            qjk.M <- 1 - pjk.M
            # 1st order derivative (item difficulty)
            d1 <- fixed.a / ( 1 - fixed.c ) * rowSums( - r.jk + n.jk * pjk.M + fixed.c * r.jk / pjk.M - fixed.c*n.jk )
            # 2nd order derivative (item difficulty)
            d2 <- fixed.a^2 / ( 1 - fixed.c)^2 * rowSums( r.jk * fixed.c * ( pjk.M - fixed.c ) * ( 1 - t( pjk ) ) / (t (pjk) )^2 
                                    -  n.jk*( pjk.M -  fixed.c ) * qjk.M )
            }
        # change in item difficulty
        b.change <- - d1 / d2 
        b <- b + b.change
        # last item is the sum of all other item difficulties
        center <- is.null(constraints) & is.null(fixed.c)
        if ( !is.null( constraints) ){   b[ constraints[,1] ] <- constraints[,2] }
        abs.change <- max( abs( b0 - b ) )
        miter <- miter+1
        }
      if (pure.rasch == 1){        
            pjk <- .prob.rasch( theta.k , b )
            } else {
            pjk <- .prob.3pl( theta = theta.k , b = b , a = fixed.a , c = fixed.c )
         }   
        # calculate log likelihood
         ll <- sum( rowSums( r.jk  * t( log( pjk ) ) + ( n.jk - r.jk ) * ( t( log(1 - pjk)) ) ) )  
       list( "b" = b , "pi.k" = pi.k , "ll" = ll , "miter" = miter , "center" = center )
    }
#*************************************************************************************


#*************************************************************************************
# M Step Rasch Type Model                                                                  
.m.step.raschtype <- function( theta.k , b , n.k , n , n.jk , r.jk , pi.k , I , conv1 , constraints , mitermax ,
                             pure.rasch , trait.weights , fixed.a , fixed.c , fixed.d ,  alpha1 , alpha2 , h = .0025 ,
							 designmatrix , group , numdiff.parm  , Qmatrix=NULL ,
							 old_increment , est.b){
    abs.change <- 1
    miter <- 0
    # group estimation
    G <- ncol(n.k)
    # number of subjects within groups
    n <- colSums(n.k)
	if ( is.null(Qmatrix) ){ NT <- length(theta.k) } else { NT <- nrow(theta.k) }
    # update pi.k 
#    pi.k <- matrix( 0 , nrow= NT  , ncol=G)
#    for (gg in 1:G){ 
#        if ( is.null( trait.weights) | G > 1 ){ 
#                pi.k[,gg] <- n.k[,gg] / n[gg]  } 
#				else  {	
#                 pi.k <- dnorm( theta.k)
#                 pi.k <- pi.k/sum(pi.k) 
#                 pi.k <- matrix( pi.k , ncol=1 )
#                        }
#               }
    #*****
    # begin loop
    eps <- numdiff.parm 
    # eps <- .00005
    h <- h1 <- eps
    h2 <- 1 + 2*eps
    while( abs.change > conv1 & miter < mitermax ){
        fixed.c.M <- outer( rep(1,NT) , fixed.c )
        fixed.d.M <- outer( rep(1,NT) , fixed.d )
        b0 <- b     
            pjk <- .prob.raschtype.genlogis( theta.k , b , alpha1 , alpha2 , fixed.a,Qmatrix)
                pjk <- fixed.c.M + ( fixed.d.M - fixed.c.M) * pjk
            pjk <- ( pjk + h1 ) / h2
            pjk.M <- t(pjk)
            qjk.M <- 1 - pjk.M
            pjk1 <- .prob.raschtype.genlogis( theta.k , b + h , alpha1 , alpha2 , fixed.a,Qmatrix)
                pjk1 <- fixed.c.M + ( fixed.d.M - fixed.c.M) * pjk1
            pjk1 <- ( pjk1 + h1 ) / h2
            pjk1.M <- t(pjk1)
            qjk1.M <- 1 - pjk1.M
            pjk2 <- .prob.raschtype.genlogis( theta.k , b - h , alpha1 , alpha2 , fixed.a,Qmatrix)
                pjk2 <- fixed.c.M + ( fixed.d.M - fixed.c.M) * pjk2
            pjk2 <- ( pjk2 + h1 ) / h2
            pjk2.M <- t(pjk2)
            qjk2.M <- 1 - pjk2.M
            # update item parameter
            # first order derivative
            # f(x+h) - f(x-h) = 2* f'(x) * h
            ll0 <- ll1 <- ll2 <- matrix( 0 , nrow=nrow(n.jk) , ncol=G)
            for ( gg in 1:G){
                ll0[,gg] <- rowSums( r.jk[,,gg] * log( pjk.M  )  + ( n.jk[,,gg] - r.jk[,,gg]  ) * log( qjk.M ) )
                ll1[,gg] <- rowSums( r.jk[,,gg] * log( pjk1.M ) + ( n.jk[,,gg] - r.jk[,,gg]  ) * log( qjk1.M ) )
                ll2[,gg] <- rowSums( r.jk[,,gg] * log( pjk2.M ) + ( n.jk[,,gg] - r.jk[,,gg]  ) * log( qjk2.M ) )
                            }
            # sum across all groups
            ll0 <- rowSums(ll0)
            ll1 <- rowSums(ll1)            
            ll2 <- rowSums(ll2)            
            d1 <- ( ll1 - ll2  ) / ( 2 * h )    # negative sign?
            # second order derivative
            # f(x+h)+f(x-h) = 2*f(x) + f''(x)*h^2
            d2 <- ( ll1 + ll2 - 2*ll0 ) / h^2
        # change in item difficulty
		d2[ abs(d2) < 10^(-10) ] <- 10^(-10)
		
		#***
		if ( ! is.null(est.b) ){
			d1 <- aggregate( d1 , list(est.b ) , sum )
			i1 <- d1[,1]
			d1 <- d1[,2]
			d2 <- aggregate( d2 , list(est.b) , sum )[,2]
								}						
        increment <- - d1 / d2
#		ci <- ceiling( abs(increment) / ( abs( old_increment) + 10^(-10) ) )
		ci <- ceiling( abs(increment) / max( abs( old_increment) + 10^(-10) ) )
		increment <- ifelse( abs( increment) > max(abs(old_increment))  , 
								increment/(2*ci) , 
								increment )	
		if ( ! is.null(est.b) ){
#			ai2 <- aggregate( increment , list(est.b) , mean )								
#			increment <- ( ai2[,2] )[ est.b ]
			increment <- increment[ match( est.b , i1 ) ]		
							}
#		b.change <- ifelse( abs(b.change) > old_increment , 3*sign(b.change) , b.change )
		b <- b + increment
        # linear parameter constraints
        if ( ! is.null( designmatrix ) & is.null(est.b) ){ 
            mod <- lm( b ~ 0 + designmatrix  )
            b <- fitted(mod)
                }
        # last item is the sum of all other item difficulties
        center <- is.null(constraints) 
        if ( !is.null( constraints) ){  
				b[ constraints[,1] ] <- constraints[,2] 
#				d2[ constraints[,1] ] <- Inf				
					}

        abs.change <- max( abs( b0 - b ) )
        miter <- miter+1
        }   #*** end loop
       pjk <- .prob.raschtype.genlogis( theta.k , b , alpha1 , alpha2 , fixed.a,Qmatrix)
       pjk <- fixed.c.M + ( fixed.d.M - fixed.c.M) * pjk
        # calculate log likelihood
       ll <- sapply( 1:G , FUN = function(gg){ 
                    sum( rowSums( r.jk[,,gg]  * t( log( pjk ) ) + ( n.jk[,,gg] - r.jk[,,gg] ) * ( t( log(1 - pjk)) ) ) )  
                            } )
       ll <- sum(ll)
       list( "b" = b , "pi.k" = pi.k , "ll" = ll , "miter" = miter , "center" = center , "G" = G ,
			"old_increment" = increment , "se.b" = sqrt( 1 /abs(d2) ) )
    }
#*************************************************************************************

#------------------------------------------------------------
# probability raschtype models
.prob.raschtype.genlogis <- function( theta , b , alpha1 , alpha2 , 
			fixed.a = 1 + 0*b , Qmatrix = NULL ){
	if ( is.null(Qmatrix) ){					
		XX <- outer( theta , b , "-" )
		XX <- as.vector(XX)
		XX <- outer( rep(1,length(theta)) , fixed.a ) * XX
							}
	if ( ! is.null(Qmatrix) ){ 							
		XX0 <- as.matrix(theta) %*% t(Qmatrix)
		XX <- XX0 - outer( rep(1,nrow(theta)) , b )
		XX <- as.vector(XX)
		XX <- outer( rep(1,nrow(theta)) , fixed.a ) * XX		
						}
    pm <- pgenlogis(XX , alpha1 , alpha2 )
    # pm <- apply( XX , 2 , FUN = function(xxv){ pgenlogis( xxv , alpha1 , alpha2 )  } )   
    pm <- matrix( pm , ncol= length(b))
    return(pm)
    }
#------------------------------------------------------------


#............................................................
# generalized logistic distribution
##NS export(pgenlogis)
pgenlogis <- function( x , alpha1 = 0 , alpha2 = 0 ){
    x <- as.vector(x)
    xp <- x[ x >= 0 ]
    xn <- x[ x < 0 ]
    indp <- which( x >= 0 )
    indn <- which( x < 0 )
    # positive part of x
    if( ( alpha1 > 0 ) ){ y <-  ( ( exp( alpha1 * xp ) - 1  ) / alpha1  ) }
    if( ( alpha1 == 0 ) ) { y <-  xp  }
    if( ( alpha1 < 0 ) ) { y <- ( - log( 1 - alpha1 * xp )/alpha1 ) }
    # negative part of x
    if( ( alpha2 > 0 ) ){ y1 <-  - ( ( exp( alpha2 * abs(xn) ) - 1  ) / alpha2  ) }
    if( ( alpha2 == 0 ) ) { y1 <-  xn  }
    if( ( alpha2 < 0 ) ) { y1 <- (  log( 1 - alpha2 * abs(xn) )/alpha2 ) }
    # rearrange entries
    w <- rep( 0 , length(x) )
    if ( length(indp) >  0 ){ w[ indp ] <- y }
    if ( length(indn) >  0 ){ w[ indn ] <- y1    }
    # transform to inverse logistic probability
    y <- plogis(w)
    return(y)
        }
#............................................................
# moments of generalized logistic distribution
genlogis.moments <- function( alpha1 , alpha2){
    x0 <- seq(-30,30 , len= 30000 )
    y0 <- pgenlogis( x=x0 , alpha1 = alpha1 , alpha2 = alpha2 )
    wgt <- y0[-1] - y0[ - length(y0) ] 
    wgt <- wgt / sum(wgt)
    out <- ( x0[ -1 ] + x0[ - length(x0) ] ) / 2
    M <- sum( wgt * out )
    SD <- sqrt( sum( wgt*out^2 ) - M^2 )
    moments <- c(M,SD,SD^2 )
    names(moments) <- c("M" , "SD" , "Var" )
    return(moments)
        }




#########################################################################
# simulation of Rasch type models
##NS export(sim.raschtype)
sim.raschtype <- function( theta , b , alpha1 = 0, alpha2 = 0 , fixed.a = NULL , 
		fixed.c = NULL , fixed.d = NULL ){ 
    if ( is.null(fixed.a)){ fixed.a <- 1+0*b }
    if ( is.null(fixed.c)){ fixed.c <- 0*b }
    if ( is.null(fixed.d)){ fixed.d <- 1 + 0*b}
    # latent response (subtraction)
    latresp <- outer( theta , b , "-" )
    # include slope simulation
    latresp <- outer( rep(1,length(theta)) , fixed.a ) * latresp 
    # transformed response
    cM <- outer( rep(1,length(theta)) , fixed.c )
    dM <- outer( rep(1,length(theta)) , fixed.d )    
    trlat <- pgenlogis( latresp , alpha1 = alpha1 , alpha2 = alpha2 )
    trlat <- cM + ( dM - cM )*trlat
#    expprob <- matrix( t(trlat) , ncol= length(b) )    # This was a formatting error!
    expprob <- trlat
    # define response matrix
    dat.resp <- 1 * ( expprob > matrix( runif( nrow(expprob)*ncol(expprob) ) , ncol= ncol(expprob )) )
	I <- length(b)
	colnames(dat.resp) <- paste( "I" , substring(10000+1:I,2) , sep="")
    return(dat.resp)
        }
#########################################################################


#*******************************************************
# plot rasch.mml object                           
##NS S3method(plot,rasch.mml)      
plot.rasch.mml <- function( object , plottitle = "Person-Item-Map" , itemcex = 1 ){
    plot( object$trait.distr[,1] , object$trait.distr[,2] , xlab= "Trait Distribution & Item Difficulties" ,
                    ylab = "Empirical Trait Distribution" , type="n" , ylim= c( -.03 , max(object$trait.distr[,2])*1.3 ) ,
                    main= plottitle , axes= F )
    abline( h = 0 , col="gray" )
    K <- nrow(object$trait.distr)
    for (k in 1:K){  lines( rep( object$trait.distr[k,1] , 2) , c( 0 , object$trait.distr[k,2] ) , col="blue" , lwd=3 ) }
    I <- nrow(object$item)
    if (!is.null(object$fixed.a)){ object$fixed.a <- 1 + 0 * ( 1:( nrow(object$item)) ) }
    points( object$mean.trait , -.015 , pch=17 , col=3 , cex= 1.5 )
    lines( object$mean.trait + object$sd.trait *c(-1,1) , rep( -.015 , 2 ) , col=3 , lwd=2 )
    points( object$item$itemdiff * object$fixed.a , rep( -.015 , I ) + runif( I , -.005 , .005 ) , cex= itemcex , col="red")
    abline( h = -0.015 , col="gray" )
    lines( rep(0,2) , c( -.02 , -.01) , col="gray" , lwd=2)
    axis( side = 1 )
    axis( side = 2 )
    axis( side = 4 )
    # density function
#    xgrid <- seq( min(object$trait.distr[,1]) , max(object$trait.distr[,1]) , 0.1 )
#    lines( xgrid , dnorm( xgrid , mean = object$mean.trait , sd = object$sd.trait ) , col=2 , lwd = 2 )
    }
#******************************************************


#*********************************************************************		
# Estimation of a parameter (discrimination parameter)		
.mml.raschtype.est.a <- function( theta.k , b , fixed.a , fixed.c , fixed.d ,
					pjk , alpha1 , alpha2 , h , G , I , r.jk , n.jk , est.a , Qmatrix ){
				# cc <- cG[1]	
#					est.aa <- 1 * (est.a == aa )
					fixed.c.M <- matrix( fixed.c , nrow(pjk) , length(fixed.c) , byrow=T )
					fixed.d.M <- matrix( fixed.d , nrow(pjk) , length(fixed.d) , byrow=T )
					#****
					# a
					pjk <- .prob.raschtype.genlogis( theta.k , b , alpha1 , alpha2 , fixed.a ,
								Qmatrix)
						pjk <- fixed.c.M + ( fixed.d.M - fixed.c.M) * pjk
					pjk <- ( pjk + .000000005 ) / 1.00000001 
					pjk.M <- t(pjk) ;  qjk.M <- 1 - pjk.M
					pjk1 <- .prob.raschtype.genlogis( theta.k , b  , alpha1 , alpha2 , fixed.a + h,Qmatrix)			
						pjk1 <- fixed.c.M + ( fixed.d.M - fixed.c.M) * pjk1
					pjk1 <- ( pjk1 + .000000005 ) / 1.00000001 
					pjk1.M <- t(pjk1) ; qjk1.M <- 1 - pjk1.M
					pjk2 <- .prob.raschtype.genlogis( theta.k , b  , alpha1 , alpha2 , fixed.a - h,Qmatrix)
						pjk2 <- fixed.c.M + ( fixed.d.M - fixed.c.M) * pjk2
					pjk2 <- ( pjk2 + .000000005 ) / 1.00000001 
					pjk2.M <- t(pjk2) ; qjk2.M <- 1 - pjk2.M
					# first order derivative
					# f(x+h) - f(x-h) = 2* f'(x) * h
					ll0 <- ll1 <- ll2 <- matrix(0, I , G)
				# was ist hier das G? => G ist hier Anzahl der Gruppen
					for (gg in 1:G){ 
						ll0[,gg] <- rowSums( r.jk[,,gg] * log( pjk.M ) + ( n.jk[,,gg] - r.jk[,,gg]  ) * log( qjk.M ) )
						ll1[,gg] <- rowSums( r.jk[,,gg] * log( pjk1.M ) + ( n.jk[,,gg] - r.jk[,,gg]  ) * log( qjk1.M ) )
						ll2[,gg] <- rowSums( r.jk[,,gg] * log( pjk2.M ) + ( n.jk[,,gg] - r.jk[,,gg]  ) * log( qjk2.M ) 	)		
								   }  
					ll0 <- rowSums(ll0)
					ll1 <- rowSums(ll1)
					ll2 <- rowSums(ll2)
					# aggregate with respect to estimation of a
					a1 <- aggregate( cbind( ll0 , ll1 , ll2 ) , list(est.a) , sum , na.rm=T)	
					a1 <- a1[ a1[,1] > 0 , ]					
					ll0 <- a1[,2]
					ll1 <- a1[,3]
					ll2 <- a1[,4]			
					d1 <- ( ll1 - ll2  ) / ( 2 * h )    # negative sign?
					# second order derivative
					# f(x+h)+f(x-h) = 2*f(x) + f''(x)*h^2
					d2 <- ( ll1 + ll2 - 2*ll0 ) / h^2
					d2[ abs(d2) < 10^(-10) ] <- 10^(-10)
					# change in item difficulty
					a.change <- - d1 / d2
#					a.change <- ifelse( abs( a.change ) > .2 , .2*sign(a.change) , a.change )              
					# dampening parameter as in tam
					old_increment <- .2
					ci <- ceiling( abs(a.change) / ( abs( old_increment) + 10^(-10) ) )
					a.change <- ifelse( abs( a.change) > abs(old_increment)  , 
										a.change/(2*ci) , a.change )					
	#					a.change <- a.change
					a.change <- a.change[ match( est.a , a1[,1] ) ]
					if ( any( est.a == 0 ) ){
						a.change[ est.a == 0 ] <- 0
									}									
					fixed.a <- fixed.a + a.change
					fixed.a[ fixed.a < 0 ] <- 0
				res <- list("fixed.a" = fixed.a , "se.a" = sqrt( 1 /abs(d2) ) )
				return(res)
					}
#*********************************************************************



######################################################
# estimation of c parameter
.mml.raschtype.est.c <- function( theta.k , b , fixed.a , fixed.c , fixed.d ,
					pjk , alpha1 , alpha2 , h , G , I , r.jk , n.jk , est.c ,
					min.c , max.c , iter , old_increment.c , Qmatrix){						
					numdiff.parm <- h
					fixed.c.M <- outer( rep(1,nrow(pjk)) , fixed.c  )
					fixed.d.M <- outer( rep(1,nrow(pjk)) , fixed.d )            
					#****
					# alpha1
					pjk <- .prob.raschtype.genlogis( theta.k , b , alpha1 , alpha2 , fixed.a,Qmatrix)
						pjk <- fixed.c.M + ( fixed.d.M - fixed.c.M) * pjk
					pjk <- ( pjk + .000000005 ) / 1.00000001 
					pjk.M <- t(pjk) ;  qjk.M <- 1 - pjk.M
					pjk1 <- .prob.raschtype.genlogis( theta.k , b  , alpha1 , alpha2 , fixed.a,Qmatrix)
					fixed.c.M <- outer( rep(1,nrow(pjk)) , fixed.c + h )				
						pjk1 <- fixed.c.M + ( fixed.d.M - fixed.c.M) * pjk1
					pjk1 <- ( pjk1 + .000000005 ) / 1.00000001 
					pjk1.M <- t(pjk1) ; qjk1.M <- 1 - pjk1.M
					pjk2 <- .prob.raschtype.genlogis( theta.k , b  , alpha1 , alpha2 , fixed.a,Qmatrix)
					fixed.c.M <- outer( rep(1,nrow(pjk)) , fixed.c - h )				
						pjk2 <- fixed.c.M + ( fixed.d.M - fixed.c.M) * pjk2
					pjk2 <- ( pjk2 + .000000005 ) / 1.00000001 
					pjk2.M <- t(pjk2) ; qjk2.M <- 1 - pjk2.M
					# first order derivative
					# f(x+h) - f(x-h) = 2* f'(x) * h
					ll0 <- ll1 <- ll2 <- matrix(0, I , G)
				# was ist hier das G? => G ist hier Anzahl der Gruppen
					for (gg in 1:G){ 
						ll0[,gg] <- rowSums( r.jk[,,gg] * log( pjk.M ) + ( n.jk[,,gg] - r.jk[,,gg]  ) * log( qjk.M ) )
						ll1[,gg] <- rowSums( r.jk[,,gg] * log( pjk1.M ) + ( n.jk[,,gg] - r.jk[,,gg]  ) * log( qjk1.M ) )
						ll2[,gg] <- rowSums( r.jk[,,gg] * log( pjk2.M ) + ( n.jk[,,gg] - r.jk[,,gg]  ) * log( qjk2.M ) 	)		
								   }  
					ll0 <- rowSums(ll0)
					ll1 <- rowSums(ll1)
					ll2 <- rowSums(ll2)
					# aggregate with respect to estimation of a
					a1 <- aggregate( cbind( ll0 , ll1 , ll2 ) , list(est.c) , sum , na.rm=T)	
					a1 <- a1[ a1[,1] > 0 ,]					
					ll0 <- a1[,2]
					ll1 <- a1[,3]
					ll2 <- a1[,4]			
					d1 <- ( ll1 - ll2  ) / ( 2 * h )    # negative sign?
					# second order derivative
					# f(x+h)+f(x-h) = 2*f(x) + f''(x)*h^2
					d2 <- ( ll1 + ll2 - 2*ll0 ) / h^2
					# change in item difficulty
					c.change <- - d1 / d2
#					a.change <- ifelse( abs( a.change ) > .2 , .2*sign(a.change) , a.change )              
					# dampening parameter as in tam
					ci <- ceiling( abs(c.change) / ( abs( old_increment.c) + 10^(-10) ) )
					c.change <- ifelse( abs( c.change) > abs(old_increment.c)  , 
										c.change/(2*ci) , c.change )
					c.change <- c.change[ match( est.c , a1[,1] ) ]
					if ( any( est.c == 0 ) ){
						c.change[ est.c == 0 ] <- 0
									}											
					fixed.c <- fixed.c + c.change
					fixed.c[ fixed.c < 2*numdiff.parm ] <- 2*numdiff.parm
					fixed.c[ fixed.c > max.c ] <- max.c
					fixed.c[ fixed.c < min.c ] <- min.c
#					old_increment.c <- abs( fixed.c - fixed.c0 )
				    res <- list("fixed.c" = fixed.c , "se.c" = sqrt( 1 /abs(d2) ) )
					return( res )
						}

################################################################					
# Estimation of d parameter
.mml.raschtype.est.d <- function( theta.k , b , fixed.a , fixed.c , fixed.d ,
					pjk , alpha1 , alpha2 , h , G , I , r.jk , n.jk , est.d ,
					min.d , max.d , iter , old_increment.d,Qmatrix){				
					est.dd <- 1
					numdiff.parm <- h
					fixed.c.M <- outer( rep(1,nrow(pjk)) , fixed.c  )
					fixed.d.M <- outer( rep(1,nrow(pjk)) , fixed.d )            
					#****
					# alpha1
					pjk <- .prob.raschtype.genlogis( theta.k , b , alpha1 , alpha2 , fixed.a,Qmatrix)
						pjk <- fixed.c.M + ( fixed.d.M - fixed.c.M) * pjk
					pjk <- ( pjk + .000000005 ) / 1.00000001 
					pjk.M <- t(pjk) ;  qjk.M <- 1 - pjk.M
					pjk1 <- .prob.raschtype.genlogis( theta.k , b  , alpha1 , alpha2 , fixed.a,Qmatrix)
					fixed.d.M <- outer( rep(1,nrow(pjk)) , fixed.d + h*est.dd)     					
						pjk1 <- fixed.c.M + ( fixed.d.M - fixed.c.M) * pjk1
					pjk1 <- ( pjk1 + .000000005 ) / 1.00000001 
					pjk1.M <- t(pjk1) ; qjk1.M <- 1 - pjk1.M
					pjk2 <- .prob.raschtype.genlogis( theta.k , b  , alpha1 , alpha2 , fixed.a,Qmatrix)
					fixed.d.M <- outer( rep(1,nrow(pjk)) , fixed.d - h*est.dd)     					
						pjk2 <- fixed.c.M + ( fixed.d.M - fixed.c.M) * pjk2
					pjk2 <- ( pjk2 + .000000005 ) / 1.00000001 
					pjk2.M <- t(pjk2) ; qjk2.M <- 1 - pjk2.M
					# first order derivative
					# f(x+h) - f(x-h) = 2* f'(x) * h
					ll0 <- ll1 <- ll2 <- matrix(0, I , G)
				# was ist hier das G? => G ist hier Anzahl der Gruppen
					for (gg in 1:G){ 
						ll0[,gg] <- rowSums( r.jk[,,gg] * log( pjk.M ) + ( n.jk[,,gg] - r.jk[,,gg]  ) * log( qjk.M ) )
						ll1[,gg] <- rowSums( r.jk[,,gg] * log( pjk1.M ) + ( n.jk[,,gg] - r.jk[,,gg]  ) * log( qjk1.M ) )
						ll2[,gg] <- rowSums( r.jk[,,gg] * log( pjk2.M ) + ( n.jk[,,gg] - r.jk[,,gg]  ) * log( qjk2.M ) 	)		
								   }  
					ll0 <- rowSums(ll0)
					ll1 <- rowSums(ll1)
					ll2 <- rowSums(ll2)
					# aggregate with respect to estimation of a
					a1 <- aggregate( cbind( ll0 , ll1 , ll2 ) , list(est.d) , sum , na.rm=T)		
					a1 <- a1[ a1[,1] > 0 ,]										
					ll0 <- a1[,2]
					ll1 <- a1[,3]
					ll2 <- a1[,4]			
					d1 <- ( ll1 - ll2  ) / ( 2 * h )    # negative sign?
					# second order derivative
					# f(x+h)+f(x-h) = 2*f(x) + f''(x)*h^2
					d2 <- ( ll1 + ll2 - 2*ll0 ) / h^2
					# change in item difficulty
					d.change <- - d1 / d2
#					a.change <- ifelse( abs( a.change ) > .2 , .2*sign(a.change) , a.change )              
					# dampening parameter as in tam
					if ( iter == 0 ){ old_increment.d <- rep( .2 , I ) }
					ci <- ceiling( abs(d.change) / ( abs( old_increment.d) + 10^(-10) ) )
					d.change <- ifelse( abs( d.change) > abs(old_increment.d)  , 
										d.change/(2*ci) , d.change )
					d.change <- d.change[ match( est.d , a1[,1] ) ]
					if ( any( est.d == 0 ) ){
						d.change[ est.d == 0 ] <- 0
									}											
					fixed.d <- fixed.d + d.change
					fixed.d[ fixed.d > 1 - 2 * numdiff.parm ] <- 1 - 2*numdiff.parm
					fixed.d[ fixed.d < min.d ] <- min.d
					fixed.d[ fixed.d > max.d ] <- max.d
				    res <- list("fixed.d" = fixed.d , "se.d" = sqrt( 1 /abs(d2) ) )
					return( res )					
							}
###########################################################################


#*************************************************************************************
# E Step Raschtype Model: multidimensional version
.e.step.raschtype.mirt <- function( dat1 , dat2 , dat2.resp , theta.k , pi.k , I ,
				n , b , fixed.a , fixed.c ,  fixed.d , 
                alpha1 , alpha2 , group ,  mu ,  Sigma.cov , Qmatrix ){
    #...................................                    
    # arrange groups
    if ( is.null(group) ){ group <- rep( 1 , nrow(dat1)) }
    G <- length( unique( group) )    
    # probabilities of correct item at theta_k
    pjk <- .prob.raschtype.genlogis( theta.k , b , alpha1 , alpha2 , fixed.a , Qmatrix )
    fixed.c.M <- outer( rep(1,nrow(pjk)) , fixed.c )
    fixed.d.M <- outer( rep(1,nrow(pjk)) , fixed.d )
    pjk <- fixed.c.M + ( fixed.d.M - fixed.c.M) * pjk
	#***
	# array notation of probabilities
	pjkL <- array( NA , dim=c(2 , nrow(pjk) , ncol(pjk) ) )
	pjkL[1,,] <- 1 - pjk
	pjkL[2,,] <- pjk
	f.yi.qk <- matrix( 1 , nrow(dat2) , nrow(theta.k) )
	for (ii in 1:ncol(dat2)){
	#	ii <- 1
		ind.ii <- which( dat2.resp[,ii] == 1 )
		f.yi.qk[ind.ii,] <- f.yi.qk[ind.ii,] * pjkL[ dat2[ind.ii,ii]+1 , ,ii]
					}			
					
	#******
    f.qk.yi <- 0 * f.yi.qk
    if ( G==1 ){ 
			pi.k <- matrix( pi.k , ncol=1 ) 
					}
    for ( gg in 1:G){ 
        f.qk.yi[ group == gg , ] <- f.yi.qk[ group == gg , ] * outer( rep( 1 , nrow(dat2[ group==gg,]) ) , pi.k[,gg] )
                    }
    f.qk.yi <- f.qk.yi / rowSums( f.qk.yi )
    # expected counts at theta.k
    n.k <- matrix( 0 , nrow(theta.k) , G )
    r.jk <- n.jk <- array( 0 , dim=c( ncol(dat2) , nrow(theta.k) , G) )
    ll <- rep(0,G)
    for (gg in 1:G){ 
        n.k[,gg] <- colSums( dat1[group==gg,2] * f.qk.yi[group==gg,]  )
        # expected counts at theta.k and item j
        n.jk[,,gg] <- ( t(dat2.resp[group==gg,]) * outer( rep(1,I) , dat1[group==gg,2] ) ) %*% f.qk.yi[group==gg, ]
        # compute r.jk (expected counts for correct item responses at theta.k for item j
        r.jk[,,gg] <- ( t(dat2[group==gg,]) * t( dat2.resp[group==gg,]) * outer( rep(1,I) , dat1[group==gg,2] ) ) %*% f.qk.yi[ group==gg,]
        # compute log-Likelihood
        ll[gg] <- sum( dat1[group==gg,2] * log( rowSums( f.yi.qk[group==gg,] * outer( rep(1,nrow(f.yi.qk[group==gg,])) , pi.k[,gg] ) ) ) )
        }
    res <- list( "n.k" = n.k , "n.jk" = n.jk , "r.jk" = r.jk , "f.qk.yi" = f.qk.yi , "pjk" = pjk  ,
            "f.yi.qk" = f.yi.qk , "ll" = sum(ll) )
    return(res)
    }
#*************************************************************************************

									

##################################################
# estimation of group means in the 1dim IRT model
.est.mean <- function( dat1.gg , f.yi.qk.gg , X1 , pi.k , pi.k0 , gg ,
							mean.trait , sd.trait , theta.k , h){	
						ll0 <- sum( dat1.gg * log( rowSums( f.yi.qk.gg * outer( X1 , pi.k[,gg] ) ) ) )	
						pi.k2 <- pi.k0
						pi.k2[,gg] <- dnorm( theta.k , mean = mean.trait[gg]+h , sd = sd.trait[gg]  )	
						pi.k2[,gg] <- pi.k2[,gg] / sum( pi.k2[,gg] )
						ll1 <- sum( dat1.gg * log( rowSums( f.yi.qk.gg * outer( X1 , pi.k2[,gg] ) ) )) 									
						pi.k2 <- pi.k0
						pi.k2[,gg] <- dnorm( theta.k , mean = mean.trait[gg] -h, sd = sd.trait[gg]  )						
						pi.k2[,gg] <- pi.k2[,gg] / sum( pi.k2[,gg] )
						ll2 <- sum( dat1.gg * log( rowSums( f.yi.qk.gg * outer( X1 , pi.k2[,gg] ) ) ) )							
						d1 <- ( ll1 - ll2  ) / ( 2 * h )    # negative sign?
						d2 <- ( ll1 + ll2 - 2*ll0 ) / h^2
						d2[ abs(d2) < 10^(-15) ]  <- 10^(-15)
						d.change <- - d1 / d2
						d.change <- ifelse( abs(d.change) > .1 , .1*sign(d.change) , d.change )	
						return(d.change )
							} 
##################################################



##################################################
# estimation of group SD's in the 1dim IRT model
.est.sd <- function( dat1.gg , f.yi.qk.gg , X1 , pi.k , pi.k0 , gg ,
							mean.trait , sd.trait , theta.k , h){	
		ll0 <- sum( dat1.gg * log( rowSums( f.yi.qk.gg * outer( X1 , pi.k[,gg] ) ) ) )	
		pi.k2 <- pi.k
		pi.k2[,gg] <- dnorm( theta.k , mean = mean.trait[gg] , sd = sd.trait[gg] + h )	
		pi.k2[,gg] <- pi.k2[,gg] / sum( pi.k2[,gg] )
		ll1 <- sum( dat1.gg * log( rowSums( f.yi.qk.gg * outer( X1 , pi.k2[,gg] ) ) ) )		
		pi.k2 <- pi.k
		pi.k2[,gg] <- dnorm( theta.k , mean = mean.trait[gg] , sd = sd.trait[gg] - h )	
		pi.k2[,gg] <- pi.k2[,gg] / sum( pi.k2[,gg] )
		ll2 <- sum( dat1.gg * log( rowSums( f.yi.qk.gg * outer( X1 , pi.k2[,gg] ) ) ) )		
		d1 <- ( ll1 - ll2  ) / ( 2 * h )    # negative sign?
		d2 <- ( ll1 + ll2 - 2*ll0 ) / h^2
		d2[ abs(d2) < 10^(-15) ]  <- 10^(-15)
		d.change <- - d1 / d2
		d.change <- ifelse( abs(d.change) > .05 , .05*sign(d.change) , d.change )
		return(d.change )
							} 
##################################################