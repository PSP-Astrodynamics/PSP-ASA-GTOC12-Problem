function JobUpdates = uq_Dispatcher_status_getErrorJob(DispatcherObj,jobIdx)
%UQ_DISPATCHER_STATUS_GETJOBERROR gets the status update for a Job with a
%   job-wide error in the remote machine.

%% Create SSH connect command
sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);

% Maximum number of trials for attempting an SSH connection
maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;

%% Check if job-wide error file is not empty
currentJob = DispatcherObj.Jobs(jobIdx);
remoteFolder = currentJob.RemoteFolder;
jobStdErrFilename = [currentJob.Name '.stderr'];

remoteSep = DispatcherObj.Internal.RemoteSep;

jobStdErrFile = sprintf('%s%s%s',...
    remoteFolder, remoteSep, jobStdErrFilename);

isJobStdErrFileEmpty = uq_Dispatcher_util_isFileEmpty(...
    jobStdErrFile, sshConnect, maxNumTrials);

%% Create Job updates
if isJobStdErrFileEmpty
    % Error not found
    JobUpdates = [];
else
    % Error found after Job is submitted
    
    % Get time stats
    jobStdErrFileTimestamp = uq_Dispatcher_util_getFileDateTime(...
        jobStdErrFile, sshConnect, maxNumTrials);
    startDateTime = currentJob.StartDateTime;
    runningDuration = uq_Dispatcher_util_computeDuration(...
        startDateTime,jobStdErrFileTimestamp);
    nowDateTime = uq_Dispatcher_util_getNowDateTime(sshConnect,maxNumTrials);
    
    % Fetch the output streams (stderr and stdout) in case of error
    OutputStreams = uq_fetchOutputStreams(DispatcherObj,jobIdx);
    
    % Create Job updates package
    JobUpdates.Status = -1;
    JobUpdates.FinishDateTime = jobStdErrFileTimestamp;
    JobUpdates.LastUpdateDateTime = nowDateTime;
    JobUpdates.RunningDuration = runningDuration;
    JobUpdates.OutputStreams = OutputStreams;

end

end
