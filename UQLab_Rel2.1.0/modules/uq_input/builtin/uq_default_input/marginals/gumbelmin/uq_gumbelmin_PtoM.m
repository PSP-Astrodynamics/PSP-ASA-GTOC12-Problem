function Moments = uq_gumbelmin_PtoM(Parameters)
% Moments = UQ_GUMBELMIN_PTOM(Parameters) returns the 
% value of the moments of a Beta distribution based on the
% specified parameters.
%
% NOTE: This function refers to the *minimum* Gumbel distribution. For more
% information please refer to the UQLab user manual: The Input module. 

% Euler's constant
euler = -psi(1);

gmbl_mu = Parameters(1) ;
gmbl_beta = Parameters(2) ;

% check validity of Gumbel parameters
if gmbl_beta <= 0
    error('For Gumbel distribution the scale parameter (beta) has to be positive!')
end
mu = gmbl_mu - euler * gmbl_beta ;
sigma = pi * gmbl_beta / sqrt(6);

Moments = [mu sigma] ;


