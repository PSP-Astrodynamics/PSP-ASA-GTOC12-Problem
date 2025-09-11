function JobUpdates = uq_Dispatcher_status_getErrorProcess(DispatcherObj,jobIdx)
%UQ_DISPATCHER_STATUS_GETPROCESSERROR gets the status update for a Job with 
%   a process-based error in the remote machine.

%% Get local variables
remoteSep = DispatcherObj.Internal.RemoteSep;

currentJob = DispatcherObj.Jobs(jobIdx);
remoteFolder = currentJob.RemoteFolder;

sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);

% Maximum number of trials for attempting an SSH connection
maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;

%% Check if process-based error log file(s) is available

logErrorFilename = DispatcherObj.Internal.RemoteFiles.LogError;
logErrorFile = sprintf('%s%s%s',...
    remoteFolder, remoteSep, logErrorFilename);

% Get the number of remote processes
numProcs = currentJob.Task.NumProcs;

% Check if process-based error log files exist
logProcErrorFilesExist = false(numProcs,1);
for i = 1:numProcs
    procID = sprintf('%04d',i);
    logProcErrorFile = sprintf(logErrorFile,procID);
    logProcErrorFilesExist(i) = uq_Dispatcher_util_checkFile(...
        logProcErrorFile, sshConnect, maxNumTrials);
end

%% Check if the scheduler file standard output is available
% This file indicates that the Job has indeed been finished.
if ~strcmpi(DispatcherObj.Internal.RemoteConfig.Scheduler,'none')
    % If no scheduler is used, then JobStdOutFile is irrelevant.
    jobStdOutFilename = [currentJob.Name '.stdout'];
    jobStdOutFile = sprintf('%s%s%s',...
        remoteFolder, remoteSep, jobStdOutFilename);

    jobStdOutFileExist = uq_Dispatcher_util_checkFile(...
        jobStdOutFile, sshConnect, maxNumTrials);
end

%% Is Job finished?
if ~strcmpi(DispatcherObj.Internal.RemoteConfig.Scheduler,'none')
    isJobFinished = any(logProcErrorFilesExist) && jobStdOutFileExist;
else
    isJobFinished = any(logProcErrorFilesExist);
end

%% Create Job updates
startDateTime = currentJob.StartDateTime;
if isJobFinished    
    % Get time stats
    if ~strcmpi(DispatcherObj.Internal.RemoteConfig.Scheduler,'none')
        % With a scheduler
        % FinishDateTime is the timestamp of jobStdOutFile
        finishDateTime = uq_Dispatcher_util_getFileDateTime(...
            jobStdOutFile, sshConnect, maxNumTrials);
    else
        % No scheduler
        % FinishDateTime is the most recent process-based error log file
        logProcErrorFileDateTime = cell(numProcs,1);
        for i = 1:numProcs
            procID = sprintf('%04d',i);
            logProcErrorFile = sprintf(logErrorFile,procID);
            logProcErrorFileDateTime{i} = uq_Dispatcher_util_getFileDateTime(...
                logProcErrorFile, sshConnect, maxNumTrials);
        end
        finishDateTime = uq_Dispatcher_util_getMostRecentDateTime(...
            logProcErrorFileDateTime);
    end
    runningDuration = uq_Dispatcher_util_computeDuration(...
        startDateTime,finishDateTime);
    nowDateTime = uq_Dispatcher_util_getNowDateTime(sshConnect,maxNumTrials);
    
    % Capture the stderr/stdout stream in case of error
    if currentJob.FetchStreams
        OutputStreams = uq_fetchOutputStreams(DispatcherObj,jobIdx);
    else
        OutputStreams = [];
    end
    
    % Create a Job updates packages
    JobUpdates.Status = -1;
    JobUpdates.FinishDateTime = finishDateTime;
    JobUpdates.LastUpdateDateTime = nowDateTime;
    JobUpdates.RunningDuration = runningDuration;
    JobUpdates.OutputStreams = OutputStreams;

else
    % A process-based error logfile is not found
    JobUpdates = [];
end

end
