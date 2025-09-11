function JobUpdates = uq_Dispatcher_status_getComplete(DispatcherObj,jobIdx)
%UQ_DISPATCHER_STATUS_GETCOMPLETED gets the status update for a complete 
%   Job in the remote machine.

%% Set local variables
remoteSep = DispatcherObj.Internal.RemoteSep;
currentJob = DispatcherObj.Jobs(jobIdx);
remoteFolder = currentJob.RemoteFolder;


%% Check if completed log files from each process are available

logCompletedFilename = DispatcherObj.Internal.RemoteFiles.LogCompleted;
logCompletedFile = sprintf('%s%s%s',...
    remoteFolder, remoteSep, logCompletedFilename);

% Get the number of remote processes
numProcs = currentJob.Task.NumProcs;

% Check if files exist
sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);

% Maximum number of trials for attempting an SSH connection
maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;

logProcCompletedFilesExist = false(numProcs,1);
for i = 1:numProcs
    procID = sprintf('%04d',i);
    logProcCompletedFile = sprintf(logCompletedFile,procID);
    logProcCompletedFilesExist(i) = uq_Dispatcher_util_checkFile(...
        logProcCompletedFile, sshConnect, maxNumTrials);
end

%% Check if the scheduler file standard output is available
% If no scheduler is used, then JobStdOutFile is irrelevant.
if ~strcmpi(DispatcherObj.Internal.RemoteConfig.Scheduler,'none')
    jobStdOutFilename = [currentJob.Name '.stdout'];
    jobStdOutFile = sprintf('%s%s%s',...
        remoteFolder, remoteSep, jobStdOutFilename);

    jobStdOutFileExist = uq_Dispatcher_util_checkFile(...
        jobStdOutFile, sshConnect, maxNumTrials);
end

%% Is Job complete?
if ~strcmpi(DispatcherObj.Internal.RemoteConfig.Scheduler,'none')
    isJobComplete = all(logProcCompletedFilesExist) && jobStdOutFileExist;
else
    isJobComplete = all(logProcCompletedFilesExist);
end

%% Create Job updates
startDateTime = currentJob.StartDateTime;
if isJobComplete    
    % Get time stats
    if ~strcmpi(DispatcherObj.Internal.RemoteConfig.Scheduler,'none')
        % With a scheduler
        % FinishDateTime is the timestamp of jobStdOutFile
        finishDateTime = uq_Dispatcher_util_getFileDateTime(...
            jobStdOutFile, sshConnect, maxNumTrials);
    else
        % No scheduler
        % FinishDateTime is the most recent process-based complete log file
        logProcCompletedFileDateTime = cell(numProcs,1);
        for i = 1:numProcs
            procID = sprintf('%04d',i);
            logProcCompletedFile = sprintf(logCompletedFile,procID);
            logProcCompletedFileDateTime{i} = uq_Dispatcher_util_getFileDateTime(...
                logProcCompletedFile, sshConnect, maxNumTrials);
        end
        finishDateTime = uq_Dispatcher_util_getMostRecentDateTime(...
            logProcCompletedFileDateTime);
    end
    runningDuration = uq_Dispatcher_util_computeDuration(...
            startDateTime,finishDateTime);
    nowDateTime = uq_Dispatcher_util_getNowDateTime(...
            sshConnect,maxNumTrials);
    
    % Capture Stream
    OutputStreams = [];
    if currentJob.FetchStreams
        OutputStreams = uq_fetchOutputStreams(DispatcherObj,jobIdx);
    end
    
    % Create a Job updates package
    JobUpdates.Status = 4;
    JobUpdates.FinishDateTime = finishDateTime;
    JobUpdates.LastUpdateDateTime = nowDateTime;
    JobUpdates.RunningDuration = runningDuration;
    JobUpdates.OutputStreams = OutputStreams;
    
else
    % Job is not complete
    JobUpdates = [];
end

end
