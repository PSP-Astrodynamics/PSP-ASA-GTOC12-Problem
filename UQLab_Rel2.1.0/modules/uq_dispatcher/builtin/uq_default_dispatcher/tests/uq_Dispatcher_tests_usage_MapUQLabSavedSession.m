function pass = uq_Dispatcher_tests_usage_MapUQLabSavedSession(DispatcherObj)
%UQ_DISPATCHER_TESTS_USAGE_MAPUQLABSAVEDSESSION tests dispatched uq_map
%   with a UQLab function as the mapping function and the current local
%   UQLab session saved and loaded on the remote machine.

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

% Create a MODEL object
ModelOpts.Name = uq_createUniqueID;
ModelOpts.mString = '2*X';
myModel = uq_createModel(ModelOpts);

% Specify an input
X = transpose(linspace(1,3));

% Evaluate the MODEL objects on an input (used as the reference value)
YLocal = uq_evalModel(X);

%% Single Process, Synchronized

% Make sure to test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation, load UQLab on the remote machine
Y = uq_map(@uq_evalModel, X, DispatcherObj, 'SaveUQLabSession', true);

% Simplify the results
Y = [Y{:}]';

% Assert the equality of the results
assert(isequal(Y,YLocal))

%% Single Process, Non-synchronized

% Dispatch the computation
uq_map(@uq_evalModel, X, DispatcherObj,...
    'SaveUQLabSession', true,...
    'ExecMode', 'async');

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results
Y = uq_fetchResults(DispatcherObj);

% Simplify the results
Y = [Y{:}]';

% Assert the equality of the results
assert(isequal(Y,YLocal))

%% Multiple Processes, Synchronized

% Make sure to test with multiple remote processes
DispatcherObj.NumProcs = 3;

% Dispatch the computation
Y = uq_map(@uq_evalModel, X, DispatcherObj,...
    'SaveUQLabSession', true);

% Simplify the results
Y = [Y{:}]';

% Assert the equality of the results
assert(isequal(Y,YLocal))

%% Multiple Processes, Non-synchronized

% Dispatch the computation
uq_map(@uq_evalModel, X, DispatcherObj,...
    'SaveUQLabSession', true,...
    'ExecMode', 'async');

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results
Y = uq_fetchResults(DispatcherObj);

% Simplify the results
Y = [Y{:}]';

% Assert the equality of the results
assert(isequal(Y,YLocal))

%% Revert any changes made on the Dispatcher object
DispatcherObj.ExecMode = execMode;
DispatcherObj.NumProcs = numProcs;
DispatcherObj.Internal.Display = displayOpt;

%% Cleanup
uq_removeModel(myModel);

%% Return the results
fprintf('PASS\n')

pass = true;

end
