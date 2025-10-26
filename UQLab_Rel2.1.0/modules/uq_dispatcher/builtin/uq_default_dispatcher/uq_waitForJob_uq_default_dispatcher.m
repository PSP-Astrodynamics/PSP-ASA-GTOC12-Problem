function waitStatus = uq_waitForJob_uq_default_dispatcher(...
    DispatcherObj, jobIdx, jobStatus, waitTimeout, checkInterval)
%UQ_WAITFORJOB_UQ_DEFAULT_DISPATCHER waits for a Job of the default dispatcher.

%% Set local variables
displayOpt = DispatcherObj.Internal.Display;

%% Start polling

startTime = clock;

while(true)

    %
    if displayOpt > 0
        fprintf('Checking the status of the remote execution...\n')
    end
    
    [~,statusID] = uq_getStatus(DispatcherObj,jobIdx);

    % statusID as requested
    if statusID == jobStatus
        if displayOpt > 0
            fprintf('Job Status: ''%s'' reached.\n',uq_getStatusChar(statusID))
        end
        waitStatus = true;
        return
    end
    
    % statusID == -1 or 4
    if any(statusID == [-1 4])
        if displayOpt > 0
            fprintf('Job Status: ''%s''.\n', uq_getStatusChar(statusID))
        end
        break
    end
        
    if etime(clock,startTime) > waitTimeout
        error('Timeout error. The Job may still be queued or running.')
    end
    
    % Wait a bit
    pause(checkInterval)

end

waitStatus = false;

end
