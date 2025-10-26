function pass = uq_Dispatcher_tests_usage_deleteJob(DispatcherObj)
%UQ_DISPATCHER_TESTS_USAGE_DELETEJOB tests the job delete functionality of
%   the Dispatcher module.

%% Initialize the test
fprintf('Testing: | %s | %s...', DispatcherObj.Name, mfilename)

% Save current Dispatcher object settings
execMode = DispatcherObj.ExecMode;
displayOpt = DispatcherObj.Internal.Display;
numProcs = DispatcherObj.NumProcs;

% Make sure display is quiet
DispatcherObj.Internal.Display = 0;

%% Dispatch a computation

% Make sure the dispatch computation is carried out non-synchronously
DispatcherObj.ExecMode = 'async';

% Dispatch with one remote process
DispatcherObj.NumProcs = 1;

% Dispatch a computation
uq_map('echo {1}', {1,1,1}, DispatcherObj)

% Get the current Job index
idx = numel(DispatcherObj.Jobs);

% Get the current Job remote folder
remoteFolder = DispatcherObj.Jobs(idx).RemoteFolder;

% Get the command to make the SSH connection
sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Cancel the dispatched computation
uq_deleteJob(DispatcherObj,idx)

% Assert results
assert(isequal(idx,numel(DispatcherObj.Jobs)+1))
assert(~uq_Dispatcher_util_checkDir(remoteFolder, sshConnect, 5))

%% Revert any changes made on the Dispatcher object
DispatcherObj.Internal.Display = displayOpt;
DispatcherObj.ExecMode = execMode;
DispatcherObj.NumProcs = numProcs;

%% Return the results
fprintf('PASS\n')
pass = true;

end
