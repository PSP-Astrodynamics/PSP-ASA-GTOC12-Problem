function Results = uq_LRA_UpdateStep(w, Y, Method)
% This function performs an upating step using the specified method; it
% returns the coefficients b and the new residual

% Update normalizing coefficients b
b = uq_LRA_solveMinimization(w, Y, Method);

% Update residual
res = Y-w*b;


%% Set function output
Results.b = b;
Results.res = res;

