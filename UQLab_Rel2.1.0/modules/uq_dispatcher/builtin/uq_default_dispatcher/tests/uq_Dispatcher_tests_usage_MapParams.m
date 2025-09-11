function pass = uq_Dispatcher_tests_usage_MapParams(DispatcherObj)
%UQ_DISPATCHER_TESTS_USAGE_MAPPARAMS tests dispatched uq_map with a
%   specified parameters to the mapping function.
%
%   NOTE:
%   - The test also includes testing the 'AttachedFiles' named argument. 

%% Inititialize the test
fprintf('Testing: | %s | %s...', DispatcherObj.Name, mfilename)

rng(100,'twister')  % Set random number for reproducibility

% Save current Dispatcher object settings
execMode = DispatcherObj.ExecMode;
numProcs = DispatcherObj.NumProcs;
displayOpt = DispatcherObj.Internal.Display;

% Make things quiet
DispatcherObj.Internal.Display = 0;

%% Test Setup

% Specify the inputs
X = [0 0 0; 0.5*pi 0.5*pi 0.5*pi; pi pi pi];

% Specify the parameters
P.a = 10;
P.b = 0.5;

% Local computation as the reference value
YLocal = uq_map(@uq_Dispatcher_tests_support_myFunction, X,...
    'MatrixMapping', 'ByRows', 'Parameters', P);

% File to attach (normally this is not necessary for a single function if
% the function is not located inside the UQLab module folders)
attachedFiles = fullfile(uq_rootPath, 'modules', 'uq_dispatcher',...
    'builtin', 'uq_default_dispatcher', 'tests', 'support_files',...
    'uq_Dispatcher_tests_support_myFunction.m');

%% Single Process, Synchronized

% Make sure to test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation
Y = uq_map(@uq_Dispatcher_tests_support_myFunction, X, DispatcherObj,...
    'MatrixMapping', 'ByRows',...
    'Parameters', P,...
    'AttachedFiles', attachedFiles);

% Assert the equality of the results
assert(isequal(Y,YLocal))

%% Single Process, Non-synchronized

% Dispatch the computation
uq_map(@uq_Dispatcher_tests_support_myFunction, X, DispatcherObj,...
    'ExecMode', 'async',...
    'MatrixMapping', 'ByRows',...
    'Parameters', P,...
    'AttachedFiles', attachedFiles);

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Dispatch the computation
Y = uq_fetchResults(DispatcherObj);

% Assert the equality of the results
assert(isequal(Y,YLocal))

%% Multiple Processes, Synchronized

% Make sure to test with more than one remote process
DispatcherObj.NumProcs = 3;

% Dispatch the computation
Y = uq_map(@uq_Dispatcher_tests_support_myFunction, X, DispatcherObj,...
    'MatrixMapping', 'ByRows',...
    'Parameters', P,...
    'AttachedFiles', attachedFiles);

% Assert the equality of the results
assert(isequal(Y,YLocal))

%% Multiple Processes, Non-synchronized

% Dispatch the computation
uq_map(@uq_Dispatcher_tests_support_myFunction, X, DispatcherObj,...
    'ExecMode', 'async',...
    'MatrixMapping', 'ByRows',...
    'Parameters', P,...
    'AttachedFiles', attachedFiles);

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
