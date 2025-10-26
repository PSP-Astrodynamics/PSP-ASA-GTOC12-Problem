function Parameters = uq_beta_MtoP( Moments )
% Parameters = UQ_BETA_MTOP( Moments ) returns the 
% value of the r and s parameters of a Beta distribution based on the
% first and the second moment(i.e. mean and std, respectively).
%
% Note: if not specified otherwise, the support of the distribution
% is assumed to be [a,b] = [0,1]. For more information please refer to the
% UQLab User Manual: The Input Module. 
%   
% See also UQ_BETA_PDF

mu = Moments(1);
sigma = Moments(2);

switch length(Moments)
    case 2
        % Assume that the support is [0,1]
        a = 0;
        b = 1;
        mu_prime = mu;
        v_prime = sigma^2;
    case 4
        % The support is defined in Moments field
        a = Moments(3) ;
        b = Moments(4) ;
        mu_prime = (mu-a)/(b-a);
        v_prime = sigma^2 / (b-a)^2;
    otherwise
        error('Beta distribution is expected to have either 2 or 4 values defined in Moments field!')
end

A = mu_prime*(1 - mu_prime)/v_prime - 1 ;
r = mu_prime * A;
s = (1 - mu_prime) * A ;

Parameters = [r s a b] ;

