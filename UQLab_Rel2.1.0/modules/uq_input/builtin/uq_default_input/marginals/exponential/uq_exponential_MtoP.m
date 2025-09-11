function Parameters = uq_exponential_MtoP(Moments)
% Parameters = UQ_EXPONENTIAL_MTOP(Moments) returns the 
% value of the scale parameter lambda of an exponential distribution based on the
% first and the second moment(i.e. mean and std, respectively).
%
% See also UQ_EXPONENTIAL_PDF

Parameters = 1/Moments(1);




