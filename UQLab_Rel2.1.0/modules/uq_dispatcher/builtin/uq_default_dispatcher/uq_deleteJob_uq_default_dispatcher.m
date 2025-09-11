function uq_deleteJob_uq_default_dispatcher(DispatcherObj,jobIdx)
%UQ_DELETEJOB_UQ_DEFAULT_DISPATCHER deletes the specified Job in a
%   Dispatcher unit of a uq_default_dispatcher type.

%% Parse and verify inputs
displayOpt = DispatcherObj.Internal.Display;

%% Check the last Status of the Job
[~,statusID] = uq_getStatus(DispatcherObj,jobIdx);
unfinishedJobStatus = [2 3];
for i = 1:numel(jobIdx)
    if any(statusID(i) == unfinishedJobStatus)
        warning('Job %d is not finished; it cannot be deleted!',i)
        return
    end
end

%% Create a command to establish an SSH connection
sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);

% Maximum number of trials for attempting an SSH connection
maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;

for i = 1:numel(jobIdx)
    idx = jobIdx(i);
    %% Save the Job to be deleted for rolling back
    currentJob = DispatcherObj.Jobs(idx);
    
    try
        %% Remove the remote folder associate with the Job
        remoteFolder = DispatcherObj.Jobs(idx).RemoteFolder;
        % Safe guard against whitespaces in 'remoteFolder'
        remoteFolder = uq_Dispatcher_util_writePath(remoteFolder,'linux');

        cmdName = 'rm';
        cmdArgs = {'-rf',remoteFolder};

         % Display some information
        if displayOpt > 1
            msg = sprintf(...
                    '[DISPATCHER] Delete Job %d from Dispatcher *%s*',...
                    idx, DispatcherObj.Name);
            fprintf(uq_Dispatcher_util_dispMsg(msg))
        end
        
        uq_Dispatcher_util_runCLICommand(...
            cmdName, cmdArgs, sshConnect, 'MaxNumTrials', maxNumTrials);
    
        % Display some information
        if displayOpt > 1
            fprintf('(OK)\n')
        end

        % Remove the Job for Jobs array
        DispatcherObj.Jobs(idx) = [];
        jobIdx = jobIdx - 1;
    
    catch ME
        
        % Display some information
        if displayOpt > 1
            msg = '[DISPATCHER] Something went wrong. Rolling back changes';
            fprintf(uq_Dispatcher_util_dispMsg(msg))
        end
        
        % Roll back any state change
        DispatcherObj.Jobs(idx) = currentJob;
    
        % Display some information
        if displayOpt > 1
            fprintf('(OK)\n')
        end
        
        rethrow(ME)
    end
end

end
