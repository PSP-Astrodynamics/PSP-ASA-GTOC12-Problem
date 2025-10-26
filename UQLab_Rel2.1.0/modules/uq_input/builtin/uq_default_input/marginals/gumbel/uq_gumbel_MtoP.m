function Parameters = uq_gumbel_MtoP( Moments )
% Parameters = UQ_GUMBEL_MTOP(Moments) returns the 
% value of the mu and beta parameters of a Gumbel distribution based on 
% its mean and standard deviation
%
% NOTE: This function refers to the *maximum* Gumbel distribution. For more
% information please refer to the UQLab user manual: The Input module. 
 
% Euler's constant
euler = -psi(1);

mu = Moments(1);
sigma = Moments(2);

% In order to avoid confusion Gumbel's mu parameter is denoted by alpha
gmbl_beta = sqrt(6)*sigma/pi ;
gmbl_mu = mu - euler * gmbl_beta;

Parameters = [gmbl_mu gmbl_beta] ;


