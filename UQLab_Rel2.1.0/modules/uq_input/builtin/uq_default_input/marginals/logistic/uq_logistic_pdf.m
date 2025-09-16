function f = uq_logistic_pdf( X, Parameters )
% UQ_LOGISTIC_PDF(X, parameters) calculates the Probability Density Function
% values of samples X  that follow a logistic distribution with parameters 
% specified in the vector 'parameters'

m = Parameters(1);
s = Parameters(2);
f = (exp(-(X-m)/s))./(s*(1+exp(-(X-m)/s)).^2);

f(isnan(f))=0;
