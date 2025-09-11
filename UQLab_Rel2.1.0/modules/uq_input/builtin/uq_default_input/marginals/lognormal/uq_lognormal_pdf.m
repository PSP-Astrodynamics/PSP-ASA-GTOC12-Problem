function F = uq_lognormal_pdf( X, parameters)
% UQ_LOGNORMAL_PDF(X, parameters) calculates the Probability Density Function
% values of samples X  that follow a Lognormal distribution with parameters 
% specified in the vector 'parameters'

F = lognpdf(X, parameters(1), parameters(2));

