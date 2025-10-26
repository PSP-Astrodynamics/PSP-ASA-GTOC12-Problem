function F = uq_weibull_pdf( X, parameters )
% UQ_WEIBULL_PDF(X, parameters) calculates the Probability Density Function
% values of samples X  that follow a Weibull distribution with parameters 
% specified in the vector 'parameters'

F =  wblpdf(X,parameters(1) * ones(size(X)), parameters(2));
