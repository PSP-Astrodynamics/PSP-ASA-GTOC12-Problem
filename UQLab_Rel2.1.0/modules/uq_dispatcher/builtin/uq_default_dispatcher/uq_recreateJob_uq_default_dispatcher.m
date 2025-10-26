function uq_recreateJob_uq_default_dispatcher(DispatcherObj, jobIdx, varargin)

%% Parse and verify inputs
JobObj = DispatcherObj.Jobs(jobIdx);

% Name
JobDefDefault.Name = uq_createUniqueID;
[jobName,varargin] = uq_parseNameVal(varargin, 'Name', JobDefDefault.Name);
JobDef.Name = jobName;

% RemoteFolder
remoteLocation = DispatcherObj.RemoteLocation;
remoteSep = DispatcherObj.Internal.RemoteSep;
JobDefDefault.RemoteFolder = [remoteLocation remoteSep JobDef.Name];
[remoteFolder,varargin] = uq_parseNameVal(...
    varargin, 'RemoteFolder', JobDefDefault.RemoteFolder);
JobDef.RemoteFolder = remoteFolder;

% ExecMode
JobDefDefault.ExecMode = JobObj.ExecMode;
[execMode,varargin] = uq_parseNameVal(...
    varargin, 'ExecMode', JobDefDefault.ExecMode);
try
    % Check if 'ExecMode' is a valid char
    uq_Dispatcher_util_isAsync(execMode);
catch e
    rethrow(e)
end
JobDef.ExecMode = execMode;

% AttachedFiles
JobDefDefault.AttachedFiles = JobObj.AttachedFiles;
[attachedFiles,varargin] = uq_parseNameVal(...
    varargin, 'AttachedFiles', JobDefDefault.AttachedFiles);
JobDef.AttachedFiles = attachedFiles;
% Make sure attached files are still available otherwise throw an error
for i = 1:numel(JobDef.AttachedFiles)
    if ~exist(JobDef.AttachedFiles{i})
        error('One or more AttachedFiles no longer available: %s',...
            JobDef.AttachedFiles{i})
    end
end

% AddToPath
JobDefDefault.AddToPath = JobObj.AddToPath;
[addToPath,varargin] = uq_parseNameVal(...
    varargin, 'AddToPath', JobDefDefault.AddToPath);
JobDef.AddToPath = addToPath;

% AddTreeToPath
JobDefDefault.AddTreeToPath = JobObj.AddTreeToPath;
[addTreeToPath,varargin] = uq_parseNameVal(...
    varargin, 'AddTreeToPath', JobDefDefault.AddTreeToPath);
JobDef.AddTreeToPath = addTreeToPath;

% Tag
JobDefDefault.Tag = [...
    JobObj.Tag ' ' sprintf('recreated on <%s>',JobDef.Name)];
[tag,varargin] = uq_parseNameVal(varargin, 'Tag', JobDefDefault.Tag);
JobDef.Tag = tag;

% Fetch
JobDefDefault.Fetch = JobObj.Fetch;
[fetch,varargin] = uq_parseNameVal(varargin, 'Fetch', JobDefDefault.Fetch);
JobDef.Fetch = fetch;

% Merge
JobDefDefault.Merge = JobObj.Merge;
[merge,varargin] = uq_parseNameVal(varargin, 'Merge', JobDefDefault.Merge);
JobDef.Merge = merge;

% Parse
JobDefDefault.Parse = JobObj.Parse;
[parse,varargin] = uq_parseNameVal(varargin, 'Parse', JobDefDefault.Parse);
JobDef.Parse = parse;

% Data
JobDefDefault.Data = JobObj.Data;
[data,varargin] = uq_parseNameVal(varargin, 'Data', JobDefDefault.Data);
JobDef.Data = data;

% Task
JobDefDefault.Task = JobObj.Task;
[task,varargin] = uq_parseNameVal(varargin, 'Task', JobDefDefault.Task);
JobDef.Task = task;

% WallTime
JobDefDefault.WallTime = JobObj.WallTime;
[wallTime,varargin] = uq_parseNameVal(...
    varargin, 'WallTime', JobDefDefault.WallTime);
JobDef.WallTime = wallTime;

% FetchStreams
JobDefDefault.FetchStreams = JobObj.FetchStreams;
[fetchStreams,varargin] = uq_parseNameVal(...
    varargin, 'FetchStreams', JobDefDefault.FetchStreams);
JobDef.FetchStreams = fetchStreams;

% Throw warning if varargin is not exhausted
if ~isempty(varargin)
    warning('There is %s Name/Value argument pairs.',num2str(numel(varargin)))
end

%% Create the Job
uq_createJob(JobDef,DispatcherObj);

end

