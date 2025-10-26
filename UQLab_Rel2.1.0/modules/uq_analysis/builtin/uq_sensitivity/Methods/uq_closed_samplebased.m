function Sclo = uq_closed_samplebased(Options,VariableSet)
% [SCLO,COST,OPTIONS] = UQ_CLOSED_SAMPLEBASED(OPTIONS,VARIABLESET)
% produces the closed index of X_VARIABLESET from a large sample.
%   The OPTIONS are essentially the current analysis' options including a
%   field named IndexOpts that is of type structure and contains
%   .SampleSize, .Sampling, .Estimator and possibly samples .X & .Y
%
% See also: UQ_KUCHERENKO_INDICES, UQ_SHAPLEY_INDICES, UQ_TOTAL_SENS_INDEX

%% Initialize

% get sample or samplesize
N = Options.Kucherenko.SampleSize;
xx = Options.Kucherenko.X;
yy = Options.Kucherenko.Y;
D = Options.Kucherenko.TotalVariance;
VariableSet = find(VariableSet);

% Binning specifications
% Set an average number of points per bin
AvgPerBin = 25;
% For this estimation, we will bin quantile based
binningoptions.binStrat = 'quantile';
% the user may have defined a maximum number of bins. 
nbin_tot = Options.Kucherenko.nBins;
if ~Options.Kucherenko.nBins % If not get based on AvgPerBin
    nbin_tot = floor(N/AvgPerBin);
end
% bins per conditioning dimension
binningoptions.nBins = floor(nthroot(nbin_tot,numel(VariableSet)));

%% get the conditional mean from

% Create bins along all variables in VariableSet and calculate the moments
% of Y in each of them
[momentsY, binProb] = uq_condMoments(xx,yy,VariableSet,binningoptions);

cond_means = cell2mat(momentsY.mean(:));
binProb = cell2mat(binProb(:));

% closed index: calcualte the weighted (by the bin probability) variance of
% the bin means, loop over output dimensions
Sclo = zeros(1,size(yy,2));
for ii = 1:size(yy,2)
    Sclo(ii) = var(cond_means(:,ii),binProb,'omitnan')/D(ii);
end

