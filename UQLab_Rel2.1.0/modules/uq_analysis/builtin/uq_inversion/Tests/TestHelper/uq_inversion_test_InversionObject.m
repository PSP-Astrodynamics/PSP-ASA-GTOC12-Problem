function [success] = uq_inversion_test_InversionObject(BayesianAnalysis)
% UQ_INVERSION_TEST_INVERSIONOBJECT tests a passed inversion analysis
%   object for consistency. This function is called by many test functions
%   of the Bayesian inversion module.
%
%   See also: UQ_SELFTEST_UQ_INVERSION

% get samples from prior distribution
priorSample = uq_getSample(BayesianAnalysis.PriorDist,1E+01,'MC');

% evaluate the forward models
if isfield(BayesianAnalysis.Internal,'nForwardModels')
    % custom likelihood 
    for ii = 1:BayesianAnalysis.Internal.nForwardModels
        ModelParamIndex = BayesianAnalysis.Internal.ForwardModel_WithoutConst(ii).PMap;
        Y_ForwardModel = uq_evalModel(BayesianAnalysis.Internal.ForwardModel_WithoutConst(ii).Model,priorSample(:,ModelParamIndex));
    end

    % evaluate the likelihood function
    Y_Likelihood = BayesianAnalysis.Likelihood(priorSample);
end

% evaluate the loglikelihood function
Y_LogLikelihood = BayesianAnalysis.LogLikelihood(priorSample);

% evaluate the prior and logPrior functions
Y_Prior = BayesianAnalysis.Prior(priorSample);
Y_LogPrior = BayesianAnalysis.LogPrior(priorSample);

% succeeded
success = true;