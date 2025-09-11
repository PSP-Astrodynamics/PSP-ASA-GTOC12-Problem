function pass = uq_Dispatcher_tests_usage_MapBasic(DispatcherObj)
%UQ_DISPATCHER_TESTS_USAGE_MAPBASIC tests the most basic functionality
%   of a DISPATCHER object to dispatch the uq_map command.

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

% Specify the inputs
inputs = {linspace(1,10); linspace(1,100); linspace(1,1000);...
    [0 2 3]; [1 2 3 4 5 6 7]; rand(10,3)};

% Local computation as reference value
YLocal = uq_map(@sum,inputs);

%% Single Process, Synchronized

% Make sure to test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation
Y = uq_map(@sum, inputs, DispatcherObj);

% Assert the equality of the results
assert(isequal(Y,YLocal))

%% Single Process, Non-synchronized

% Dispatch the computation
uq_map(@sum, inputs, DispatcherObj, 'ExecMode', 'async');

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
Y = uq_map(@sum, inputs, DispatcherObj);

% Assert the equality of the results
assert(isequal(Y,YLocal))

%% Multiple Processes, Non-synchronized

% Dispatch the computation
uq_map(@sum, inputs, DispatcherObj, 'ExecMode', 'async');

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
