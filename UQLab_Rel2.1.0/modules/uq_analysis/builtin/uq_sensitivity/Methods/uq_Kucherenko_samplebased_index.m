function [Sclo, Stot] = uq_Kucherenko_samplebased_index(Sample,M_Sample,VariableSet,D)
% [SCLO,COST,OPTIONS] = UQ_CLOSED_SAMPLEBASED(OPTIONS,VARIABLESET)
% produces the closed index of X_VARIABLESET from a large sample.
%   The OPTIONS are essentially the current analysis' options including a
%   field named IndexOpts that is of type structure and contains
%   .SampleSize, .Sampling, .Estimator and possibly samples .X & .Y
%
% See also: UQ_KUCHERENKO_INDICES, UQ_SHAPLEY_INDICES, UQ_TOTAL_SENS_INDEX

%% Initialize
VariableSet1 = find(VariableSet);
VariableSettot = find(~VariableSet);
% Get sample size
N = size(Sample,1);
% Binning specifications
% Set an average number of points per bin
AvgPerBin = 25;
% For this estimation, we will bin quantile based
binopts.binStrat = 'quantile';
% Get number of bins based on AvgPerBin
nbin = floor(N/AvgPerBin);


%% get the conditional mean from

% Create bins along all variables in VariableSet and calculate the moments
% of Y in each of the
% bins per conditioning dimension for first-order index
% NOTE: Maximum number of bins are limited to 100 in one dimension
%       (corresponds to percentile in quantile-based binning)
binopts.nBins = min(100,floor(nthroot(nbin,numel(VariableSet1))));
%binopts.nBins = floor(nthroot(nbin,numel(VariableSet1)));
% get cond moments for first-order index
[momentsY1,binProb1] = uq_condMoments(Sample,M_Sample,VariableSet1,binopts);

% bins per conditioning dimension for total index
binopts.nBins = floor(nthroot(nbin,numel(VariableSettot)));
% get cond moments for total index
[momentsYtot,binProbtot] = uq_condMoments(Sample,M_Sample,VariableSettot,binopts);

% vectorize and get rid of empty bins
cond_means = momentsY1.mean;
cond_vars = momentsYtot.variance;

% Compute the indices, loop over output dimensions
Sclo = zeros(1,size(M_Sample,2));
Stot = zeros(1,size(M_Sample,2));
for oo = 1:size(M_Sample,2)
    % Closed (first-order) index: Calculate the weighted (by the bin
    % probability) variance of the bin means
    Sclo(oo) = var(cond_means(:,oo),binProb1)/D(oo);
    % Total effect index: Calculate the weighted (by the bin probability)
    % mean of the bin variances
    Stot(oo) = sum(cond_vars(:,oo).*binProbtot)/D(oo);
end

end

