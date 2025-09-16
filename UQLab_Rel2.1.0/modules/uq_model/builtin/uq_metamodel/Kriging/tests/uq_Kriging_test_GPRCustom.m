function pass = uq_Kriging_test_GPRCustom(level)
%UQ_KRIGING_TEST_GPRCUSTOM tests for constructing custom GP regression.
%
%   This is to make sure that a user-defined Kriging metamodel (i.e, a 
%   predictor-only model) is working as expected.
%
%   PASS = UQ_KRIGING_TEST_CUSTOMKRIGINGREGRESSION(LEVEL) carried out 
%   non-regression tests with the test depth specified in the string LEVEL
%   for the custom Kriging (i.e., a predictor-only model) functionality
%   in the Kriging module.

%   Test functions are two simple one-dimensional function with noisy
%   output from each of which 100 sample points are generated for the
%   experimental design.
%   The test parameters are:
%       1) Isotropy of correlation function (2): true or false
%       2) Types of correlation function (2): 'separable' or 'ellipsoidal'
%       3) Families of correlation function (5): 'matern-5_2',
%          'matern-3_2', 'gaussian', 'exponential', or 'CorrFamilyHandle'
%       4) Estimation of noise level (2): true or false
%       5) Estimation methods: 'ml' or 'cv'
%
%   Optimization method is fixed with the built-in 'cmaes' for
%   compatibility.
%
%   Exhaustive test consist of 80 test cases.
%   For 'normal' level test, only 20 test cases are randomly selected.

%% Initialize the test
%
uqlab('-nosplash')

if nargin < 1
    level = 'normal';
end

fprintf('\nRunning: |%s| uq_Kriging_test_GPRCustom...\n',level);

%% Define the test model
%
ModelOpts.mString = [...
    '[1 + X * 5e-2 + sin(X) ./ X + 0.2 * randn(size(X,1),1), ',...
    'X .* sin(X) + 1.0 * randn(size(X,1),1), ',...
    '1 + X * 5e-2 + sin(X) ./ X + 0.2 * randn(size(X,1),1)]'];

myModel = uq_createModel(ModelOpts,'-private');

%% Define the test model input
%
InputOpts.Marginals.Type = 'Uniform';
InputOpts.Marginals.Parameters = [-10 10];

myInput = uq_createInput(InputOpts,'-private');

%% Define the test parameters
%
rng(100,'twister')
eps = 1e-10;  % Absolute error epsilon

nSample = 50;  % Sample points for training

% Correlation functions
corrIsotropy = {true,false};
corrTypes = {'Separable','Ellipsoidal'};
CorrFamilyHandle.Separable = @(X1,X2,th) max(0, 1 - abs(X1-X2)/th);
CorrFamilyHandle.Ellipsoidal = @(h) max(0, 1 - h);
corrFamilies = {'matern-5_2', 'matern-3_2', 'gaussian', 'exponential',...
        CorrFamilyHandle};

% Noise variances
EstimateNoiseFlag = {{'auto'}, {0.04, 1.0, 0.04}, {true}};

% Estimation method
EstimationMethods = {'ml', 'cv'};

%% Create the test cases

% Get the indices of all possible combinations
combIdx = uq_findAllCombinations(corrIsotropy, corrTypes,...
    corrFamilies, EstimateNoiseFlag, EstimationMethods);
for ii = 1:length(combIdx)
    % produce one different test-case for each combination
    testCases(ii).Corr.Isotropic = corrIsotropy{combIdx(ii,1)};
    testCases(ii).Corr.Type = corrTypes{combIdx(ii,2)};
    if isstruct(corrFamilies{combIdx(ii,3)})
        testCases(ii).Corr.Family = ...
            corrFamilies{combIdx(ii,3)}.(testCases(ii).Corr.Type);
    else
        testCases(ii).Corr.Family = corrFamilies{combIdx(ii,3)};
    end
    testCases(ii).Noise.Estimate = EstimateNoiseFlag{combIdx(ii,4)};
    testCases(ii).EstimMethod = EstimationMethods{combIdx(ii,5)};
end

% for normal level randomly pick n Cases only
if strcmpi(level,'normal')
    nCases = 10;
    randIdx = randperm(size(combIdx,1),nCases);
    testCases = testCases(randIdx);
else
    nCases = size(combIdx,1);
end

passCases = false(nCases,1);

%% Display the header for the test iterations
%
logicalString = {'false', 'true'};
headerString = {'No.', 'Isotropy?', 'Type', 'Family', 'Estim.',...
    'EstNoise', 'Noise1', 'Noise2', 'Noise3', 'Max.Err.Mu', 'Max.Err.Var',...
    'Success?'};
fprintf('\n%4s %9s %11s %11s %6s %8s %8s %8s %8s %10s %11s %8s\n',...
    headerString{:})
