function f = uq_uniform_pdf( X, parameters )
% UQ_UNIFORM_PDF(X, parameters) calculates the Probability Density Function
% values of samples X  that follow a uniform distribution with parameters 
% specified in the vector 'parameters'

f = zeros(size(X));
a =  parameters(1);
b =  parameters(2);

%% Get the indices of the elements of X that lie before between or after the bounds
ind1 = X < a;
ind2 = X > b;
ind3 = ~(ind1 | ind2);

%% set the PDF to 0 below above the bounds
f(ind1) = 0;
f(ind2) = 0;

%% set the PDF to the appropriate value between the bounds
f(ind3) = 1/(b - a);


