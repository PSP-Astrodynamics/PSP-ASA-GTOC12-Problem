function pass = uq_Kriging_test_GPRConstant(level)
%UQ_KRIGING_TEST_GPRCONSTANT tests for constants support in GP regression.
%
%   Summary:
%   Make sure that various Kriging configurations are working as expected
%   when using constants in some of the input components.

%% Initialize the test
%
rng(100,'twister')
uqlab('-nosplash')

if nargin < 1
    level = 'normal';
end

fprintf('\nRunning: |%s| uq_Kriging_test_GPRConstant...\n',level);

%% Define test parameters
%
eps = 1e-14;
Ncomp = 1e3;

CorrFamilyHandle.Separable = @(X1,X2,th) max(0, 1 - abs(X1-X2)/th);
CorrFamilyHandle.Ellipsoidal = @(h) max(0, 1 - h);
Families = {'matern-5_2', 'matern-3_2', 'gaussian',...
        'exponential', CorrFamilyHandle};    
Isotropy = {true, false};
CorrTypes = {'Separable', 'Ellipsoidal'};

Trend.Type = 'polynomial';
Trend.Degree = 3;

%% Define input model with constants
%
[InputOpts.Marginals(1:5).Type] = deal('uniform');
[InputOpts.Marginals(1:5).Parameters] = deal([-pi pi]);
InputOpts.Marginals(2).Type = 'Constant';
InputOpts.Marginals(2).Parameters = 3.2;
InputOpts.Marginals(4).Type = 'Constant';
InputOpts.Marginals(4).Parameters = 2.3;

% Create the INPUT object
myInput = uq_createInput(InputOpts);

%% Define computational model for the test (Ishigami function)
%
% Ishigami function plus two variables that have been set to constant:
ModelOpts.mHandle = @(X) uq_ishigami_various_outputs(...
    [X(:,1),X(:,3),X(:,5)]) + (X(:,2).^2 + X(:,4));

% Create the MODEL object
myModel = uq_createModel(ModelOpts);

%% Create test case combinations
%
% Get the indices of all possible combinations
combIdx = uq_findAllCombinations(Isotropy, CorrTypes, Families);
% Produce one test case for each combination
for oo  = 1:length(combIdx)
    testCases(oo).Corr.Isotropic = Isotropy{combIdx(oo,1)};
    testCases(oo).Corr.Type = CorrTypes{combIdx(oo,2)};
    if isstruct(Families{combIdx(oo,3)})
        testCases(oo).Corr.Family = ...
            Families{combIdx(oo,3)}.(testCases(oo).Corr.Type);
    else
        testCases(oo).Corr.Family = Families{combIdx(oo,3)} ;
    end
end

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
headerString = {'No.', 'Isotropy?', 'Type', 'Family',...
    'Max.Err.Mu', 'Max.Err.Var', 'Success'};
fprintf('\n%4s %9s %11s %11s %10s %11s %7s\n', headerString{:})

%% Run the test case
%
% Define common options
% Kriging metamodel
MetaOpts.Type =  'Metamodel';
MetaOpts.MetaType = 'Kriging';
MetaOpts.FullModel = myModel;
MetaOpts.Display = 'quiet';

% Input
MetaOpts.Input = myInput;
MetaOpts.ExpDesign.NSamples = 10;
MetaOpts.ExpDesign.Sampling = 'LHS';
% Estimation method
MetaOpts.EstimMethod = 'CV';
% Optimization
MetaOpts.Optim.Method = 'cmaes';  % For compatibility
MetaOpts.Optim.Bounds = [0.1; 3];
% Noise Options
MetaOpts.Regression(1).SigmaNSQ = 1;
MetaOpts.Regression(2).SigmaNSQ = 0;
MetaOpts.Regression(3).SigmaNSQ = 3;
% Input scaling
MetaOpts.Scaling = false;
% Trend
MetaOpts.Trend = Trend;

for nCase = 1:nCases

    % Correlation function
    MetaOpts.Corr.Type = testCases(nCase).Corr.Type;
    MetaOpts.Corr.Family = testCases(nCase).Corr.Family;
    MetaOpts.Corr.Isotropic = testCases(nCase).Corr.Isotropic;
    try
        myKriging = uq_createModel(MetaOpts);
    catch
        fprintf('Evaluation of Kriging failed for test case %d\n',nCase);
        pass = false;
        break
    end
    
    % Get the number of outputs
    Nout = myKriging.Internal.Runtime.Nout;

    % Create a custom Kriging metamodel
    MetaOpts2.Type =  'Metamodel';
    MetaOpts2.MetaType = 'Kriging';
    MetaOpts2.Display = 'quiet';
    MetaOpts2.ExpDesign.X = myKriging.ExpDesign.X;
    MetaOpts2.ExpDesign.Y = myKriging.ExpDesign.Y;
    MetaOpts2.Input.nonConst = MetaOpts.Input.nonConst;
    for oo = 1:Nout
        MetaOpts2.Kriging(oo).beta = myKriging.Kriging(oo).beta;
        MetaOpts2.Kriging(oo).sigmaSQ = myKriging.Kriging(oo).sigmaSQ;
        MetaOpts2.Kriging(oo).theta = myKriging.Kriging(oo).theta;
        MetaOpts2.Kriging(oo).Corr.Family = ...
            myKriging.Internal.Kriging(oo).GP.Corr.Family;
        MetaOpts2.Kriging(oo).Corr.Type = ...
            myKriging.Internal.Kriging(oo).GP.Corr.Type;
        MetaOpts2.Kriging(oo).Corr.Isotropic = ...
            myKriging.Internal.Kriging(oo).GP.Corr.Isotropic;
        MetaOpts2.Kriging(oo).Trend = MetaOpts.Trend;
        MetaOpts2.Kriging(oo).sigmaNSQ = ...
            myKriging.Internal.Regression(oo).SigmaNSQ;
    end

    myCustomKriging = uq_createModel(MetaOpts2);

    % Compare the results
    X = uq_getSample(Ncomp);
    warning('off')
    [myKrig_Ymu,myKrig_Yvar] = uq_evalModel(myKriging,X);
    [myCustKrig_Ymu,myCustKrig_Yvar] = uq_evalModel(myCustomKriging,X);

    curr_error_mu = max(max(abs(myCustKrig_Ymu - myKrig_Ymu)));
    curr_error_var = max(abs(myCustKrig_Yvar - myKrig_Yvar));

    passCases(nCase) = all(curr_error_mu < eps) & ...
        all(curr_error_var < eps);

    if isa(testCases(nCase).Corr.Family,'function_handle')
        CorrFamilyStr = 'handle';
    else
        CorrFamilyStr = testCases(nCase).Corr.Family;
    end
    
    % Print the result for each test cases
    fprintf('%4d %9s %11s %11s %10.3e %11.3e %7s\n',...
        nCase,...
        logicalString{testCases(nCase).Corr.Isotropic+1},...
        testCases(nCase).Corr.Type,...
        CorrFamilyStr,...
        max(curr_error_mu), max(curr_error_var),...
        logicalString{passCases(nCase) + 1})
    if ~passCases(nCase)
        return
    end
end

pass = all(passCases);

end
