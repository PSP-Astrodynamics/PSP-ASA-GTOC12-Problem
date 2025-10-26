function pass = uq_Dispatcher_tests_usage_PCKMultiOutArgs(DispatcherObj)
%UQ_DISPATCHER_TESTS_USAGE_PCEMULTIOUTARGS tests a dispatched computation
%   of a PCK model having multiple output arguments.
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

% Create an INPUT object
myInput = uq_createInput(InputOpts);

%% PCK metamodel

% Select PCK as the metamodeling tool
PCKOpts.Type = 'Metamodel';
PCKOpts.MetaType = 'PCK';
PCKOpts.Display = 'quiet';

% Generate an experimental design
X = uq_getSample(myInput, 10, 'Sobol');
Y = uq_evalModel(myModel,X);

% Assign the experimental design to the metamodel specification
PCKOpts.ExpDesign.X = X;
PCKOpts.ExpDesign.Y = Y;

% Specify the range for the selection of the maximum polynomial degree
% of the trend
PCKOpts.PCE.Degree = 1:10;

% Create the Sequential PC-Kriging metamodel:
myPCK = uq_createModel(PCKOpts,'-private');

%% Validation data set

% Create a validation set of size $10^3$ over a regular grid:
XVal = uq_getSample(myInput, 1e3, 'grid');

% Evaluate the true model responses for the validation set:
[YPCKValLocal,YPCKVarLocal,YPCKCovLocal] = uq_evalModel(myPCK,XVal);

%% Synchronized dispatched computation (single process)

% Make sure the dispatched computation is synchronized
DispatcherObj.ExecMode = 'sync';

% Test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation
[YPCKVal,YPCKVar,YPCKCov] = uq_evalModel(myPCK, XVal, 'HPC');

% Assert the equality of all outputs
assert(uq_iscloseall(YPCKValLocal,YPCKVal))
% Increase tolerance because some values may be close to zero
assert(uq_iscloseall(YPCKVarLocal, YPCKVar, 'ATol', 1e-6))
assert(uq_iscloseall(YPCKCovLocal, YPCKCov, 'ATol', 1e-6))

%% Synchronized dispatched computation (multiple processes)

% Test with multiple remote processes
DispatcherObj.NumProcs = 3;

% Dispatch the computation (Covariance matrix cannot be computed when
% there are multiple remote processes; it returns an empty array)
warning('off')  % Supress expected warning
[YPCKVal,YPCKVar,YPCKCov] = uq_evalModel(myPCK, XVal, 'HPC');
warning('on')

% Assert the equality of all outputs
assert(uq_iscloseall(YPCKValLocal,YPCKVal))
% Increase tolerance because some values may be close to zero
assert(uq_iscloseall(YPCKVarLocal, YPCKVar, 'ATol', 1e-6))
assert(isempty(YPCKCov))

%% Non-synchronized dispatched computation (single process)

% Make sure the dispatched computation is not synchronized
DispatcherObj.ExecMode = 'async';

% Test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation
[~,~,~] = uq_evalModel(myPCK, XVal, 'HPC');

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results
[YPCKVal,YPCKVar,YPCKCov] = uq_fetchResults(DispatcherObj);

% Assert the equality of all outputs
assert(uq_iscloseall(YPCKValLocal,YPCKVal))
% Increase tolerance because some values may be close to zero
assert(uq_iscloseall(YPCKVarLocal, YPCKVar, 'ATol', 1e-6))
assert(uq_iscloseall(YPCKCovLocal, YPCKCov, 'ATol', 1e-6))

%% Non-synchronized dispatched computation (multiple process)

% Test with multiple remote processes
DispatcherObj.NumProcs = 3;

% Dispatch the computation (Covariance matrix cannot be computed when
% there are multiple remote processes; it returns an empty array)
warning('off')  % Supress expected warning
[~,~,YPCKCov] = uq_evalModel(myPCK, XVal, 'HPC');
warning('on')

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results (only two results are available)
[YPCKVal,YPCKVar] = uq_fetchResults(DispatcherObj);

% Assert the equality of all outputs
assert(uq_iscloseall(YPCKValLocal,YPCKVal))
% Increase tolerance because some values may be close to zero
assert(uq_iscloseall(YPCKVarLocal, YPCKVar, 'ATol', 1e-6))
assert(isempty(YPCKCov))

%% Revert any changes made on the Dispatcher object
DispatcherObj.Internal.Display = displayOpt;
DispatcherObj.ExecMode = execMode;
DispatcherObj.NumProcs = numProcs;

%% Return the results
fprintf('PASS\n')

pass = true;

end
