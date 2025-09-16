function varargout = uq_map_uq_default_dispatcher(fun, inputs, DispatcherObj, varargin)
%UQ_MAP_UQ_DEFAULT_DISPATCHER maps a sequence of inputs to another sequence
%   with a given function executed in a remote parallel environment using
%   the default DISPATCHER object.
%
%   See also UQ_MAP, UQ_MAP_UQ_EMPTY_DISPATCHER.

%% Parse and Verify Inputs

% Determine if the mapping is on MATLAB functions or Linux commands
if isa(fun,'char')
    isMATLABTask = false;
    funType = 'system';
else
    isMATLABTask = true;
    % Check if MATLAB is specified in the remote machine Profile
    if isempty(DispatcherObj.Internal.RemoteConfig.MATLABCommand)
        error('MATLAB command in full path not defined in %s',...
            DispatcherObj.Profile)
    end
    % Determine what's the function type
    funInfo = functions(fun);
    switch lower(funInfo.type)
        case 'simple'
            funType = 'simple';
        case 'matlab built-in function'
            funType = 'built-in';
        case 'anonymous'
            funType = 'anonymous';
    end
    % Further check if a simple function belongs to a MATLAB toolbox
    if strcmpi(funType,'simple')
        funFile = funInfo.file;
        % This is the regex rule that decides whether a function belongs
        % to a toolbox
        isAToolboxFun = regexpi(funFile,{'MATLAB','R\d+','toolbox'},'match');
        isAToolboxFun = all(cellfun(@(x) ~isempty(x),isAToolboxFun));
        if isAToolboxFun
            funType = 'built-in';
        end
        
        % Decide if a simple function belongs to UQLab
        isUQLabFun1 = regexpi(...
            funFile,...
            {regexprep(uq_rootPath,'\\','\\\\'),'modules','builtin'},...
            'match');
        isUQLabFun1 = all(cellfun(@(x) ~isempty(x), isUQLabFun1));
        isUQLabFun2 = regexpi(...
            funFile,...
            {regexprep(uq_rootPath,'\\','\\\\'),'core'},...
            'match');
        isUQLabFun2 = all(cellfun(@(x) ~isempty(x), isUQLabFun2));
        isUQLabFun = isUQLabFun1 | isUQLabFun2;
        if isUQLabFun
            funType = 'built-in';
        end
    end

end

% ExecMode
DefaultValue.ExecMode = DispatcherObj.ExecMode;
[execMode,varargin] = uq_parseNameVal(...
    varargin, 'ExecMode', DefaultValue.ExecMode);
JobDef.ExecMode = execMode;
% Convert the execution mode char to a flag (error if char is unsupported)
try
    isAsync = uq_Dispatcher_util_isAsync(execMode);
catch e
    rethrow(e)
end

% NumOfOutArgs (Number of output arguments)
DefaultValue.NumOfOutArgs = max(1,nargout);
[numOfOutArgs,varargin] = uq_parseNameVal(...
    varargin, 'NumOfOutArgs', DefaultValue.NumOfOutArgs);
% The left-hand-side must be smaller or equal the named argument
if nargout > numOfOutArgs
    error('The number of requested arguments mismatched.')
end
JobDef.Task.NumOfOutArgs = numOfOutArgs;

% SaveUQLabSession (default: false)
% Note: Only valid for MATLAB-based remote task
if isMATLABTask
    DefaultValue.SaveUQLabSession = false;
    [saveUQLabSession,varargin] = uq_parseNameVal(...
        varargin, 'SaveUQLabSession', DefaultValue.SaveUQLabSession);
end

% UQLab (default: false)
% Note: Only valid for MATLAB-based remote task
if isMATLABTask
    DefaultValue.UQLab = false;
    [useUQLab,varargin] = uq_parseNameVal(...
        varargin, 'UQLab', DefaultValue.UQLab);
    % If UQLab save session is requested, override use UQLab flag
    if saveUQLabSession
        useUQLab = true;
    end
    % Check if UQLab is specified in the Profile
    if isempty(DispatcherObj.Internal.RemoteConfig.RemoteUQLabPath)
        error('Remote UQLab path is not defined in %s',...
            DispatcherObj.Profile)
    end
end

% Determine if the sequence is a function handle
isSequenceAHandle = (numel(inputs) == 1) && isa(inputs,'function_handle');
if ~isMATLABTask && isSequenceAHandle
    error('Function handle to generate sequence is not valid for remote Linux commands.')
end

