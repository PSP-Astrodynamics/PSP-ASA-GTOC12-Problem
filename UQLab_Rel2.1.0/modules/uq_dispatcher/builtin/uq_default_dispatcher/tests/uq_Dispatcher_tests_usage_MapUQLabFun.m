function pass = uq_Dispatcher_tests_usage_MapUQLabFun(DispatcherObj)
%UQ_DISPATCHER_TESTS_USAGE_MAPUQLABFUN tests dispatched uq_map with a UQLab
%   function as the mapping function.

%% Inititialize the test
fprintf('Testing: | %s | %s...', DispatcherObj.Name, mfilename)

rng(100,'twister')  % Set random number for reproducibility

% Save current Dispatcher object settings
execMode = DispatcherObj.ExecMode;
numProcs = DispatcherObj.NumProcs;
displayOpt = DispatcherObj.Internal.Display;

% Make sure that the display option is quiet
DispatcherObj.Internal.Display = 0;

%% Setup

% Specify the inputs
ModelOpts1.mString = '2*X';
ModelOpts2.mString = 'X+2';
ModelOpts3.mString = 'X+1';
inputs = {ModelOpts1;ModelOpts2;ModelOpts3};

% Create a set of MODEL objects
myModels = uq_map(@(X) uq_createModel(X,'-private'), inputs);

% Evaluate the MODEL objects on an input (used as the reference value)
YLocal = uq_map(@(X) uq_evalModel(X,10), myModels);

%% Single Process, Synchronized

% Make sure to test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation, load UQLab on the remote machine
myModels = uq_map(@uq_createModel, inputs, DispatcherObj,...
    'UQLab', true);

% Evaluate the resulting model on an input
Y = uq_map(@(X) uq_evalModel(X,10), myModels);

% Assert the equality of the results
assert(isequal(Y,YLocal))

%% Single Process, Non-synchronized

% Dispatch the computation, load UQLab on the remote machine
uq_map(@uq_createModel, inputs, DispatcherObj,...
    'UQLab', true,...
    'ExecMode', 'async');

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results
myModels = uq_fetchResults(DispatcherObj);

% Evaluate the resulting MODEL objects on an input
Y = uq_map(@(X) uq_evalModel(X,10), myModels);

% Assert the equality of the results
assert(isequal(Y,YLocal))

%% Multiple Processes, Synchronized

% Make sure to test with multiple remote processes
DispatcherObj.NumProcs = 3;

% Dispatch the computation, load UQLab on the remote machine
myModels = uq_map(@uq_createModel, inputs, DispatcherObj,...
    'UQLab', true);

% Evaluate the resulting MODEL objects on an input
Y = uq_map(@(X) uq_evalModel(X,10), myModels);

% Assert the equality of the results
assert(isequal(Y,YLocal))

%% Multiple Processes, Non-synchronized

% Dispatch the computation, load UQLab on the remote machine
uq_map(@uq_createModel, inputs, DispatcherObj,...
    'UQLab', true,...
    'ExecMode', 'async');

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results
myModels = uq_fetchResults(DispatcherObj);

% Evaluate the resulting MODEL objects on an input
Y = uq_map(@(X) uq_evalModel(X,10), myModels);

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
