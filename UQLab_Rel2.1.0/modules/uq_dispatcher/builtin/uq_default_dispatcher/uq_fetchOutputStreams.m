function OutputStreams = uq_fetchOutputStreams(DispatcherObj,jobIdx,varargin)
%UQ_FETCHOUTPUTSTREAMS fetches the stream from remote execution.

if nargin == 1
    jobIdx = numel(DispatcherObj.Jobs);
end

%% Update Dispatcher
[updateDispatcher,varargin] = uq_parseNameVal(...
    varargin, 'UpdateDispatcher', false);

% Throw warning if args is not exhausted
if ~isempty(varargin)
    warning('Unparsed NAME/VALUE argument pairs remain.')
end

%% Check if the Job is not finished
% finishedIDs = [1 2 3];
% if any(DispatcherObj.Jobs(jobIdx).Status == finishedIDs)
%     % TODO: show only warning at the top verbosity level
%     warning('Attempt to capture the stream: Job is not yet finished.')
%     CapturedStream = '';
% end

%% 
remoteFiles = DispatcherObj.Internal.RemoteFiles;
currentJob = DispatcherObj.Jobs(jobIdx);
remoteSep = DispatcherObj.Internal.RemoteSep;

sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);
% Maximum number of trials for attempting an SSH connection
maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;

%% Submission standard output
% Only read submission stdout if a job scheduler is used.
if ~strcmpi(DispatcherObj.Internal.RemoteConfig.Scheduler,'none')

    submitStdOutFilename = remoteFiles.JobScriptStdOut;
    submissionStdOutFile = sprintf('%s%s%s', ...
        currentJob.RemoteFolder, remoteSep, submitStdOutFilename);

    % Read the file
    [~,results] = uq_Dispatcher_util_cat(submissionStdOutFile,sshConnect,maxNumTrials);

    OutputStreams.SubmitStdOut = strsplit(uq_strip(results),'\n');
else
    OutputStreams.SubmitStdOut = {''};
end

%% Job standard output
% Get filename
jobStdOutFilename = [currentJob.Name '.stdout'];
jobStdOutFile = sprintf('%s%s%s',...
    currentJob.RemoteFolder, remoteSep, jobStdOutFilename);

% Read the file
[~,results] = uq_Dispatcher_util_cat(...
    jobStdOutFile, sshConnect, maxNumTrials);

OutputStreams.JobStdOut = strsplit(uq_strip(results),'\n');

%% Job standard error
% Get filename
jobStdErrFilename = [currentJob.Name '.stderr'];
jobStdErrFile = sprintf('%s%s%s',...
    currentJob.RemoteFolder, remoteSep, jobStdErrFilename);

% Read the file
[~,results] = uq_Dispatcher_util_cat(...
    jobStdErrFile, sshConnect, maxNumTrials);

OutputStreams.JobStdErr = strsplit(uq_strip(results),'\n');

%% Process standard error (if any)

% Get the number of processes
numTasks = currentJob.Task.NumTasks;
numProcs = currentJob.Task.NumProcs;

processStdErr = cell(numProcs,1);

for i = 1:numProcs
    procID = sprintf('%04d',i);
    procStdErrFilename = sprintf(remoteFiles.LogError,procID);
    procStdErrFile = sprintf('%s%s%s',...
        currentJob.RemoteFolder, remoteSep, procStdErrFilename);
    isFileExist = uq_Dispatcher_util_checkFile(procStdErrFile,sshConnect,maxNumTrials);
    if isFileExist
        [~,results] = uq_Dispatcher_util_cat(procStdErrFile,sshConnect,maxNumTrials);
        processStdErr{i} = strsplit(uq_strip(results),'\n');
    else
        processStdErr{i} = '';
    end
end

OutputStreams.ProcessStdErr = processStdErr;

%% Task standard output (if any)

OutputStreams.TaskStdOut = {};
if ~currentJob.Task.MATLAB
    taskStdOut = cell(numTasks,1);
    for i = 1:numTasks
        taskStdOutFilename = sprintf('wrappedCommand_%d.stdout',i);  % TODO: rename wrappedCommand
        taskStdOutFile = sprintf('%s%s%s%s',...
            currentJob.RemoteFolder, remoteSep, 'logs', remoteSep,...  % is logs always there
            taskStdOutFilename);
        [~,results] = uq_Dispatcher_util_cat(taskStdOutFile,sshConnect,maxNumTrials);
        taskStdOut{i} = strsplit(uq_strip(results),'\n');
    end
    OutputStreams.TaskStdOut = taskStdOut;
end

%% Task standard error (if any)
OutputStreams.TaskStdErr = {};
if ~currentJob.Task.MATLAB
    taskStdErr = cell(numTasks,1);
    for i = 1:numTasks
        taskStdErrFilename = sprintf('wrappedCommand_%d.stderr',i);  % TODO: rename wrappedCommand
        taskStdErrFile = sprintf('%s%s%s%s',...
            currentJob.RemoteFolder, remoteSep, 'logs', remoteSep,...  % is logs always there
            taskStdErrFilename);
        [~,results] = uq_Dispatcher_util_cat(taskStdErrFile,sshConnect,maxNumTrials);
        taskStdErr{i} = strsplit(uq_strip(results),'\n');
    end
    OutputStreams.TaskStdErr = taskStdErr;
end

%% Task exit status (if any)
OutputStreams.TaskExitStatus = {};
if ~currentJob.Task.MATLAB
    taskStdErr = cell(numTasks,1);
    for i = 1:numTasks
        taskStdErrFilename = sprintf('wrappedCommand_%d.stat',i);  % TODO: rename wrappedCommand
        taskStdErrFile = sprintf('%s%s%s%s',...
            currentJob.RemoteFolder, remoteSep, 'logs', remoteSep,...  % is logs always there
            taskStdErrFilename);
        [~,results] = uq_Dispatcher_util_cat(taskStdErrFile,sshConnect,maxNumTrials);
        taskStdErr{i} = strsplit(uq_strip(results),'\n');
    end
    OutputStreams.TaskExitStatus = taskStdErr;
end

%% Update the DISPATCHER object if requested
if updateDispatcher
    DispatcherObj.Jobs(jobIdx).OutputStreams = OutputStreams;
end


end

