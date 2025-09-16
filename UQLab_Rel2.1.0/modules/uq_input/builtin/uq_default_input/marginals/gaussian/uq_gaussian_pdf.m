function F = uq_gaussian_pdf( X, parameters )
% UQ_GAUSSIAN_PDF(X, parameters) calculates the Probability Density Function
% values of samples X  that follow a Gaussian distribution with parameters 
% specified in the vector 'parameters'
F = normpdf(X, parameters(1), parameters(2));