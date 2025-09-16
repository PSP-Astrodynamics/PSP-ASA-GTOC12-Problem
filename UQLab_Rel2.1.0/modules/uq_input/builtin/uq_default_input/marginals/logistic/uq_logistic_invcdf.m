function X = uq_logistic_invcdf( F, Parameters )
% UQ_LOGISTIC_INVCDF(F, parameters) calculates the inverse Cumulative Density Function
% values of CDF values F of samples X  that follow a logistic distribution with 
% parameters specified in the vector 'parameters'

m = Parameters(1);
s = Parameters(2);

X = m + s*log(F./(1-F));