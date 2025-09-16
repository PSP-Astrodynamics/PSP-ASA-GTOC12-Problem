function uq_updateStatus_uq_default_dispatcher(DispatcherObj,jobIdx)
%UQ_UPDATESTATUS_UQ_DEFAULT_DISPATCHER updates the status of a Job in a
%   DISPATCHER unit of uq_default_dispatcher type. 

%% Create SSH connect
sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);

% Maximum number of trials for attempting an SSH connection
maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;

%% Save current Job as backup for rolling back changes
currentJob = DispatcherObj.Jobs(jobIdx);
currentJobStatus = currentJob.Status;

%% Check if the remote directory is still intact
remoteFolder = currentJob.RemoteFolder;
if ~uq_Dispatcher_util_checkDir(remoteFolder, sshConnect, maxNumTrials)
    error('Remote folder associated with the Job does not exist any more.')
end

%% Check if Job is 'error'/'canceled'/'complete' (ID==-1,0,4)
% Then update LastUpdateDateTime and return
if any(currentJobStatus == [-1 0 4])
    try
        nowDateTime = uq_Dispatcher_util_getNowDateTime(sshConnect,maxNumTrials);
        DispatcherObj.Jobs(jobIdx).LastUpdateDateTime = nowDateTime;
        return
    catch ME
        % Roll back any update
        DispatcherObj.Jobs(jobIdx) = currentJob;
        rethrow(ME)
    end
end

%% Check if Job has been submitted ('submitted')
if isempty(currentJob.SubmitDateTime)

    try
        % Get the status update for a 'submitted' job
        JobUpdates = uq_Dispatcher_status_getSubmitted(DispatcherObj,jobIdx);
        % Update the Job
        updateJob(DispatcherObj, jobIdx, JobUpdates)
        % If no status update, then return immediately, otherwise continue
        if ~isfield(JobUpdates,'Status')
            return
        end
    catch ME
         % Roll back changes
        DispatcherObj.Jobs(jobIdx) = currentJob;
        rethrow(ME)
    end
end

%% Check if a previously submitted Job is already started ('running')
if isempty(currentJob.StartDateTime)
    
    try
        % Get the status update for a 'running' job
        JobUpdates = uq_Dispatcher_status_getRunning(DispatcherObj,jobIdx);
        updateJob(DispatcherObj, jobIdx, JobUpdates)
        % If no status update, then return immediately, otherwise continue
        if ~isfield(JobUpdates,'Status')
            return
        end
    catch ME
        % Roll back changes
        DispatcherObj.Jobs(jobIdx) = currentJob;
        rethrow(ME)
    end
    
end

%% Check if a previously running Job is now finished
% ('error', 'canceled', or 'complete')
if isempty(currentJob.FinishDateTime)

    % 'error', 'canceled', and 'completed' are all mutually exclusive.
    % Check if the Job is already finished, if so update status,
    % and return immediately. Otherwise, simply update time stats.

    try
        % Check for Job-wide error logfile
        JobUpdates = uq_Dispatcher_status_getErrorJob(...
            DispatcherObj,jobIdx);
        if ~isempty(JobUpdates)
            % Update the Job
            updateJob(DispatcherObj, jobIdx, JobUpdates)
            % ...and return
            return
        end
        
        % Check for process-based error logfiles
        JobUpdates = uq_Dispatcher_status_getErrorProcess(...
            DispatcherObj,jobIdx);
        if ~isempty(JobUpdates)
            % Update the Job
            updateJob(DispatcherObj, jobIdx, JobUpdates)
            % ...and return
            return
        end
    
        % Check for process-based completion logfiles
        JobUpdates = uq_Dispatcher_status_getComplete(...
            DispatcherObj,jobIdx);
        if ~isempty(JobUpdates)
            % Update the Job
            updateJob(DispatcherObj, jobIdx, JobUpdates)
            % ...and return
            return
        end
        
        % Job is still running, update time stats
        nowDateTime = uq_Dispatcher_util_getNowDateTime(sshConnect,maxNumTrials);
        startDateTime = DispatcherObj.Jobs(jobIdx).StartDateTime;
    
        DispatcherObj.Jobs(jobIdx).LastUpdateDateTime = nowDateTime;
        DispatcherObj.Jobs(jobIdx).RunningDuration = ...
            uq_Dispatcher_util_computeDuration(...
                startDateTime,nowDateTime);
        return

    catch ME
        % Roll back changes
        DispatcherObj.Jobs(jobIdx) = currentJob;
        rethrow(ME)
    end
    
end

%% Job was finished, just update LastUpdateDateTime
try
    % Get time stats
    nowDateTime = uq_Dispatcher_util_getNowDateTime(sshConnect,maxNumTrials);
    % Update Job
    DispatcherObj.Jobs(jobIdx) = nowDateTime;
catch ME
    % Roll back changes
    DispatcherObj.Jobs(jobIdx) = currentJob;
    rethrow(ME)
end

end

%% ------------------------------------------------------------------------
function updateJob(DispatcherObj, jobIdx, JobUpdate)

fnames = fieldnames(JobUpdate);
for i = 1:numel(fnames)
    DispatcherObj.Jobs(jobIdx).(fnames{i}) = JobUpdate.(fnames{i});
end

end
