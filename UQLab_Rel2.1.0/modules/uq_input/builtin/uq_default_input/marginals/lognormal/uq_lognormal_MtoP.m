function Parameters = uq_lognormal_MtoP( Moments )
% Parameters = UQ_LOGNORMAL_MTOP(Moments) returns the 
% value of the parameters of a Lognormal distribution based on the
% first and the mean and standard deviation
   

mu = Moments(1);
sigma = Moments(2);

lambda = log(mu^2 / sqrt(mu^2 + sigma^2) ) ;
zeta = sqrt(log(1 + sigma^2 / mu^2) ) ;

Parameters = [lambda zeta] ;

