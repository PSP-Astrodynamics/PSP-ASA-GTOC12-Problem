function uq_submitJob_uq_default_dispatcher(DispatcherObj,jobIdx)
%
%
%   See also UQ_SUBMITJOB.

%% Parse and verify inputs
displayOpt = DispatcherObj.Internal.Display;

%%
currentJob = DispatcherObj.Jobs(jobIdx);

uq_updateStatus(DispatcherObj,jobIdx)
% Only 'pending' Job (Status == 1) can be submitted
if DispatcherObj.Jobs(jobIdx).Status ~= 1
    warning('Can''t submit; Job is *%s* not pending!',...
        uq_getStatus(DispatcherObj,jobIdx))
    return
end

%%
remoteFolder = currentJob.RemoteFolder;
remoteSep = DispatcherObj.Internal.RemoteSep;
jobScript = DispatcherObj.Internal.RemoteFiles.JobScript;

%% Create a command for SSH connection
sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);

% Maximum number of trials for attempting an SSH connection
maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;

%% Get the remote environment setup commands
RemoteConfig = DispatcherObj.Internal.RemoteConfig; 
envSetup = RemoteConfig.EnvSetup;

%% Get the scheduler-specific variables
SchedulerVars = RemoteConfig.SchedulerVars;
submitCommand = SchedulerVars.SubmitCommand;
if isempty(submitCommand)
    % If no scheduler, explicitly send to the background
    jobScript = sprintf('./%s 1> %s 2> %s',...
        jobScript, [currentJob.Name '.stdout'], [currentJob.Name '.stderr']);
else
    jobScript = ['<' jobScript];
end

%% Copy everything before cleaning

jobScriptStdOut = DispatcherObj.Internal.RemoteFiles.JobScriptStdOut;
logSubmit = DispatcherObj.Internal.RemoteFiles.LogSubmit;

%% Submit the Job and create a log file (job submitted) in the remote
try
    % NOTE: creating the log file is done in a single SSH dispatch to avoid
    % awkward situation in which the filestamp of job-started log file is
    % older than the filestamp of job-submitted log file.
    if all(cellfun(@isempty,envSetup))
        cmdName = {'cd', submitCommand, 'touch'};
        cmdArgs = {...
            % Safe guard against possible whitespaces in 'remoteFolder'
            {uq_Dispatcher_util_writePath(remoteFolder,'linux')},...
            {jobScript, ['>',jobScriptStdOut]},...
            {logSubmit}};
    else
        cmdName = {envSetup{:}, 'cd', submitCommand, 'touch'};
        % Safe guard against possible whitespaces in 'remoteFolder'
        cmdArgs = {...
            repmat({''},1,numel(envSetup)),...
            {uq_Dispatcher_util_writePath(remoteFolder,'linux')},...
            {jobScript, ['>',jobScriptStdOut]},...
            {logSubmit}};
    end

    % Display some information
    if displayOpt > 1
        msg = '[DISPATCHER] Submit the Job to the remote machine';
        fprintf(uq_Dispatcher_util_dispMsg(msg))
    end

    uq_Dispatcher_util_runCLICommand(...
        cmdName, cmdArgs, sshConnect, 'MaxNumTrials', maxNumTrials);

    % Display some information
    if displayOpt > 1
        fprintf('(OK)\n')
    end

    %% Get the timestamp of the logfile
    jobSubmitLogfilename = DispatcherObj.Internal.RemoteFiles.LogSubmit;
    jobSubmitLogfile = sprintf('%s%s%s',...
        remoteFolder, remoteSep, jobSubmitLogfilename);
    submitDateTime = uq_Dispatcher_util_getFileDateTime(...
                jobSubmitLogfile, sshConnect, maxNumTrials);

catch ME
    rethrow(ME)
end

%% Get the Job ID
try
    % NOTE: We cannot be sure that the JobID stored in standard output file
    % will be readily available, so we need to try to get the JobID
    % multiple times, using time out as well, if it is still empty then
    % throw an error.
    jobID = '';
    startTime = clock;
    timeOut = 300;  % 5 minutes
    while isempty(jobID) && etime(clock,startTime) < timeOut
        % Display some information
        if displayOpt > 1
            msg = '[DISPATCHER] Get the remote Job ID';
            fprintf(uq_Dispatcher_util_dispMsg(msg))
        end
        jobID = uq_getJobID(DispatcherObj,jobIdx);
    end
    
    if isempty(jobID)
        error('Failed to get the Job ID of a submitted Job.')
    end

    % Display some information
    if displayOpt > 1
        fprintf('(OK)\n')
    end

    %% Update JobObj (status == 2) and DispatcherObj
    % NOTE: Change to DispatcherObj state
    DispatcherObj.Jobs(jobIdx).Status = 2;
    DispatcherObj.Jobs(jobIdx).JobID = jobID;
    DispatcherObj.Jobs(jobIdx).SubmitDateTime = submitDateTime;
    DispatcherObj.Jobs(jobIdx).LastUpdateDateTime = ...
        uq_Dispatcher_util_getNowDateTime(sshConnect,maxNumTrials);

catch ME
    % Something is wrong, roll back all changes
    
    % Roll back side-effect: delete jobSubmitLogfile in the remote machine
    cmdName = 'rm';
    cmdArgs = {'-f',jobSubmitLogfile};
    uq_Dispatcher_util_runCLICommand(...
        cmdName, cmdArgs, sshConnect, 'MaxNumTrials', maxNumTrials);
    
    % Roll back changes in the Job object state
    DispatcherObj.Jobs(jobIdx) = currentJob;
    
    % Rethrow error
    rethrow(ME)
end

end
