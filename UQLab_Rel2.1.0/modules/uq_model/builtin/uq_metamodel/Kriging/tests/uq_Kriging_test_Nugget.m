function pass = uq_Kriging_test_Nugget(level)
%UQ_KRIGING_TEST_NUGGET(LEVEL) tests for the nugget support in the Kriging module.
%
%   Summary:
%   Make sure that various Kriging configurations are working as expected
%   when using nugget. With a 0 nugget, Kriging should interpolate even
%   for a noisy data.

%% Initialize the test
rng(100,'twister')
uqlab('-nosplash')
if nargin < 1
    level = 'normal';
end
evalc('uqlab');

fprintf('\nRunning: |%s| uq_Kriging_test_Nugget...\n',level)

% Test parameters
thresh = 1e-10;   % Numerical threshold for float comparions
N = 50;           % Number of sample points

%% Create experimental design

% Full computational model
ModelOpts.mString = 'X.*sin(X)';
ModelOpts.isVectorized = true;

myModel = uq_createModel(ModelOpts,'-private');

% Probabilistic input model
InputOpts.Marginals.Type = 'Uniform';
InputOpts.Marginals.Parameters = [0 15];

myInput = uq_createInput(InputOpts,'-private');

% Create experimental design
X = uq_getSample(myInput,N,'LHS');
Y = uq_evalModel(myModel,X) + randn(N,1);

%% Common Kriging setup
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'Kriging';
MetaOpts.Display = 'quiet';

MetaOpts.ExpDesign.X = X;
MetaOpts.ExpDesign.Y = Y;

%% With zero nugget it should interpolate
MetaOpts.Corr.Nugget = 0.0;
% Create the Kriging metamodel:
myKriging = uq_createModel(MetaOpts,'-private');

[YmuED,YvarED] = uq_evalModel(myKriging,myKriging.ExpDesign.X);

isInterpolateMu = all(abs(YmuED-Y) < thresh);
isInterpolateVar = all(YvarED < thresh);
if isInterpolateMu && isInterpolateVar
    pass = true;
else
    pass = false;
    return
end

%% With a non-zero nugget it should not interpolate
MetaOpts.Corr.Nugget = 1e-4;

% Create the Kriging metamodel:
myKriging = uq_createModel(MetaOpts,'-private');

YvarPred = zeros(N,1);
for i = 1:N
    % Compute the prediction points one by one
    [~,YvarPred(i)] = uq_evalModel(myKriging,X(i));
end
[YmuED,YvarED] = uq_evalModel(myKriging,myKriging.ExpDesign.X);

isInterpolateMu = all(abs(YmuED - Y) < thresh);
% Variance of the experimental design should be the same
% as the variance of prediction (it might not be zero)
isVarEDeqVarPred = all(abs(YvarPred-YvarED) < thresh);
% Should not interpolate
if ~isInterpolateMu && isVarEDeqVarPred
    pass = true;
else
    pass = false;
    return
end

end
