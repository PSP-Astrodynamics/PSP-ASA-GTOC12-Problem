function pass = uq_Dispatcher_tests_usage_KrigingMultiOutArgs(DispatcherObj)
%UQ_DISPATCHER_TESTS_USAGE_KRIGINGMULTIOutArgs tests a dispatched
%   computation of a Kriging model having multiple output arguments.
%
%   NOTE:
%   - 'uq_iscloseall' is used to test equalities because the remote MATLAB
%     version may differ and this causes a very small different between
%     the computed numbers.

%% Initialize the test
fprintf('Testing: | %s | %s...', DispatcherObj.Name, mfilename)

rng(100,'twister')  % Set random number for reproducibility

% Save current Dispatcher object settings
displayOpt = DispatcherObj.Internal.Display;
execMode = DispatcherObj.ExecMode;
numProcs = DispatcherObj.NumProcs;

% Make sure that the display option is quiet
DispatcherObj.Internal.Display = 0;

%% Computational model

% Create a MODEL object using a string
ModelOpts.mString = 'X.*sin(X)';
ModelOpts.isVectorized = true;

myModel = uq_createModel(ModelOpts,'-private');

%% Probabilistic input model

% Specify the probabilistic model of the input variable
InputOpts.Marginals.Type = 'Uniform';
InputOpts.Marginals.Parameters = [0 15];

% Create an INPUT object:
myInput = uq_createInput(InputOpts,'-private');

%% Experimental design

% Generate an experimental design
X = uq_getSample(myInput, 8,'LHS');

% Evaluate the corresponding model responses
Y = uq_evalModel(myModel,X);

%% Kriging metamodel

% Select the metamodeling tool and the Kriging module
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'Kriging';
MetaOpts.Display = 'quiet';

% Use the experimental design and corresponding model responses
MetaOpts.ExpDesign.X = X;
MetaOpts.ExpDesign.Y = Y;

% Create the Kriging metamodel:
myKriging = uq_createModel(MetaOpts,'-private');

%% Validation data set

% Create a validation set of size 1'000 over a regular grid
Xval = uq_getSample(myInput, 1e3, 'grid');

% Evaluate the Kriging surrogate locally:
[YMeanLocal,YVarLocal,YCovLocal] = uq_evalModel(myKriging,Xval);

%% Synchronized dispatched computation (single process)

% Make sure the dispatched computation is synchronized
DispatcherObj.ExecMode = 'sync';

% Test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the Kriging surrogate predictions on the validation set
[YMean,YVar,YCov] = uq_evalModel(myKriging, Xval, 'HPC');

% Assert the equality of all outputs:
assert(uq_iscloseall(YMeanLocal,YMean));
% Increase tolerance because some values may be close to zero
assert(uq_iscloseall(YVarLocal,YVar,'ATol',1e-6));
assert(uq_iscloseall(YCovLocal,YCov)); 

%% Synchronized dispatched computation (multiple processes)

% Test with multiple remote processes
DispatcherObj.NumProcs = 3;

% Dispatch the Kriging surrogate predictions on the validation set
% (Covariance matrix cannot be computed when there are multiple remote
% processes; it returns an empty array)
warning('off')  % Supress expected warning
[YMean,YVar,YCov] = uq_evalModel(myKriging,Xval,'HPC');
warning('on')

% Assert the equality of all outputs:
assert(uq_iscloseall(YMeanLocal,YMean));
% Increase tolerance because some values may be close to zero
assert(uq_iscloseall(YVarLocal,YVar,'ATol',1e-6));
assert(isempty(YCov));

%% Non-synchronized dispatched computation (single process)

% Make sure the dispatched computation is not synchronized
DispatcherObj.ExecMode = 'async';

% Test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the Kriging surrogate predictions on the validation set
[~,~,~] = uq_evalModel(myKriging,Xval,'HPC');

% Wait for the Job to finish:
uq_waitForJob(DispatcherObj)

% Fetch the results
[YMean,YVar,YCov] = uq_fetchResults(DispatcherObj);

% Assert the equality of all outputs
assert(uq_iscloseall(YMeanLocal,YMean));
% Increase tolerance because some values may be close to zero
assert(uq_iscloseall(YVarLocal,YVar,'ATol',1e-6));
assert(uq_iscloseall(YCovLocal,YCov)); 

%% Non-synchronized dispatched computation (multiple processes)

% Test with multiple remote processes
DispatcherObj.NumProcs = 3;

% Dispatch the Kriging surrogate predictions on the validation set
warning('off')  % Supress expected warning
[~,~,YCov] = uq_evalModel(myKriging,Xval,'HPC');
warning('on')

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results (only two results are available)
[YMean,YVar] = uq_fetchResults(DispatcherObj);

% Assert the equality of all outputs
assert(uq_iscloseall(YMeanLocal,YMean));
% Increase tolerance because some values may be close to zero
assert(uq_iscloseall(YVarLocal,YVar,'ATol',1e-6));
assert(isempty(YCov)); 

%% Revert any changes made on the Dispatcher object
DispatcherObj.Internal.Display = displayOpt;
DispatcherObj.ExecMode = execMode;
DispatcherObj.NumProcs = numProcs;

%% Return the results
fprintf('PASS\n')

pass = true;

end
