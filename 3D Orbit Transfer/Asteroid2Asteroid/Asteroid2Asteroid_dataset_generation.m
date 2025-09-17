%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PSP ASA
% Asteroid2Asteroid Low Thrust Transfer Dataset Generator
% Author: Travis Hastreiter 
% Created On: 16 September, 2025
% Description: Computes low thrust transfers for asteroid to asteroid 
% transfers for the purpose of creating a comprehensive delta V surrogate 
% function.
% Most Recent Change: 16 September, 2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

IDs = 1:4000; % Asteroid IDs to consider - NEED TO BE ABLE TO HAVE ARBITRARY ID ARRAY
n_datasets = 7;
m0_frac = linspace(0.9, 0.35, n_datasets);
t0_yr = linspace(1.5, 13.5, n_datasets);
ToF_yr = 0.5 * ones([1, n_datasets]);

converged_is = {};
for i = 7 : n_datasets
    [~, ~, converged_is{i}] = Asteroid2Asteroid_lowthrust_batch_func(IDs, m0_frac(i), t0_yr(i), ToF_yr(i));
end