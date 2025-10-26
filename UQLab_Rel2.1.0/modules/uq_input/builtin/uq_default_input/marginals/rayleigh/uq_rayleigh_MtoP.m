function Parameters = uq_rayleigh_MtoP( Moments )
% Parameters = UQ_RAYLEIGH_MTOP(Moments) returns the 
% value of the parameter of a Rayleigh distribution based on 
% its mean

Parameters = Moments(:,1)/sqrt(pi/2);
