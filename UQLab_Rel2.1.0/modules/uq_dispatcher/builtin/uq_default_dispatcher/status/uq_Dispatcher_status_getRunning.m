function JobUpdates = uq_Dispatcher_status_getRunning(DispatcherObj,jobIdx)
%UQ_DISPATCHER_STATUS_GETRUNNING gets the status update for a running Job
%   in the remote machine.
 
%% Check if the job-started logfile has been produced
jobStartLogFilename = DispatcherObj.Internal.RemoteFiles.LogStart;
remoteSep = DispatcherObj.Internal.RemoteSep;
remoteFolder = DispatcherObj.Jobs(jobIdx).RemoteFolder;

jobStartLogFile = sprintf('%s%s%s',...
    remoteFolder, remoteSep, jobStartLogFilename);

sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);

% Maximum number of trials for attempting an SSH connection
maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;

jobStartLogFileExist = uq_Dispatcher_util_checkFile(...
    jobStartLogFile, sshConnect, maxNumTrials);

%% Create Job updates
submitDateTime = DispatcherObj.Jobs(jobIdx).SubmitDateTime;
if jobStartLogFileExist
    % Logfile exists, Job has been started
    
    % Get time stats
    jobStartLogFileDateTime = uq_Dispatcher_util_getFileDateTime(...
        jobStartLogFile, sshConnect, maxNumTrials);
    queueDuration = uq_Dispatcher_util_computeDuration(...
        submitDateTime,jobStartLogFileDateTime);
    nowDateTime = uq_Dispatcher_util_getNowDateTime(sshConnect,maxNumTrials);
    
    % Create Job updates package
    JobUpdates.Status = 3;
    JobUpdates.StartDateTime = jobStartLogFileDateTime;
    JobUpdates.LastUpdateDateTime = nowDateTime;
    JobUpdates.QueueDuration = queueDuration;
    
else
    % Job has not been started
    
    % Get time stats
    nowDateTime = uq_Dispatcher_util_getNowDateTime(sshConnect,maxNumTrials);
    queueDuration = uq_Dispatcher_util_computeDuration(...
        nowDateTime,submitDateTime);

    % Create Job updates package
    JobUpdates.LastUpdateDateTime = nowDateTime;
    JobUpdates.QueueDuration = queueDuration;

end

end
