function pass = uq_default_input_test_DataMarginals( level )
% UQ_DEFAULT_INPUT_TEST_DATAMARGINALS validation test for data  
% (kernel smoothing based) marginals of the default input module
%
% Summary:
% Some marginal distributions are used to draw some samples that
% are then used to define a kernel-smoothing-based random vector.
% Samples are then drawn from that random vector and they are compared
% in terms of their moments to the samples that were drawn from the
% "true" random vector

%% initialize test
evalc('uqlab');
if nargin < 1
    level = 'normal'; 
end
fprintf(['\nRunning: |' level '| uq_default_input_test_DataMarginals...\n']);
% fix the random seed
rng(1001);

%% parameters
N0 = 5e3;
N = 5e3;
epsMean = 0.01; 
epsStd  = 0.03;

%% True Input
inputOpts.Marginals(1).Type = 'Gumbel';
inputOpts.Marginals(1).Moments = [15 3];
inputOpts.Marginals(2).Type = 'Beta';
inputOpts.Marginals(2).Parameters = [2 3 0 7];
inputOpts.Copula.Type = 'Gaussian';
inputOpts.Copula.RankCorr = [1, 0.8; 0.8, 1];

OrigInput = uq_createInput(inputOpts);

% Get samples from the "true" input
XOrig = uq_getSample(N0, 'LHS');

%% Create the data-based input
%  kernel smoothing-based marginals
DataIN.Marginals(1).Type = 'ks';
DataIN.Marginals(1).Parameters = XOrig(:,1);
DataIN.Marginals(2).Type = 'ks';
DataIN.Marginals(2).Parameters = XOrig(:,2);
% Gaussian copula with appropriate spearman's correlation matrix
DataIN.Copula.Type = 'Gaussian';
DataIN.Copula.RankCorr = corr(XOrig, 'type', 'spearman');

DataInput = uq_createInput(DataIN);

% return the seed to original, so that the two sample sets are very close
rng(1001);
% Get samples from the data-based input
XX = uq_getSample(N, 'LHS');

%% validate results
pass = all(all((mean(XX) - mean(XOrig))./mean(XOrig) < epsMean ) & ...
    ((std(XX) - std(XOrig))./std(XOrig) < epsStd ) );

