function pass = uq_Dispatcher_tests_usage_MapAnonFun(DispatcherObj)
%UQ_DISPATCHER_TESTS_USAGE_MAPANONFUN tests the most basic functionality
%   of a DISPATCHER object to dispatch a map function.

%% Inititialize the test
fprintf('Testing: | %s | %s...', DispatcherObj.Name, mfilename)

rng(100,'twister')  % Set random number for reproducibility

% Save current Dispatcher object settings
execMode = DispatcherObj.ExecMode;
numProcs = DispatcherObj.NumProcs;
displayOpt = DispatcherObj.Internal.Display;

% Make sure that the display option is quiet
DispatcherObj.Internal.Display = 0;

%% Test Setup

% To illustrate this feature, define an anonymous function:
mse = @(X) sqrt(mean((X(:,1) - X(:,2)).^2)); 

% Generate several illustrative data sets:
inputs = {...
    [randn(1e2,1),randn(1e2,1)];...
    [randn(1e3,1),randn(1e3,1)];...
    [randn(1e4,1),randn(1e4,1)]};

% Local computation as the reference value
YLocal = uq_map(mse,inputs);

%% Single Process, Synchronized

% Make sure to test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation
Y = uq_map(mse, inputs, DispatcherObj);

% Assert the equality of the results
assert(isequal(Y,YLocal))

%% Single Process, Non-synchronized

% Dispatch the computation
uq_map(mse, inputs, DispatcherObj, 'ExecMode', 'async');

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results
Y = uq_fetchResults(DispatcherObj);

% Assert the equality of the results
assert(isequal(Y,YLocal))

%% Multiple Processes, Synchronized

% Make sure to test with more than one remote process
DispatcherObj.NumProcs = 3;

% Dispatch the computation
Y = uq_map(mse, inputs, DispatcherObj);

% Assert the equality of the results
assert(isequal(Y,YLocal))

%% Multiple Processes, Non-synchronized

% Dispatch the computation
uq_map(mse, inputs, DispatcherObj, 'ExecMode', 'async');

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results
Y = uq_fetchResults(DispatcherObj);

% Assert the equality of the results
assert(isequal(Y,YLocal))

%% Revert any changes made on the Dispatcher object
DispatcherObj.ExecMode = execMode;
DispatcherObj.NumProcs = numProcs;
DispatcherObj.Internal.Display = displayOpt;

%% Return the results
fprintf('PASS\n')

pass = true;

end
