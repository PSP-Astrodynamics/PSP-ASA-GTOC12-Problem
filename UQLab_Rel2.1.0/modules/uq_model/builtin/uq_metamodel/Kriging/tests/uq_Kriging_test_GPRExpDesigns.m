function pass = uq_Kriging_test_GPRExpDesigns(level)
%UQ_KRIGING_TEST_GPREXPDESIGNS tests input options in GP regression.
%
%   The tests make sure that Kriging for regression works with various
%   input/experimental design options regardless the scaling option.
%
%   PASS = UQ_KRIGING_TEST_REGRESSION_EXPDESIGNS(LEVEL) tests the
%   available input/experimental design options in the Kriging module 
%   for regression.

%   The test function is the Runge function added with small noise.
%   The test parameters are:
%       1) Input scaling (3): 'true', 'false', or 'Input'
%       2) Experimental design (5): 'Input', 'User', 'Data', 'Data+Input'
%           - 'Input': INPUT object is assigned.
%           - 'User': user-defined experimental design is assigned.
%           - 'User+Input': user-defined experimental design and an INPUT 
%              object are assigned (for scaling purpose).
%           - 'Data': user-defined experimental design in a file is
%              assigned.
%           - 'Data+Input': user-defined experimental design in a file and 
%              and INPUT object are assigned (for scaling purpose).
%
%   Exhaustive test consist of 11 test cases. For 'normal' level test,
%   all test cases are carried out.

%% Initialize the test
%
uqlab('-nosplash')

if nargin < 1
    level = 'normal'; 
end

fprintf('\nRunning: |%s| uq_Kriging_test_GPRExpDesigns...\n',level);

%% Define test parameters
%
rng(75415,'twister')
Ntrain = 50;
Nvalid = 500;
eps = 5e-2;

%% Create a noisy experimental design
%
% Create INPUT object
InputOpts.Marginals.Type = 'Uniform';
InputOpts.Marginals.Parameters = [-1 1];
testInput = uq_createInput(InputOpts);
% Create MODEL object (Runge function)
ModelOptsTrue.Name = 'RungeTrue';
ModelOptsTrue.mFile = 'uq_runge';
trueModel = uq_createModel(ModelOptsTrue);
% Create MODEL object (Noisy Runge function)
ModelOptsNoisy.Name = 'RungeNoisy';
ModelOptsNoisy.mString = ['(ones(size(X)) + 25 * X.^2).^-1 ',...
    '+ 0.01*randn(size(X,1),1)'];
noisyModel = uq_createModel(ModelOptsNoisy);
% Create Experimental Design (Training)
Xtrain = uq_getSample(Ntrain,'Sobol');
Ytrain = uq_evalModel(noisyModel,Xtrain);
% Create Experimental design (Validation)
Xvalid = uq_getSample(Nvalid,'Sobol');
Yvalid = uq_evalModel(trueModel,Xvalid);

%% Define an INPUT object for scaling
%
InputOpts.Marginals.Type = 'Uniform';
InputOpts.Marginals.Parameters = [-1.5 1.5];
scalingInput = uq_createInput(InputOpts);

%% Create test cases
%
ExpDesign = {'Input', 'User', 'Data', 'User+Input', 'Data+Input'};
scaling = {false, true, scalingInput};
ScalingStr = {'false', 'true', 'Input'};
% Get the indices of all possible combinations
combIdx = uq_findAllCombinations(ExpDesign,scaling);
% Scaling with INPUT object only applies if INPUT object is used as the
% Kriging model INPUT. Thus, exclude all other use cases of Exp.Design.
combIdx(combIdx(:,1)~=1 & combIdx(:,2)==3,:) = [];

%% Define common Kriging options
%
% Kriging metamodel
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'Kriging';
MetaOpts.Display = 'quiet';
% Regression option
MetaOpts.Regression.SigmaNSQ = 'auto';
% Optimization options
MetaOpts.Optim.InitialValue = 0.5;
MetaOpts.Optim.Bounds = [0.01; 3];
MetaOpts.Optim.Method = 'cmaes';
% Trend options
MetaOpts.Trend.Type = 'polynomial';
MetaOpts.Trend.Degree = 3;
MetaOpts.Trend.PolyTypes = 'simple_poly';

%% Create the datafile and define it in ExpDesign
%
X = Xtrain;
Y = Ytrain; 
fname = 'KrigValTest.mat';
save(fname, 'X', 'Y')

%% Display the header for the test iterations
%
LogicalString = {'false', 'true'};
headerString = {'No.', 'Scaling', 'Exp.Design', 'Rel.Err.', 'Success'};
fprintf('\n%5s %7s %11s %10s %7s\n',headerString{:})
FormatString = '%5d %7s %11s %10.3e %7s\n';

%% Loop over test cases
%
nCases = size(combIdx,1);
pass = false(nCases,1);
for nCase = 1:nCases

    % Create a Kriging metamodel
    MetaOpts.Name = [];
    MetaOpts.Scaling = scaling{combIdx(nCase,2)};
    switch ExpDesign{combIdx(nCase,1)}
        case 'Input'
            MetaOpts.FullModel = noisyModel;
            MetaOpts.Input = testInput;
            MetaOpts.ExpDesign.NSamples = Ntrain;
            MetaOpts.ExpDesign.Sampling = 'Sobol';
            myKriging = uq_createModel(MetaOpts);
        case 'User'
            MetaOpts.Input = [];
            MetaOpts.ExpDesign.User = 'User';
            MetaOpts.ExpDesign.X = Xtrain;
            MetaOpts.ExpDesign.Y = Ytrain;
            myKriging = uq_createModel(MetaOpts);
        case 'User+Input'
            MetaOpts.Input = testInput;
            MetaOpts.ExpDesign.User = 'User';
            MetaOpts.ExpDesign.X = Xtrain;
            MetaOpts.ExpDesign.Y = Ytrain;
            myKriging = uq_createModel(MetaOpts);
        case 'Data'
            MetaOpts.Input = [];
            MetaOpts.ExpDesign.Sampling = 'Data';
            MetaOpts.ExpDesign.DataFile = fname;
            myKriging = uq_createModel(MetaOpts);
        case 'Data+Input'
            MetaOpts.Input = testInput;
            MetaOpts.ExpDesign.Sampling = 'Data';
            MetaOpts.ExpDesign.DataFile = fname;
            myKriging = uq_createModel(MetaOpts);
    end

    % Predict at the validation points
    Ypred = uq_evalModel(myKriging,Xvalid);
    predictError = sqrt(mean((Yvalid - Ypred).^2))/std(Yvalid);
    pass(nCase) = predictError < eps;

    % Clear experimental design options
    MetaOpts = rmfield(MetaOpts,'ExpDesign');

    % Print the results
    fprintf(FormatString,...
        nCase,...
        ScalingStr{combIdx(nCase,2)},...
        ExpDesign{combIdx(nCase,1)},...
        predictError,...
        LogicalString{pass(nCase)+1})

end

eval(['delete ',fname]);

pass = all(pass);

end
