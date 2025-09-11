function Parameters = uq_gamma_MtoP( Moments )
% Parameters = UQ_GAMMA_MTOP( Moments ) returns the 
% value of the lambda and k parameters of a Gamma distribution based on the
% first and the second moments (i.e. mean and std, respectively).

mu = Moments(1);
sigma = Moments(2);

lambda = mu / sigma^2;
k = mu^2 / sigma^2 ;
Parameters = [lambda k] ;

