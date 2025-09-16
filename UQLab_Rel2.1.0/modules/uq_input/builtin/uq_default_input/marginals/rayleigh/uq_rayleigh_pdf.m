function F = uq_rayleigh_pdf( X, parameters )
% UQ_RAYLEIGH_PDF(X, parameters) calculates the Probability Density Function
% values of samples X that follow a Rayleigh distribution with parameters 
% specified in the vector 'parameters'
%
F = raylpdf(X, parameters(:,1));