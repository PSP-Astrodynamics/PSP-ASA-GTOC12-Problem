function resIDX = uq_bootstrap(N,B)
% RESIDX = UQ_BOOTSTRAP(N,B) returns an index array for resampling with
% repetitions

%% consistency check: X must be a 2D matrix 
resIDX = round(rand(B,N)*(N-1)) + 1;