% Parameters
% Note: Only valid for MATLAB-based remote task
DefaultValue.Parameters = 'none';
if any(strcmpi('Parameters',varargin))
    [parameters,varargin] = uq_parseNameVal(...
        varargin, 'Parameters', DefaultValue.Parameters);
    if ischar(parameters) && ~strcmpi(parameters,'none') && ~isMATLABTask
        warning('Parameters for Linux command task are ignored.')
    end
else
    parameters = DefaultValue.Parameters;
end

% AttachedFiles (Attached files and folders)
DefaultValue.AttachedFiles = {};
[attachedFiles,varargin] = uq_parseNameVal(...
    varargin, 'AttachedFiles', DefaultValue.AttachedFiles);
if ~iscell(attachedFiles)
    attachedFiles = {attachedFiles};
end
JobDef.AttachedFiles = {};
[JobDef.AttachedFiles{end+1:end+numel(attachedFiles)}] = attachedFiles{:};
% Check if all the attached files exist
attachedFilesExist = cellfun(@(x) exist(x,'file'), attachedFiles) == 2;
attachedDirsExist = cellfun(@(x) exist(x,'dir'), attachedFiles) == 7;
if sum([attachedFilesExist attachedDirsExist]) ~= numel(attachedFiles)
    warning('One or more attached files and directories does not exist.')
end
% Check if any of the attached files are directories
attachedDirs = attachedFiles(cellfun(@isdir,attachedFiles));
if ispc
    fileSep = '\';
else
    fileSep = '/';
