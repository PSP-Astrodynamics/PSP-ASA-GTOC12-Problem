function pass = uq_Dispatcher_tests_usage_DefModelMultiOutArgs(DispatcherObj)
%UQ_DISPATCHER_TESTS_USAGE_DEFMODELMULTIOUTARGS tests a dispatched
%   computation of a default model having multiple output arguments.
%
%   NOTE:
%   - This tests uses a function named 'uq_modelMultiOutArgs' which has a
%     multiple output arguments.

%% Initialize the test
fprintf('Testing: | %s | %s...', DispatcherObj.Name, mfilename)

rng(100,'twister')  % Set random number for reproducibility

% Save current Dispatcher object settings
execMode = DispatcherObj.ExecMode;
displayOpt = DispatcherObj.Internal.Display;
numProcs = DispatcherObj.NumProcs;

% Make things quiet
DispatcherObj.Internal.Display = 0;

%% Computational model

% Create a MODEL object from an m-file
ModelOpts.mFile = 'uq_modelMultiOutArgs';
ModelOpts.isVectorized = true;

myModel = uq_createModel(ModelOpts,'-private');

%% Probabilistic input model

% Specify the probabilistic model of the input variable
InputOpts.Marginals(1).Name = 'b'; % beam width
InputOpts.Marginals(1).Type = 'Lognormal';
InputOpts.Marginals(1).Moments = [0.15 0.0075]; % (m)

InputOpts.Marginals(2).Name = 'h'; % beam height
InputOpts.Marginals(2).Type = 'Lognormal';
InputOpts.Marginals(2).Moments = [0.3 0.015]; % (m)

InputOpts.Marginals(3).Name = 'L'; % beam length
InputOpts.Marginals(3).Type = 'Lognormal';
InputOpts.Marginals(3).Moments = [5 0.05]; % (m)

InputOpts.Marginals(4).Name = 'E'; % Young's modulus
InputOpts.Marginals(4).Type = 'Lognormal';
InputOpts.Marginals(4).Moments = [3e10 4.5e9]; % (Pa)

InputOpts.Marginals(5).Name = 'p'; % uniform load
InputOpts.Marginals(5).Type = 'Lognormal';
InputOpts.Marginals(5).Moments = [1e4 2e3]; % (N/m)

% Create an INPUT object
myInput = uq_createInput(InputOpts,'-private');

%% Validation data set

% Create a validation set
X = uq_getSample(myInput,1e3);

% Evaluate the model locally
[Y1Lcl,Y2Lcl,Y3Lcl,Y4Lcl,Y5Lcl,Y6Lcl,Y7Lcl,Y8Lcl,Y9Lcl,YAllLcl] = ...
    uq_evalModel(myModel,X);

%% Synchronized dispatched computation (single process)

% Make sure the dispatched computation is synchronized
DispatcherObj.ExecMode = 'sync';

% Test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation
[Y1,Y2,Y3,Y4,Y5,Y6,Y7,Y8,Y9,YAll] = uq_evalModel(myModel, X, 'HPC');

% Assert the equality of all outputs
assert(isequal(...
    [Y1Lcl,Y2Lcl,Y3Lcl,Y4Lcl,Y5Lcl,Y6Lcl,Y7Lcl,Y8Lcl,Y9Lcl],...
    [Y1,Y2,Y3,Y4,Y5,Y6,Y7,Y8,Y9]))
assert(isequal(YAllLcl,YAll))

%% Synchronized dispatched computation (multiple processes)

% Test with multiple remote processes
DispatcherObj.NumProcs = 3;

% Dispatch the computation
[Y1,Y2,Y3,Y4,Y5,Y6,Y7,Y8,Y9,YAll] = uq_evalModel(myModel, X, 'HPC');

% Assert the equality of all outputs
assert(isequal(...
    [Y1Lcl,Y2Lcl,Y3Lcl,Y4Lcl,Y5Lcl,Y6Lcl,Y7Lcl,Y8Lcl,Y9Lcl],...
    [Y1,Y2,Y3,Y4,Y5,Y6,Y7,Y8,Y9]))
assert(isequal(YAllLcl,YAll))

%% Non-synchronized dispatched computation (single process)

% Make sure the dispatched computation is not synchronized
DispatcherObj.ExecMode = 'async';

% Test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation
[Y1,Y2,Y3,Y4,Y5,Y6,Y7,Y8,Y9,YAll] = uq_evalModel(myModel, X, 'HPC');

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results
[Y1,Y2,Y3,Y4,Y5,Y6,Y7,Y8,Y9,YAll] = uq_fetchResults(DispatcherObj);

% Assert the equality of all outputs
assert(isequal(...
    [Y1Lcl,Y2Lcl,Y3Lcl,Y4Lcl,Y5Lcl,Y6Lcl,Y7Lcl,Y8Lcl,Y9Lcl],...
    [Y1,Y2,Y3,Y4,Y5,Y6,Y7,Y8,Y9]))
assert(isequal(YAllLcl,YAll))

%% Non-synchronized dispatched computation (multiple process)

% Test with multiple remote processes
DispatcherObj.NumProcs = 3;

% Dispatch the computation
[Y1,Y2,Y3,Y4,Y5,Y6,Y7,Y8,Y9,YAll] = uq_evalModel(myModel, X, 'HPC');

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results (only two results are available)
[Y1,Y2,Y3,Y4,Y5,Y6,Y7,Y8,Y9,YAll] = uq_fetchResults(DispatcherObj);

% Assert the equality of all outputs
assert(isequal(...
    [Y1Lcl,Y2Lcl,Y3Lcl,Y4Lcl,Y5Lcl,Y6Lcl,Y7Lcl,Y8Lcl,Y9Lcl],...
    [Y1,Y2,Y3,Y4,Y5,Y6,Y7,Y8,Y9]))
assert(isequal(YAllLcl,YAll))

%% Revert any changes made on the Dispatcher object
DispatcherObj.Internal.Display = displayOpt;
DispatcherObj.ExecMode = execMode;
DispatcherObj.NumProcs = numProcs;

%% Return the results
fprintf('PASS\n')

pass = true;

end
