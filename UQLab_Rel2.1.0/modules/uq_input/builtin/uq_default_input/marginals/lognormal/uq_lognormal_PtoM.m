function Moments = uq_lognormal_PtoM( Parameters )
% Moments = UQ_LOGNORMAL_PTOM(Parameters) returns the values of the
% first two moments (mean and standard deviation) of a Lognormal 
% distribution based on the specified parameters

lambda = Parameters(1) ;
zeta = Parameters(2) ;

mu = exp(lambda + 0.5 *zeta^2) ;
sigma = exp(lambda + 0.5 *zeta^2 )*sqrt( exp(zeta^2) - 1 ) ;

Moments = [mu sigma] ;


