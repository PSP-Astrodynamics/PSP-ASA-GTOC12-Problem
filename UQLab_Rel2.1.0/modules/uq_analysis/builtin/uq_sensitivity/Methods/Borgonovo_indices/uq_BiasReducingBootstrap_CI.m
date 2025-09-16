function [CI, Confidence, BMean] = uq_BiasReducingBootstrap_CI(Replications, PointEstimates, Alpha)
% [CI, NCONF,BMEAN] = UQ_BIASREDUCINGBOOTSTRAP_CI(REPLICATIONS, POINTESTIMATES): 
%     Returns bootstrap confidence intervals on the estimation of 
%     PointEstimates taking into account the bootstrap replication data 
%     included in Replications. HAS TO BE CHANGED ACCORDING TO EFFRON 86!
%
% See also: UQ_BORGONOVO_INDICES

if ~exist('Alpha','var')
    Alpha = 0.025;
end
% Compute the mean:
BMean = mean(Replications);
BMean = 2*PointEstimates - BMean;
Replications = (2*repmat(PointEstimates ,size(Replications,1),1)- Replications);

% Gaussian confidence interval (Confidence output)
Z_Alpha = norminv(1 - Alpha/2);

% Get the standard deviation of the replications:
STD = std(Replications, 0, 1);

% Confidence intervals based on empirical quantiles:
CI = quantile(Replications, [Alpha/2 1-Alpha/2]);

% Confidence intervals assuming a normal distribution
Confidence = STD*Z_Alpha;
