function Moments = uq_exponential_PtoM( Parameters )
% Moments = UQ_EXPONENTIAL_PTOM(Parameters) returns the 
% value of the moments of an exponential distribution based on the
% specified scale parameter lambda.
%
% See also UQ_EXPONENTIAL_PDF

Moments(1) = 1/Parameters(1);
Moments(2) = Moments(1);




