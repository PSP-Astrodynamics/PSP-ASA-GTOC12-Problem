function f = uq_laplace_pdf( X, Parameters )
% UQ_LAPLACE_PDF(X, parameters) calculates the Probability Density Function
% values of samples X  that follow a Laplace distribution with parameters 
% specified in the vector 'parameters'

m = Parameters(1);
b = Parameters(2);

f = exp(- abs(X - m)/b)/(2*b) ; 