function [CI, Confidence, BMean] = uq_Bootstrap_CI(Replications, Alpha)
% [CI, NCONF,BMEAN] = UQ_BOOTSTRAP_CI(REPLICATIONS, ALPHA): returns
%     the confidence intervals and the (1 - ALPHA) empirical-quantile-based
%     confidence intervals CI of the estimator mean based on the provided
%     REPLICATIONS.  The NCONF output represents ALPHA-quantile when the
%     replications are assumed to have a normal distribution.
%
% See also: UQ_SOBOL_INDICES

% Compute the mean:
BMean = mean(Replications);

% Gaussian confidence interval (Confidence output)
Z_Alpha = norminv(1 - Alpha/2);

% Get the standard deviation of the replications:
STD = std(Replications, 0, 1);

% Confidence intervals based on empirical quantiles:
CI = quantile(Replications, [Alpha/2 1-Alpha/2]);

% Confidence intervals assuming a normal distribution
Confidence = STD*Z_Alpha;
