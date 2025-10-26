function JobUpdates = uq_Dispatcher_status_getSubmitted(DispatcherObj,jobIdx)

%% Set local variables
remoteSep = DispatcherObj.Internal.RemoteSep;
currentJob = DispatcherObj.Jobs(jobIdx);
remoteFolder = currentJob.RemoteFolder;
maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;

sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);

%% Check if submitted log file is available
jobSubmitLogFilename = DispatcherObj.Internal.RemoteFiles.LogSubmit;
jobSubmitLogFile = sprintf('%s%s%s',...
    remoteFolder, remoteSep, jobSubmitLogFilename);

jobSubmitLogFileExists = uq_Dispatcher_util_checkFile(...
    jobSubmitLogFile, sshConnect, maxNumTrials);

if jobSubmitLogFileExists
    isJobSubmitted = true;
else
    isJobSubmitted = false;
end

%% Create Job updates
if isJobSubmitted
    
    submitDateTime = uq_Dispatcher_util_getFileDateTime(...
        jobSubmitLogFile, sshConnect, maxNumTrials);
   
    % Get the Job ID
    % NOTE: We cannot be sure that the JobID stored in standard output file
    % will be readily available, so we need to try to get the JobID
    % multiple times, using time out as well, if it is still empty then
    % throw an error.
    jobID = '';
    startTime = clock;
    timeOut = 300;  % 5 minutes
    while isempty(jobID) && etime(clock,startTime) < timeOut
        jobID = uq_getJobID(DispatcherObj,jobIdx);
    end
    
    % Create a Job updates package
    JobUpdates.Status = 2;
    JobUpdates.JobID = jobID;
    JobUpdates.SubmitDateTime = submitDateTime;
    JobUpdates.LastUpdateDateTime = ...
            uq_Dispatcher_util_getNowDateTime(sshConnect,maxNumTrials);

else
    % Job has not been submitted
    
    % Get time stats
    nowDateTime = uq_Dispatcher_util_getNowDateTime(sshConnect,maxNumTrials);

    % Create Job updates package
    JobUpdates.LastUpdateDateTime = nowDateTime;
end

end
