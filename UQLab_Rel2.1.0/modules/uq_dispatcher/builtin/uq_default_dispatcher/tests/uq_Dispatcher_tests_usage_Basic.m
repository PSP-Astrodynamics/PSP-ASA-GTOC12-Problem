function pass = uq_Dispatcher_tests_usage_Basic(DispatcherObj)
%UQ_DISPATCHER_TESTS_USAGE_BASIC tests the most basic functionality
%   of a DISPATCHER object to compute a MODEL evaluation.

%% Inititialize the test
fprintf('Testing: | %s | %s...', DispatcherObj.Name, mfilename)

rng(100,'twister')  % Set random number for reproducibility

% Save current Dispatcher object settings
execMode = DispatcherObj.ExecMode;
displayOpt = DispatcherObj.Internal.Display;

% Make things quiet
DispatcherObj.Internal.Display = 0;

%% Computational model

% Specify the computational model using string
ModelOpts.mString = 'X.*sin(X)';
ModelOpts.isVectorized = true;

myModel = uq_createModel(ModelOpts,'-private');

%% Probabilistic input model

% Specify the probabilistic model of the input variable:
InputOpts.Marginals.Type = 'Uniform';
InputOpts.Marginals.Parameters = [0 15];

% Then create an INPUT object:
myInput = uq_createInput(InputOpts,'-private');

%% 4 - DISPATCHED MODEL EVALUATION USING A DISPATCHER OBJECT

%% Validation set

% Create a small set of test sample points:
X = uq_getSample(myInput,1e2);

% To verify the results of the dispatched computation, evaluate the same
% MODEL on the local machine:
Ylocal = uq_evalModel(myModel,X);

%% Synchronized test

% Make sure the dispatched computation is synchronized
DispatcherObj.ExecMode = 'sync';

% Dispatch the MODEL evaluation to the remote machine
Ydispatched = uq_evalModel(myModel, X, 'HPC');

% Assert the equality of local and dispatched computation
assert(isequal(Ydispatched,Ylocal))

%% Non-synchronized test

% Make sure the dispatched computation is not synchronized
DispatcherObj.ExecMode = 'async';

% Dispatch the MODEL evaluation to the remote machine
uq_evalModel(myModel, X, 'HPC');

% Wait for the dispatched computation to finish
uq_waitForJob(DispatcherObj)

% Fetch the remote results once finished
Ydispatched = uq_fetchResults(DispatcherObj);

% Assert the equality of local and dispatched computation
assert(isequal(Ydispatched,Ylocal))

%% Revert any changes made on the Dispatcher object
DispatcherObj.ExecMode = execMode;
DispatcherObj.Internal.Display = displayOpt;

%% Return the results
fprintf('PASS\n')

pass = true;

end
