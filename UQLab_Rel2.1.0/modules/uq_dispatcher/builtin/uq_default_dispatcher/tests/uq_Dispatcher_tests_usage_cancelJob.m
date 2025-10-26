function pass = uq_Dispatcher_tests_usage_cancelJob(DispatcherObj)
%UQ_DISPATCHER_TESTS_USAGE_CANCELJOB tests the job cancel functionality of
%   the Dispatcher module.

%% Initialize the test
fprintf('Testing: | %s | %s...', DispatcherObj.Name, mfilename)

% Save current Dispatcher object settings
execMode = DispatcherObj.ExecMode;
displayOpt = DispatcherObj.Internal.Display;
numProcs = DispatcherObj.NumProcs;

%% Dispatch a computation

% Make sure display is quiet
DispatcherObj.Internal.Display = 0;

% Make sure the dispatch computation is carried out non-synchronously
DispatcherObj.ExecMode = 'async';

% Dispatch with one remote process
DispatcherObj.NumProcs = 1;

% Dispatch a computation (absurdly long 'calculation')
uq_map('sleep {1}', {10000,10000,10000}, DispatcherObj)

idx = numel(DispatcherObj.Jobs);
try
    % Cancel the dispatched computation
    uq_cancelJob(DispatcherObj,idx)

    % Get the Job status
    [jobStatusChar,jobStatusID] = uq_getStatus(DispatcherObj);

    % Assert results
    assert(isequal(jobStatusID,uq_getStatusID('canceled')))
    assert(strcmpi(jobStatusChar,uq_getStatusChar(0)))
    
    % Clean up
    uq_deleteJob(DispatcherObj,idx)

    % Return the results
    fprintf('PASS\n')
    pass = true;
catch
    % Clean up
    uq_deleteJob(DispatcherObj,idx)
    
    fprintf('FAILED\n')
    pass = false;
end

%% Revert any changes made on the Dispatcher object
DispatcherObj.Internal.Display = displayOpt;
DispatcherObj.ExecMode = execMode;
DispatcherObj.NumProcs = numProcs;

end
