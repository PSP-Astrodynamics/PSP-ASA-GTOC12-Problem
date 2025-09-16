function pass = uq_Kriging_test_Print(level)
%UQ_KRIGING_TEST_GPRCUSTOM tests for printing Kriging object.
%
%   This is to make sure that a Kriging metamodel object can be printed.
%   NOTE: The correctness of what's being printed, however, must be
%   separately checked.
%
%   PASS = UQ_KRIGING_TEST_PRINT(LEVEL) carried out non-regression tests
%   with the test depth specified in the string LEVEL for printing a
%   Kriging metamodel object.

%% Initialize the test
uqlab('-nosplash')

if nargin < 1
    level = 'normal';
end

fprintf('\nRunning: |%s| uq_Kriging_test_Print...\n',level);

%% Define the test model

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

rng(100,'twister')

nSample = 10;  % Sample points for training

% Correlation functions
corrIsotropy = {true,false};
corrTypes = {'Separable','Ellipsoidal'};
CorrFamilyHandle.Separable = @(X1,X2,th) max(0, 1 - abs(X1-X2)/th);
CorrFamilyHandle.Ellipsoidal = @(h) max(0, 1 - h);
corrFamilies = {'matern-5_2', 'matern-3_2', 'gaussian', 'exponential',...
    CorrFamilyHandle};

% Noise variances
EstimateNoiseFlag = {{'auto'}, {0.04, 1.0, 0.04}};

% Estimation method
EstimationMethods = {'ml', 'cv'};

% Inputs
X = uq_getSample(myInput,nSample);
Y = uq_evalModel(myModel,uq_getSample(myInput,nSample));
Inputs = {myInput, {X,Y}};

%% Create the test cases

% Get the indices of all possible combinations
combIdx = uq_findAllCombinations(corrIsotropy, corrTypes,...
    corrFamilies, EstimateNoiseFlag, EstimationMethods, Inputs);
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
    if isa(Inputs{combIdx(ii,6)},'uq_input')
        testCases(ii).Input = Inputs{combIdx(ii,6)};
    else
        testCases(ii).ExpDesign.X = Inputs{combIdx(ii,6)}{1};
        testCases(ii).ExpDesign.Y = Inputs{combIdx(ii,6)}{2};
    end
end

% for normal level randomly pick n Cases only
if strcmpi(level,'normal')
    nCases = 20;
    randIdx = randperm(size(combIdx,1),nCases);
    testCases = testCases(randIdx);
else
    nCases = size(combIdx,1);
end

passCases = false(nCases,1);

%% Loop over the normal level test cases and verify the results
%
for nCase = 1:length(testCases)
    
    clearvars MetaOpts
    MetaOpts.Type = 'Metamodel';
    MetaOpts.MetaType = 'Kriging';
    MetaOpts.Display = 'quiet';
    MetaOpts.FullModel = myModel;
    
    % Experimental design options
    if ~isempty(testCases(nCase).Input)
        MetaOpts.Input = testCases(nCase).Input;
        MetaOpts.ExpDesign.NSamples = nSample;
        MetaOpts.ExpDesign.Sampling = 'MC';
    else
        MetaOpts.ExpDesign.X = testCases(nCase).ExpDesign.X;
        MetaOpts.ExpDesign.Y = testCases(nCase).ExpDesign.Y;    
    end
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
    MetaOptsCustom.Input.nonConst = 1;

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
     
    % Print
    try
        uq_print(myKriging)
        uq_print(myKriging,1)
        uq_print(myKriging,2)
        uq_print(myKriging,3)
        uq_print(myKriging,1,'beta')
        uq_print(myKriging,1,'theta')
        uq_print(myKriging,1,'R')
        uq_print(myKriging,1,'F')
        uq_print(myKriging,2,'beta')
        uq_print(myKriging,2,'theta')
        uq_print(myKriging,2,'R')
        uq_print(myKriging,2,'F')
        uq_print(myKriging,3,'beta')
        uq_print(myKriging,3,'theta')
        uq_print(myKriging,3,'R')
        uq_print(myKriging,3,'F')
        uq_print(myCustomKriging)
        uq_print(myCustomKriging,1)
        uq_print(myCustomKriging,2)
        uq_print(myCustomKriging,3)
        uq_print(myCustomKriging,1,'beta')
        uq_print(myCustomKriging,1,'theta')
        uq_print(myCustomKriging,1,'R')
        uq_print(myCustomKriging,1,'F')
        uq_print(myCustomKriging,2,'beta')
        uq_print(myCustomKriging,2,'theta')
        uq_print(myCustomKriging,2,'R')
        uq_print(myCustomKriging,2,'F')
        uq_print(myCustomKriging,3,'beta')
        uq_print(myCustomKriging,3,'theta')
        uq_print(myCustomKriging,3,'R')
        uq_print(myCustomKriging,3,'F')
        pass = true;
    catch
        pass = false;
    end
end

end
