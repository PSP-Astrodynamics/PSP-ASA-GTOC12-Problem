function F = uq_gumbel_pdf( X, parameters )
% UQ_GUMBEL_PDF(X, parameters) calculates the Probability Density Function
% values of samples X  that follow a Gumbel distribution with parameters 
% specified in the vector 'parameters'
%
% NOTE: This function refers to the *maximum* Gumbel distribution. For more
% information please refer to the UQLab user manual: The Input module. 
F = evpdf(-X, -parameters(1), parameters(2));