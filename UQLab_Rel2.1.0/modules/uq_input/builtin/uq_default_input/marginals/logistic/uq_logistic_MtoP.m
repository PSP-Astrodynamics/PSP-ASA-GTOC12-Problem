function Parameters = uq_logistic_MtoP(Moments)
% Parameters = UQ_LOGISTIC_MTOP(Moments) returns the 
% value of the parameters of a logistic distribution based on
% its mean and standard deviation

M1 = Moments(1);
M2 = Moments(2);

m = M1 ;
s = sqrt(3)*M2/pi ;

Parameters = [m, s];
