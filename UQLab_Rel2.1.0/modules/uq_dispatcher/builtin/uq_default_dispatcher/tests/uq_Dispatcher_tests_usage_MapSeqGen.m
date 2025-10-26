function pass = uq_Dispatcher_tests_usage_MapSeqGen(DispatcherObj)
%UQ_DISPATCHER_TESTS_USAGE_MAPSEQGEN tests dispatched uq_map with a
%   user-defined sequence generator as the input sequence.
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

% Specify the sequence generator parameters
seqGenParams = {0.5,1,100};

% Specify the inputs
X = uq_Dispatcher_tests_support_mySeqGen(seqGenParams{:});

% Local computation as the reference value
YLocal = uq_map(@(X) mean(X), X, 'MatrixMapping', 'ByColumns');

% File to attach (normally this is not necessary for a single function if
% the function is not located inside the UQLab module folders)
attachedFiles = fullfile(uq_rootPath, 'modules', 'uq_dispatcher',...
    'builtin', 'uq_default_dispatcher', 'tests', 'support_files',...
    'uq_Dispatcher_tests_support_mySeqGen.m');

%% Single Process, Synchronized

% Make sure to test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation
Y = uq_map(@(X) mean(X), @uq_Dispatcher_tests_support_mySeqGen,...
    DispatcherObj,...
    'MatrixMapping', 'ByColumns',...
    'SeqGenParameters', seqGenParams,...
    'InputSize', [1e5, 1e2],...
    'AttachedFiles', attachedFiles);

% Assert the equality of the results
assert(uq_iscloseall([Y{:}],[YLocal{:}]))

%% Single Process, Non-synchronized

% Dispatch the computation
uq_map(@(X) mean(X), @uq_Dispatcher_tests_support_mySeqGen,...
    DispatcherObj,...
    'MatrixMapping', 'ByColumns',...
    'SeqGenParameters', seqGenParams,...
    'InputSize', [1e5, 1e2],...
    'ExecMode', 'async',...
    'AttachedFiles', attachedFiles);

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Dispatch the computation
Y = uq_fetchResults(DispatcherObj);

% Assert the equality of the results
assert(uq_iscloseall([Y{:}],[YLocal{:}]))

%% Multiple Processes, Synchronized

% Make sure to test with more than one remote process
DispatcherObj.NumProcs = 3;

% Dispatch the computation
Y = uq_map(@(X) mean(X), @uq_Dispatcher_tests_support_mySeqGen,...
    DispatcherObj,...
    'MatrixMapping', 'ByColumns',...
    'SeqGenParameters', seqGenParams,...
    'InputSize', [1e5, 1e2],...
    'AttachedFiles', attachedFiles);

% Assert the equality of the results
assert(uq_iscloseall([Y{:}],[YLocal{:}]))

%% Built-in MATLAB, Single Output, Multiple Processes, Non-synchronized

% Dispatch the computation
uq_map(@(X) mean(X), @uq_Dispatcher_tests_support_mySeqGen,...
    DispatcherObj,...
    'MatrixMapping', 'ByColumns',...
    'SeqGenParameters', seqGenParams,...
    'ExecMode', 'async',...
    'InputSize', [1e5, 1e2],...
    'AttachedFiles', attachedFiles);

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results
Y = uq_fetchResults(DispatcherObj);

% Assert the equality of the results
assert(uq_iscloseall([Y{:}],[YLocal{:}]))

%% Revert any changes made on the Dispatcher object
DispatcherObj.ExecMode = execMode;
DispatcherObj.NumProcs = numProcs;
DispatcherObj.Internal.Display = displayOpt;

%% Return the results
fprintf('PASS\n')

pass = true;

end
