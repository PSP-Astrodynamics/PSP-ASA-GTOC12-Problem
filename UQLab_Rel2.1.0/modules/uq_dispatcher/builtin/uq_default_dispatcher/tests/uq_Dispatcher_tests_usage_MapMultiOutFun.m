function pass = uq_Dispatcher_tests_usage_MapMultiOutFun(DispatcherObj)
%UQ_DISPATCHER_TESTS_USAGE_MAPMULTIOUTFUN tests dispatched uq_map with 
%   a mapping function having multiple output arguments.

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
inputs = {'~/projects/uqlab-dispatcher/test_hpc/test_uqlink/example.mat';...
    '~/projects/uqlab-dispatcher/test_hpc';...
    '~/projects/uqlab/core/uq_license.p'};

% Local computation
[YLocal1,YLocal2,YLocal3] = uq_map(@fileparts,inputs);

%% Single Output, Single Process, Synchronized

% Make sure to test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation
Y = uq_map(@fileparts, inputs, DispatcherObj);

% Assert the equality of the results
assert(isequal(Y,YLocal1))

%% Single Output, Single Process, Synchronized

% Dispatch the computation
[Y1,Y2,Y3] = uq_map(@fileparts, inputs, DispatcherObj);

% Assert the equality of the results
assert(isequal(Y1,YLocal1))
assert(isequal(Y2,YLocal2))
assert(isequal(Y3,YLocal3))

%% Single Output, Single Process, Non-synchronized

% Dispatch the computation
uq_map(@fileparts, inputs, DispatcherObj, 'ExecMode', 'async');

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results
Y = uq_fetchResults(DispatcherObj);

% Assert the equality of the results
assert(isequal(Y,YLocal1))

%% Single Output, Single Process, Non-synchronized

% Dispatch the computation (request more than one output)
uq_map(@fileparts, inputs, DispatcherObj,...
    'ExecMode', 'async',...
    'NumOfOutArgs', 3);

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results (more than one output)
[Y1,Y2,Y3] = uq_fetchResults(DispatcherObj);

% Assert the equality of the results
assert(isequal(Y1,YLocal1))
assert(isequal(Y2,YLocal2))
assert(isequal(Y3,YLocal3))

%% Single Output, Multiple Processes, Synchronized

% Make sure to test with more than one remote process
DispatcherObj.NumProcs = 3;

% Dispatch the computation
Y = uq_map(@fileparts, inputs, DispatcherObj);

% Assert the equality of the results
assert(isequal(Y,YLocal1))

%% Multiple Outputs, Multiple Processes, Synchronized

% Dispatch the computation (request more than one output)
[Y1,Y2,Y3] = uq_map(@fileparts, inputs, DispatcherObj);

% Assert the equality of the results
assert(isequal(Y1,YLocal1))
assert(isequal(Y2,YLocal2))
assert(isequal(Y3,YLocal3))

%% Multiple Outputs, Multiple Processes, Non-synchronized

% Dispatch the computation (request more than one output)
uq_map(@fileparts, inputs, DispatcherObj,...
    'ExecMode', 'async',...
    'NumOfOutArgs', 3);

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results (more than one output)
[Y1,Y2,Y3] = uq_fetchResults(DispatcherObj);

% Assert the equality of the results
assert(isequal(Y1,YLocal1))
assert(isequal(Y2,YLocal2))
assert(isequal(Y3,YLocal3))

%% Revert any changes made on the Dispatcher object
DispatcherObj.ExecMode = execMode;
DispatcherObj.NumProcs = numProcs;
DispatcherObj.Internal.Display = displayOpt;

%% Return the results
fprintf('PASS\n')

pass = true;

end
