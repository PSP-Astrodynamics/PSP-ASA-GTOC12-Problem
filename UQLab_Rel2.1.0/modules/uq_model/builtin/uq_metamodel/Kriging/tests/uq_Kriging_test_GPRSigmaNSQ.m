function pass = uq_Kriging_test_GPRSigmaNSQ(level)
%UQ_KRIGING_TEST_GPRSigmaNSQ tests different specifications of SigmaNSQ.
%
%   This is to make sure that all possible values of
%   MetaOpts.Regression.SigmaNSQ for Kriging regression is working as
%   expected.
%
%   PASS = UQ_KRIGING_TEST_GPRSIGMANSQ(LEVEL) carried out non-regression
%   tests with the test depth specified in the string LEVEL for the 
%   Kriging regression with all possible values of SigmaNSQ regression 
%   options.

%% Initialize the test
%
rng(100,'twister')
uqlab('-nosplash')

if nargin < 1
    level = 'normal';
end

fprintf('\nRunning: |%s| uq_Kriging_test_GPRSigmaNSQ...\n',level);

%% Define the test model
%
ModelOpts.mString = 'X.*sin(X)';
myModel = uq_createModel(ModelOpts,'-private');

% Specify its marginal distribution and create a UQLab INPUT object:
InputOpts.Marginals.Type = 'Uniform';
InputOpts.Marginals.Parameters = [-3*pi 3*pi];
myInput = uq_createInput(InputOpts);

% Create an experimental design of size $100$:
Ntrain = 50;
X = uq_getSample(myInput,Ntrain);
% Evaluate the corresponding model responses:
Y = uq_evalModel(myModel,X);
% Add random Gaussian noise with $\sigma_\epsilon = 0.2\sigma_Y$ to the model
% response
noiseVar = 1.0;
Y = Y + sqrt(noiseVar)*randn(size(Y,1),1);

%% Define the test parameters
% Noise variances
SigmaNSQs = {...
    'auto', 'none',...                          % Characters
    true, false,...                             % Logical
    noiseVar,...                                % Non-zero var., regression
    sqrt(noiseVar)*ones(size(Y,1),1),...        % Non-zero var., regression
    sqrt(noiseVar)*diag(ones(size(Y,1),1)),...  % Non-zero var., regression
    0.0,...                                     % Zero variance, no regres.
    sqrt(noiseVar)*zeros(size(Y,1),1),...       % Zero variance, no regres.
    sqrt(noiseVar)*diag(zeros(size(Y,1),1))};   % Zero variance, no regres.

% Estimation method
EstimationMethods = {'ml','cv'};

%% Create the test cases

% Get the indices of all possible combinations
combIdx = uq_findAllCombinations(SigmaNSQs,EstimationMethods);
for ii = 1:length(combIdx)
    % produce one different test-case for each combination
    testCases(ii).SigmaNSQ = SigmaNSQs{combIdx(ii,1)};
    testCases(ii).EstimMethod = EstimationMethods{combIdx(ii,2)};
end

passCases = false(size(combIdx,1),1);

%% Display the header for the test iterations
%
logicalString = {'false', 'true'};
headerString = {...
    'No.', 'Estim.', 'IsRegression', 'EstNoise', 'SigmaNSQ', 'Success'};
fprintf('\n%4s %6s %12s %8s %16s %8s\n',headerString{:})
formatString = '%4d %6s %12s %8s %16s %8s\n';

%% Loop over the normal level test cases and verify the results
%
for nCase = 1:length(testCases)

    clearvars MetaOpts
    MetaOpts.Type = 'Metamodel';
    MetaOpts.MetaType = 'Kriging';
    MetaOpts.Display = 'quiet';
    MetaOpts.EstimMethod = testCases(nCase).EstimMethod;
    MetaOpts.Scaling = false;
    
    % Define regression options
    MetaOpts.Regression.SigmaNSQ = testCases(nCase).SigmaNSQ;
    
    % Experimental design options
    MetaOpts.ExpDesign.X = X;
    MetaOpts.ExpDesign.Y = Y;
    
    % Optimization options
    MetaOpts.Optim.Method = 'cmaes';
    
    % Create a GPR model
    try
        myKriging = uq_createModel(MetaOpts,'-private');
        passCases(nCase) = true;
    catch e
        passCases(nCase) = false;
        rethrow(e)
    end

    if isa(testCases(nCase).SigmaNSQ,'double')
        if isscalar(testCases(nCase).SigmaNSQ)
            classString = 'double (scalar)';
        elseif isvector(testCases(nCase).SigmaNSQ)
            classString = 'double (vector)';
        elseif ismatrix(testCases(nCase).SigmaNSQ)
            classString = 'double (matrix)';
        else
            classString = 'double (unknown)';
        end
    else
        classString = class(testCases(nCase).SigmaNSQ);
    end

    % Print the result for each test cases
    fprintf(...
        formatString,...
        nCase,...
        testCases(nCase).EstimMethod,...
        logicalString{myKriging.Internal.Regression.IsRegression+1},...
        logicalString{myKriging.Internal.Regression.EstimNoise+1},...
        classString,...
        logicalString{passCases(nCase) + 1})
end

pass = all(passCases);

end
