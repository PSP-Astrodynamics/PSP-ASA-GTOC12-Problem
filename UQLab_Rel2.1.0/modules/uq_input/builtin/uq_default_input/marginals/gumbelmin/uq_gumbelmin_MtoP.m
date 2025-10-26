function Parameters = uq_gumbelmin_MtoP( Moments )
% Parameters = UQ_GUMBELMIN_MTOP(Moments) returns the value of
% the mu and beta parameters of a minimum Gumbel distribution based on the
% first and the second moment (i.e. mean and std, respectively).
%
% NOTE: This function refers to the *minimum* Gumbel distribution. For more
% information please refer to the UQLab user manual: The Input module. 
   

% Euler's constant
euler = -psi(1);

mu = Moments(1);
sigma = Moments(2);

gmbl_beta = sqrt(6)*sigma/pi ;
gmbl_mu = mu + euler * gmbl_beta;


Parameters = [gmbl_mu gmbl_beta] ;

