function Moments = uq_gamma_PtoM( Parameters )
% Moments = UQ_GAMMA_PTOM(Parameters) returns the values of the first two moments (mean and 
% standard deviation) of a Gamma distribution based on the specified parameters [lambda, k]

lambda = Parameters(1) ;
k = Parameters(2) ;
% check validity of Gamma parameters
if k <= 0 || lambda <= 0
    error('For Gamma distribution, both parameters have to be positive!')
end
mu = k/lambda ;
sigma = sqrt(k)/lambda ;

Moments = [mu sigma] ;


