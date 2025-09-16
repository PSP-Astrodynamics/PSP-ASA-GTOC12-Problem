function Moments = uq_logistic_PtoM(Parameters )
% Moments = UQ_LOGISTIC_PTOM(Parameters) returns the values of the 
% first two moments (mean and standard deviation) of a logistic 
% distribution based on the specified parameters [mu, beta]

m = Parameters(1);
s = Parameters(2);

%% Mean
M1 = m;

%% Standard deviation
M2 = s*pi/sqrt(3);

Moments = [M1, M2];