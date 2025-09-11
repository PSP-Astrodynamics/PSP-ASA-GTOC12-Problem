function varargout = uq_ssh_dispatcher(DispatcherObj)
%UQ_SSH_DISPATCHER dispatches a uq_evalModel call to a remote machine.

%% Execution mode is inherited from the Dispatcher object property
try
    uq_Dispatcher_util_isAsync(DispatcherObj.ExecMode);
    JobDef.ExecMode = DispatcherObj.ExecMode;
catch e
    rethrow(e)
end

%% If Model is 'uq_link' and MATLAB/UQLab is not required in the remote
ModelObj = DispatcherObj.Internal.Data.current_model;
if strcmp(ModelObj.Type,'uq_uqlink')
    if ~ModelObj.Internal.RemoteMATLAB
        currentThreadSafe = ModelObj.Internal.ThreadSafe;
        ModelObj.Internal.ThreadSafe =  true;
        X = DispatcherObj.Internal.Data.X;
        % Get the number of output arguments from the call to 'uq_evalModel'
        numOfOutArgs = DispatcherObj.Internal.Data.Nargout;
        % At least one output argument is requested
        numOfOutArgs = max(numOfOutArgs,1);
        [varargout{1:numOfOutArgs}] = ...
            uq_UQLink_dispatchWithoutMATLAB(X,ModelObj.Internal,DispatcherObj);
        ModelObj.Internal.ThreadSafe = currentThreadSafe;
        return
    end
end

%% Check if MATLAB is specified in the Profile
if isempty(DispatcherObj.Internal.RemoteConfig.MATLABCommand)
    error('MATLAB command in full path not defined in %s',...
        DispatcherObj.Profile)
end

%% Check if UQLab is specified in the Profile
if isempty(DispatcherObj.Internal.RemoteConfig.RemoteUQLabPath)
    error('Remote UQLab path is not defined in %s',...
        DispatcherObj.Profile)
end

%% Specify a Job - Create a unique name
% Create a unique name based on time/date for multi-process-safe operation
% (avoid issue with overwriting, etc.)
jobName = uq_createUniqueID;
JobDef.Name = jobName;

% Create a name of the remote folder based on the Job name
RemoteConfig = DispatcherObj.Internal.RemoteConfig;
remoteSep = DispatcherObj.Internal.RemoteSep;
JobDef.RemoteFolder = [RemoteConfig.RemoteFolder remoteSep jobName];

%% Specify the Tag in a Job
% Serve as a label to a Job
JobDef.Tag = sprintf('uq_evalModel of <%s> on <%s>',...
    DispatcherObj.Internal.current_model.Name, datestr(now));

%% Specify the Data in a Job
JobDef.Data.Inputs = DispatcherObj.Internal.Data.X;
JobDef.Data.Model = DispatcherObj.Internal.Data.current_model;

%% Specify the Task in a Job - Task type
JobDef.Task.Type = 'uq_evalModel';

%% Specify the Task in a Job - Use MATLAB
JobDef.Task.MATLAB = true;

%% Specify the Task in a Job - Use UQLab
JobDef.Task.UQLab = true;
JobDef.Task.SaveUQLabSession = true;

%% Specify the Task in a Job - Command
JobDef.Task.Command = @uq_evalModel;

%% Specify the Task in a Job - Number of tasks in a Job
numTasks = size(DispatcherObj.Internal.Data.X,1);
JobDef.Task.NumTasks = numTasks;

%% Specify the Task in a Job - Number of processes in a Job
% The number of requested processes
numProcsReq = DispatcherObj.NumProcs;
% The number of actual processes
numProcsAct = uq_Dispatcher_util_getNumProcs(numTasks,numProcsReq);
JobDef.Task.NumProcs = numProcsAct;

%% Specify the Task in a Job - Number of output arguments
% Get the number of output arguments from the call to 'uq_evalModel'
numOfOutArgs = DispatcherObj.Internal.Data.Nargout;
% At least one output argument is requested
numOfOutArgs = max(numOfOutArgs,1);

% Kriging and PCK verification
% If an evaluation of a Kriging or a PCK metamodel is dispatched with a
% multiple (parallel) MATLAB processes, the covariance matrix of the
% prediction cannot be fetched and merged due to non-independent nature of
% the computation.
if isprop(JobDef.Data.Model,'MetaType')
    if any(strcmpi(JobDef.Data.Model.MetaType,{'kriging','pck'}))
        if JobDef.Task.NumProcs > 1 && numOfOutArgs == 3
            warning('Covariance matrix for Kriging or PCK metamodel\n%s',...
                'cannot be computed in a parallel dispatched evaluation.')
            varargout{3} = [];
            numOfOutArgs = 2;
        end
    end
end

JobDef.Task.NumOfOutArgs = numOfOutArgs;
JobDef.MergeParams.NumOfOutArgs = numOfOutArgs;

%% Specify the Read-and-merge function associated with the Job
JobDef.Fetch = uq_Dispatcher_map_fetch(DispatcherObj,numProcsAct);
JobDef.Parse = @uq_Dispatcher_map_parse;
JobDef.Merge = @uq_Dispatcher_evalModel_merge;

%% Specify the wall time for the Job
JobDef.WallTime = DispatcherObj.JobWallTime;

%% Specify whether to capture stream
JobDef.FetchStreams = DispatcherObj.Internal.FetchStreams;

%% Attach the function file if it's an m-file-based Default model
if strcmp(ModelObj.Type,'uq_default_model')
    if isprop(ModelObj,'mFile')
        JobDef.AttachedFiles = {which(ModelObj.mFile)};
    end
    
    if isprop(ModelObj,'mHandle')
        JobDef.AttachedFiles = {which(func2str(ModelObj.mHandle))};
    end
end

%% Attach the parser function if it's a UQLink model
if strcmp(ModelObj.Type,'uq_uqlink')
    JobDef.AttachedFiles = {which(func2str(ModelObj.Internal.Output.Parser))};
end

%% Attach the template files if it's a UQLink model
if strcmp(ModelObj.Type,'uq_uqlink')
    templateFiles = ModelObj.Internal.Template;
    templatePath = ModelObj.Internal.TemplatePath;
    templateFiles = fullfile(templatePath,templateFiles);
    [JobDef.AttachedFiles{end+1:end+numel(templateFiles)}] = templateFiles{:};
end

%% Create the Job
jobIdx = uq_createJob(JobDef,DispatcherObj);

%% Submit the parallel uq_evalModel
uq_submitJob(DispatcherObj,jobIdx)

%% Wait for the Job to finish (Optional)
isAsync = uq_Dispatcher_util_isAsync(DispatcherObj.Jobs(jobIdx).ExecMode);
if isAsync
    if nargout > 0
        [varargout{1:numOfOutArgs}] = deal([]);
    end
    return
end

% If wait, start polling and, when finish, fetch the results
syncTimeout = DispatcherObj.SyncTimeout;
try
    uq_waitForJob(DispatcherObj, jobIdx, 'WaitTimeout', syncTimeout)
    [varargout{1:numOfOutArgs}] = uq_fetchResults(DispatcherObj,jobIdx);
catch e
    rethrow(e)
end

end