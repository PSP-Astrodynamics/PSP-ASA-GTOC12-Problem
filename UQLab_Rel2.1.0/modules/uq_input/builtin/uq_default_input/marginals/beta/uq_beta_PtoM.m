function Moments = uq_beta_PtoM( Parameters )
% Moments = UQ_BETA_PTOM(Parameters) returns the 
% value of the moments of a Beta distribution based on the
% specified parameters.
%
% Note: if not specified otherwise, the support of the distribution
% is assumed to be [a,b] = [0,1]. For more information please refer to the
% UQLab User Manual: The Input Module. 
%   
% See also UQ_BETA_PDF

r = Parameters(1) ;
s = Parameters(2) ;
% check validity of Beta parameters
if r <= 0 || s <= 0
    error('For Beta distribution, both parameters have to be positive!')
end
switch length(Parameters)
    case 2 % the support is [0,1]
        a = 0;
        b = 1;
    case 4 % the support is [a,b]
        a = Parameters(3);
        b = Parameters(4);
    otherwise
        error('Beta distribution can only work with 2 or 4 parameters defined!')
end
mu = a + (b-a)*r / (r+s) ;
sigma = (b-a)/(r+s) * sqrt(r*s / (r+s+1)) ;

Moments = [mu sigma] ;


