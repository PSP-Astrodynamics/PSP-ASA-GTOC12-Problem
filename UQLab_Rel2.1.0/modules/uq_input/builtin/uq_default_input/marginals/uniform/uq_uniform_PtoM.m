function Moments = uq_uniform_PtoM( Parameters )
% Moments = UQ_UNIFORM_PTOM(Parameters) returns the values of the
% first two moments (mean and standard deviation) of a uniform 
% distribution based on the specified parameters

a = Parameters(1) ;
b = Parameters(2) ;
%check validity of [a,b]
if a > b
    error('The parameters of a uniform distribution are incorrectly defined (should be a<b)!')

end
mu = (a + b)/2 ;
sigma = (b - a)/sqrt(12) ;


Moments = [mu sigma] ;


