function Parameters = uq_laplace_MtoP( Moments )
% [m, b] = UQ_LAPLACE_MTOP(X, Parameters) returns the 
% value of the m and b parameters of a Laplace distribution based on the
% first and the second moment(i.e. mean and std, respectively)

M1 = Moments(1);
M2 = Moments(2);


%% m: location parameter
m = M1;
%% b: scale parameter
b = M2/sqrt(2);

Parameters = [m, b];