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

IDs = 45000:48000; % Asteroid IDs to consider
n_datasets = 3;
m0_frac = linspace(0.6, 0.4, n_datasets);
t0_yr = linspace(7.5, 9.5, n_datasets);
ToF_yr = linspace(0.7, 0.9, n_datasets);

converged_is = {};
for j = 1 : numel(ToF_yr) % loop over ToF
    for i = 1 : n_datasets
        [~, ~, converged_is{i}] = Asteroid2Asteroid_lowthrust_batch_func(IDs, m0_frac(i), t0_yr(i), ToF_yr(j));
    end
end