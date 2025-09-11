function Moments = uq_laplace_PtoM(Parameters )
% [M1, M2] = UQ_LAPLACE_PTOM(X, Parameters) returns the 
% value of the mean and standard deviation of a Laplace 
% distribution based on its parameters [m, b]
%  

m = Parameters(1);
b = Parameters(2);

%% Mean
M1=m;
%% Standard deviation
M2=sqrt(2)*b;

Moments = [M1, M2];
