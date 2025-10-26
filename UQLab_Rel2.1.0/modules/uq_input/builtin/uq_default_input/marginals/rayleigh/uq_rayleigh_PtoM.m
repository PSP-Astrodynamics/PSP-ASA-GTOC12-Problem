function Moments = uq_rayleigh_PtoM( Parameters )
% Moments = UQ_RAYLEIGH_PTOM(Parameters) returns the values of the
% first two moments (mean and standard deviation) of a Rayleigh 
% distribution based on the specified parameter

Moments(1)=Parameters(:,1)*sqrt(pi/2);
Moments(2)=Parameters(:,1)*sqrt((4-pi)/2);

