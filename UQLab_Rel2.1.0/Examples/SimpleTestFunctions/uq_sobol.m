function Y = uq_sobol(X)
% Y = UQ_SOBOL(X) is a simple vector implementation of the sobol function
% 
% See also: UQ_EXAMPLE_SOBOL_SOBOL_FUNCTION

[N,M] = size(X);

if M ~= 8
    error('uq_sobol: input must be a matrix of length 8 row vectors!');
end

% the vector of coefficients is;
c = [1 2 5 10 20 50 100 500]';
C = repmat(transpose(c),N,1);

% the response variable then:
Y_ = (abs(4*X-2)+C)./(1+C);
Y = prod(Y_,2);