formatString = '%4d %9s %11s %11s %6s %8s %8.3f %8.3f %8.3f %10.3e %11.3e %8s\n';
%% Loop over the normal level test cases and verify the results
%
for nCase = 1:length(testCases)
    
    clearvars MetaOpts
    MetaOpts.Type = 'Metamodel';
    MetaOpts.MetaType = 'Kriging';
    MetaOpts.Display = 'quiet';
    MetaOpts.FullModel = myModel;
    MetaOpts.Input = myInput;    
    MetaOpts.EstimMethod = testCases(nCase).EstimMethod;
    MetaOpts.Scaling = false;
    
    % Define regression options
    [MetaOpts.Regression(1:3).SigmaNSQ] = deal(...
        testCases(nCase).Noise.Estimate{:});
    MetaOpts.Regression(1).SigmaSQ.Bound = [0.001 25];
    MetaOpts.Regression(1).SigmaSQ.InitialValue = 10;
    MetaOpts.Regression(2).SigmaSQ.Bound = [0.1 1.4e3];
    MetaOpts.Regression(2).SigmaSQ.InitialValue = 10;

    % Kriging trend options
    MetaOpts.Trend.Type = 'polynomial';
    MetaOpts.Trend.Degree = 2;
    
    % Experimental design options
    MetaOpts.ExpDesign.NSamples = nSample;
    MetaOpts.ExpDesign.Sampling = 'MC';

    % Correlation function options
    MetaOpts.Corr.Type = testCases(nCase).Corr.Type;
    MetaOpts.Corr.Family = testCases(nCase).Corr.Family;
    MetaOpts.Corr.Isotropic = testCases(nCase).Corr.Isotropic;
    
    % Optimization options
    MetaOpts.Optim.Method = 'cmaes';
    
    % Create a GPR model
    myKriging = uq_createModel(MetaOpts,'-private');
  
    % Get the number of outputs
    nOut = myKriging.Internal.Runtime.Nout;
    
    % Define options for custom Kriging regression model
    clearvars MetaOptsCustom
    MetaOptsCustom.Type = 'Metamodel';
    MetaOptsCustom.MetaType = 'Kriging';
    MetaOptsCustom.Display = 'quiet';
    
    % Custom Kriging metamodel, Experimental Design
    MetaOptsCustom.ExpDesign.X = myKriging.ExpDesign.X;
    MetaOptsCustom.ExpDesign.Y = myKriging.ExpDesign.Y;
    MetaOptsCustom.Input.nonConst = MetaOpts.Input.nonConst;

    % Loop over outputs and for each, define a custom Kriging model
    for oo = 1:nOut
        % Trend function specification
        MetaOptsCustom.Kriging(oo).Trend = MetaOpts.Trend;
        % Correlation function specification
        MetaOptsCustom.Kriging(oo).Corr.Family =...
            myKriging.Internal.Kriging(oo).GP.Corr.Family;
        MetaOptsCustom.Kriging(oo).Corr.Type = ...
            myKriging.Internal.Kriging(oo).GP.Corr.Type;
        MetaOptsCustom.Kriging(oo).Corr.Isotropic =...
            myKriging.Internal.Kriging(oo).GP.Corr.Isotropic;
        % Optimized hyperparameters
        MetaOptsCustom.Kriging(oo).beta = myKriging.Kriging(oo).beta;
        MetaOptsCustom.Kriging(oo).sigmaSQ = myKriging.Kriging(oo).sigmaSQ;
        MetaOptsCustom.Kriging(oo).theta = myKriging.Kriging(oo).theta;
        MetaOptsCustom.Kriging(oo).sigmaNSQ = ...
            myKriging.Internal.Regression(oo).SigmaNSQ;
    end

    % Create a custom Kriging metamodel
    myCustomKriging = uq_createModel(MetaOptsCustom,'-private');
     
    % Compare the results with large sample set
    X = uq_getSample(myInput,1e4);
    [myKriging_Ymu,myKriging_Yvar] = uq_evalModel(myKriging,X);
    [myCustomKriging_Ymu,myCustomKriging_Yvar] = ...
        uq_evalModel(myCustomKriging,X);

    curr_error_mu = max(max(abs(myCustomKriging_Ymu - myKriging_Ymu)));
    curr_error_var = max(abs(myCustomKriging_Yvar - myKriging_Yvar));

    % Make sure noise var. is positive
    passCases(nCase) = all(curr_error_mu < eps) & ...
        all(curr_error_var < eps) & ...
        (myKriging.Kriging(1).sigmaNSQ > 0) & ...
        (myKriging.Kriging(2).sigmaNSQ > 0);
    
    if isa(testCases(nCase).Corr.Family,'function_handle')
        CorrFamilyStr = 'handle';
    else
        CorrFamilyStr = testCases(nCase).Corr.Family;
    end
    
    if isa(testCases(nCase).Noise.Estimate{1},'char')
        estNoise = 'true';
    else
        estNoise = 'false';
    end
    
    if isa(testCases(nCase).Noise.Estimate{1},'logical')
        estNoise = logicalString{testCases(nCase).Noise.Estimate{1}+1};
    end
    
    % Print the result for each test cases
    fprintf(formatString,...
        nCase,...
        logicalString{testCases(nCase).Corr.Isotropic+1},...
        testCases(nCase).Corr.Type,...
        CorrFamilyStr,...
        testCases(nCase).EstimMethod,...
        estNoise,...
        myKriging.Kriging(1).sigmaNSQ,...
        myKriging.Kriging(2).sigmaNSQ,...
        myKriging.Kriging(3).sigmaNSQ,...
        max(curr_error_mu), max(curr_error_var),...
        logicalString{passCases(nCase) + 1})
    
end

pass = all(passCases);

end
