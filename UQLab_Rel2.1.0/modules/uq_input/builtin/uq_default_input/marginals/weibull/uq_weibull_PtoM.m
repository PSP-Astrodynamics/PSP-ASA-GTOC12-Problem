function Moments = uq_weibull_PtoM( Parameters )
% Moments = UQ_WEIBULL_PTOM(Parameters) returns the values of the
% first two moments (mean and standard deviation) of a Weibull 
% distribution based on the specified parameters

wbl_alfa = Parameters(1) ;
wbl_beta = Parameters(2) ;

% check validity of Weibull parameters
if wbl_alfa <= 0 || wbl_beta <= 0
    error('For Weibull distribution, both parameters have to be positive!')
end

mu = wbl_alfa*gamma(1 + 1/wbl_beta) ;
sigma = wbl_alfa*sqrt(gamma(1 + 2/wbl_beta) - gamma(1 + 1/wbl_beta)^2) ;

Moments = [mu sigma] ;


