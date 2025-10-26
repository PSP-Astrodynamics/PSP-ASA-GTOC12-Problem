function Moments = uq_gumbel_PtoM( Parameters )
% Moments = UQ_GUMBEL_PTOM(Parameters) returns the values of the
% first two moments (mean and standard deviation) of a Gumbel 
% distribution based on the specified parameters [mu, beta]
%
% NOTE: This function refers to the *maximum* Gumbel distribution. For more
% information please refer to the UQLab user manual: The Input module. 

% Euler's constant
euler = -psi(1);

gmbl_mu = Parameters(1) ;
gmbl_beta = Parameters(2) ;

% check validity of Gumbel parameters
if gmbl_beta <= 0
    error('For Gumbel distribution the scale parameter (beta) has to be positive!')
end

mu = gmbl_mu + euler * gmbl_beta ;
sigma = pi * gmbl_beta / sqrt(6);

Moments = [mu sigma] ;