end
% Remove trailing separator
attachedDirNames = regexprep(attachedDirs, sprintf('%s$',fileSep), '');
% Get only the last part of the directory (if it's written in full path)
attachedDirNames = regexp(attachedDirNames, fileSep, 'split');
attachedDirNames = cellfun(@(x) x{end}, attachedDirNames,...
    'UniformOutput', false);

% AddToPath (default: empty or if attached files has folder)
DefaultValue.AddToPath = {};
[addToPath,varargin] = uq_parseNameVal(...
    varargin, 'AddToPath', DefaultValue.AddToPath);
JobDef.AddToPath = {};
[JobDef.AddToPath{end+1:end+numel(addToPath)}] = addToPath{:};

% AddTreeToPath (default: empty)
DefaultValue.AddTreeToPath = {};
[addTreeToPath,varargin] = uq_parseNameVal(...
    varargin, 'AddTreeToPath', DefaultValue.AddTreeToPath);
% Add the attached directories (incl. sub-directories) to the path
[addTreeToPath{end+1:end+numel(attachedDirNames)}] = attachedDirNames{:};
JobDef.AddTreeToPath = {};
[JobDef.AddTreeToPath{end+1:end+numel(addTreeToPath)}] = addTreeToPath{:};

% AddTreeToPath (default: empty)
DefaultValue.AutoAttachFiles = true;
[autoAttachFiles,varargin] = uq_parseNameVal(...
    varargin, 'AutoAttachFiles', DefaultValue.AutoAttachFiles);

% Tag (default: 'uq_map of <fun> at <date/time>')
if isa(fun,'char')
    funName = fun;
else
    funName = func2str(fun);
end
DefaultValue.Tag = sprintf('uq_map of <%s> on <%s>',...
    funName, datestr(now));
[tag,varargin] = uq_parseNameVal(...
    varargin, 'Tag', DefaultValue.Tag);
JobDef.Tag = tag;

% FetchStreams (default: follow DispatcherObj Options)
if isMATLABTask
    DefaultValue.FetchStreams = DispatcherObj.Internal.FetchStreams;
else
    DefaultValue.FetchStreams = true;
end
[fetchStreams,varargin] = uq_parseNameVal(...
    varargin, 'FetchStreams', DefaultValue.FetchStreams);
JobDef.FetchStreams = fetchStreams;

% AutoSubmit (default: true)
DefaultValue.AutoSubmit = true;
[isAutoSubmit,varargin] = uq_parseNameVal(...
    varargin, 'AutoSubmit', DefaultValue.AutoSubmit);

% Name (default: uq_createUniqueID)
DefaultValue.Name = uq_createUniqueID;
[jobName,varargin] = uq_parseNameVal(varargin, 'Name', DefaultValue.Name);

% MatrixMapping
% Note: Only valid for Matrix as Inputs
Default.MatrixMapping = 'ByElements';
[matrixMapping,varargin] = uq_parseNameVal(...
    varargin, 'MatrixMapping', Default.MatrixMapping);
if isempty(matrixMapping) || ...
        ~any(strcmpi(matrixMapping,{'byelements','bycolumns','byrows'}))
    warning('Not recognized option value for *MatrixMapping*.')
    matrixMapping = Default.MatrixMapping;
end
JobDef.Task.MatrixMapping = matrixMapping;

% ExpandCell (default: false)
Default.ExpandCell = false;
[expandCell,varargin] = uq_parseNameVal(...
    varargin, 'ExpandCell', Default.ExpandCell);
JobDef.Task.ExpandCell = expandCell;

% SeqGenParameters - Parameters for the sequence generator
% default: empty cell array
Default.SeqGenParameters = {};
[seqGenParameters,varargin] = uq_parseNameVal(...
    varargin, 'SeqGenParameters', Default.SeqGenParameters);
if ~iscell(seqGenParameters)
    error('Parameters for the sequence generator must be a cell array.')
end
JobDef.Data.SeqGenParameters = seqGenParameters;

% InputSize (Mandatory if a sequence generator is used)
Default.InputShape = [];
[inputSize,varargin] = uq_parseNameVal(varargin,...
    'InputSize', Default.InputShape);
if isSequenceAHandle
    if isempty(inputSize)
        error('Input size must be specified if a sequence generator is used.')
    end
end

% ErrorHandler - Function to handle error
Default.ErrorHandler = true;
[errorHandler,varargin] = uq_parseNameVal(...
    varargin, 'ErrorHandler', Default.ErrorHandler);
if ~islogical(errorHandler) && ~isa(errorHandler,'function_handle')
    error('*ErrorHandler* must either be a logical or a function handle.')
end
if islogical(errorHandler)
    if errorHandler
        JobDef.Task.ErrorHandler = 'true';
    else
        JobDef.Task.ErrorHandler = 'false';
    end
else
    JobDef.Task.ErrorHandler = sprintf('@%s',func2str(errorHandler));
end

%% WallTime
Default.WallTime = DispatcherObj.JobWallTime;
[wallTime,varargin] = uq_parseNameVal(...
    varargin, 'JobWallTime', Default.WallTime);
if ~isnumeric(wallTime) && ~isscalar(wallTime)
    warning('Invalid *JobWallTime* specification. Revert to the default.')
    wallTime = uq_Dispatcher_params_getDefaultOpt('JobWallTime');
end
JobDef.WallTime = wallTime;

%% Specify a Job - Create a unique folder name
% Create a unique name based on time/date for multi-process-safe operation
% (avoid issue with overwriting, etc.)
JobDef.Name = jobName;
remoteSep = DispatcherObj.Internal.RemoteSep;
remoteLocation = DispatcherObj.RemoteLocation; 
JobDef.RemoteFolder = [remoteLocation remoteSep jobName];

%% Specify the Task in a Job - Task type
JobDef.Task.Type = 'uq_map';

%% Specify the Task in a Job - Use MATLAB
if isMATLABTask
    JobDef.Task.MATLAB = true;
else
    JobDef.Task.MATLAB = false;
end

%% Specify the Task in a Job - Use UQLab (Optional)
if isMATLABTask
    JobDef.Task.UQLab = useUQLab;
    JobDef.Task.SaveUQLabSession = saveUQLabSession;
else
    JobDef.Task.UQLab = false;
    JobDef.Task.SaveUQLabSession = false;
end

%% Specify the Task in a Job - Command
if strcmpi(funType,'anonymous')
    JobDef.Task.Command = 'model';
else
    JobDef.Task.Command = fun;
end

%% Auto attached files

% if no UQLab is used, some files from UQLab must be attached to run
% uq_map in the remote.
if isMATLABTask && ~useUQLab
    fileInfo{1} = functions(@uq_map);
    fileInfo{2} = functions(@uq_map_uq_empty_dispatcher);
    fileInfo{3} = functions(@uq_parseNameVal);
    JobDef.AttachedFiles(end+1:end+numel(fileInfo)) = arrayfun(...
        @(i) fileInfo{i}.file, 1:numel(fileInfo), 'UniformOutput', false);
end

% If function is simple, attach the function
if strcmpi(funType,'simple') && autoAttachFiles
    fileInfo = functions(fun);
    if ~isempty(fileInfo.file) && ...
            ~strcmpi(fileInfo.file,'MATLAB built-in function')
        JobDef.AttachedFiles{end+1} = fileInfo.file;
    end
end

% If inputs is function handle, attach the function
if isSequenceAHandle
    fileInfo = functions(inputs);
    JobDef.AttachedFiles{end+1} = fileInfo.file;
end

% A user-defined function handle is specified
if isa(errorHandler,'function_handle')
    fileInfo = functions(errorHandler);
    JobDef.AttachedFiles{end+1} = fileInfo.file;
end

%% Specify the Data in a Job
if isSequenceAHandle
    JobDef.Data.Inputs = inputs;
else
    % Reshape inputs if it is a matrix depending on how the mapping is
    % conducted
    if (isnumeric(inputs) || islogical(inputs)) && ismatrix(inputs)
        switch lower(matrixMapping)
            case 'byrows'
                inputs = arrayfun(@(i) {inputs(i,:)},...
                    transpose(1:size(inputs,1)), 'UniformOutput', false);
            case 'bycolumns'
                inputs = arrayfun(@(i) {inputs(:,i)}, 1:size(inputs,2),...
                    'UniformOutput', false);
        end
        JobDef.Task.ExpandCell = true;
    end
    
    % Flatten array to a column vector form because it is easier to split 
    % the task in different processes (during merging, original form
    % will be reconstructed)
    JobDef.Data.Inputs = inputs(:);
end
JobDef.Data.Parameters = parameters;

if strcmpi(funType,'anonymous')
    JobDef.Data.Model = func2str(fun);
else
    JobDef.Data.Model = '';
end

%% Specify the number of tasks in a Job
if isSequenceAHandle
    switch lower(matrixMapping)
        case 'byrows'
            numTasks = inputSize(1);
        case 'bycolumns'
            numTasks = inputSize(2);
        otherwise
            numTasks = prod(inputSize);
    end
else
    numTasks = numel(inputs);  % the number of elements
end
JobDef.Task.NumTasks = numTasks;

%% Specify the number of processes in a Job
% The number of requested processes
numProcsReq = DispatcherObj.NumProcs;
% The number of actual processes
numProcsAct = uq_Dispatcher_util_getNumProcs(numTasks,numProcsReq);

JobDef.Task.NumProcs = numProcsAct;

%% Fetch
if isMATLABTask
    DefaultValue.Fetch = uq_Dispatcher_map_fetch(DispatcherObj,numProcsAct);
else
    DefaultValue.Fetch = {};
end
[fetch,varargin] = uq_parseNameVal(...
    varargin, 'FilesToFetch', DefaultValue.Fetch);

%% Parse
% default: uq_Dispatcher_map_parse if MATLAB task, empty otherwise
if isMATLABTask
    DefaultValue.Parse = @uq_Dispatcher_map_parse;
else
    DefaultValue.Parse = {};
end
[parseFun,varargin] = uq_parseNameVal(...
    varargin, 'Parse', DefaultValue.Parse);

%% Merge
% default: uq_Dispatcher_map_merge if MATLAB task, empty otherwise
if isMATLABTask
    DefaultValue.Merge = @uq_Dispatcher_map_merge;
else
    DefaultValue.Merge = {};
end
[mergeFun,varargin] = uq_parseNameVal(...
    varargin, 'Merge', DefaultValue.Merge);

%% Check if there's a NAME/VALUE pair leftover
if ~isempty(varargin)
    warning('Unparsed NAME/VALUE argument pairs remain.')
end

%% Specify the task in a Job - FetchResults
JobDef.Fetch = fetch;
JobDef.Parse = parseFun;
JobDef.Merge = mergeFun;
% These parameters are used to reshape the outputs of remote parallel map.
if isSequenceAHandle
    switch lower(matrixMapping)
        case 'byrows'
            inputSize = [inputSize(1) 1];
        case 'bycolumns'
            inputSize = [1 inputSize(2)];
    end
    JobDef.MergeParams.InputSize = inputSize;
else
    JobDef.MergeParams.InputSize = size(inputs);
end
JobDef.MergeParams.NumOfOutArgs = numOfOutArgs;

%% Create Job
jobIdx = uq_createJob(JobDef,DispatcherObj);

%% Submit the Mapping Job
if ~isAutoSubmit
    if nargout
        [varargout{1:numOfOutArgs}] = deal([]);
    end
    return
end

uq_submitJob(DispatcherObj,jobIdx)

%% Wait for the mapping Job to finish (Optional)
if isAsync
    if nargout
        [varargout{1:numOfOutArgs}] = deal([]);
    end
    return
end

% Start polling and, when finish, fetch results
syncTimeout = DispatcherObj.SyncTimeout;
try
    uq_waitForJob(DispatcherObj, jobIdx, 'WaitTimeout', syncTimeout)
    [varargout{1:numOfOutArgs}] = uq_fetchResults(DispatcherObj,jobIdx);
catch e
    [varargout{1:numOfOutArgs}] = deal([]);
    error(e.message)
end

end
