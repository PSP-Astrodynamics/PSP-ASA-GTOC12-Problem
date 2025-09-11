function uq_initialize_uq_default_dispatcher(current_dispatcher)
%UQ_INITIALIZE_UQ_DEFAULT_DISPATCHER initializes a default Dispatcher
%   object with user-specified options.
%
%   UQ_INITIALIZE_UQ_DEFAULT_DISPATCHER(CURRENT_DISPATCHER) initializes
%   the CURRENT_DISPATCHER with the user-specified options.
%
%   NOTE:
%   The CURRENT_DISPATCHER passed to the function will be updated in-place.

%% Input Verifications
if exist('current_dispatcher','var')
    if ischar(current_dispatcher)
        current_dispatcher = uq_getDispatcher(current_dispatcher);
    end
else
    current_dispatcher = uq_getDispatcher;
end

%% Set Local Variables

% Skipped fields are unprocessed fields, dealt with somewhere else
skipFields = {'Type','Name'};

Options = current_dispatcher.Options;
Internal = current_dispatcher.Internal;

%% Parse *Display* Option
[Options,Internal] = uq_initialize_display(Options,Internal);

%% Get the content of the *Profile* File
% Specify the name of the cluster profile file (excl. the extension).
% *Profile* is mandatory.

% Parse the *Profile* field
[ProfileOpt,Options] = uq_process_option(Options, 'Profile', [], 'char');

if ProfileOpt.Invalid
    error('Invalid value for the remote machine Profile filename.')
end

if ProfileOpt.Missing || isempty(ProfileOpt.Value)
    error('Missing specification for the remote machine Profile filename.')
end

% Get the fileparts of the profile file
rootDir = uq_rootPath;
defaultProfileDir = 'Profiles/HPC';
profileFile = which(ProfileOpt.Value);
if isempty(profileFile)
    % 'profileFile' is empty when the file is not in the PATH
    % The it is assumed that the users give the path to the file
    [profileFullPath{1:3}] = fileparts(ProfileOpt.Value);
else
    [profileFullPath{1:3}] = fileparts(profileFile);
end
if exist(ProfileOpt.Value,'file') == 2
    % Explicitly checking the existence of a *file*
    % Assume the file is in the PATH
    profileFullname = ProfileOpt.Value;
    currentDir = pwd;
    cd(profileFullPath{1})
    profileFullPath{1} = pwd;
    cd(currentDir)
else
    % Assume the file is in the default folder
    profileFullPath{1} = fullfile(rootDir,defaultProfileDir);
    [~,profileFileName,profileFileExt] = fileparts(ProfileOpt.Value);
    profileFullPath{2} = profileFileName;
    if isempty(profileFileExt)
        profileFullPath{3} = '.m';
    end
    profileFullname = fullfile(profileFullPath{1},...
        strcat(profileFullPath{2:3}));
end
Internal.ProfileFullPath = transpose(profileFullPath);
% Read the remote machine Profile file
remoteConfig = uq_Dispatcher_readProfile(profileFullname);
Internal.RemoteConfig = remoteConfig;
% Add as a property of the Dispatcher Object
if ~isprop(current_dispatcher,'Profile')
    uq_addprop(current_dispatcher,'Profile');
    current_dispatcher.Profile = profileFullPath{2};
end

%% Create new *RemoteLocation* Property
% Use the value from RemoteConfig
if ~isprop(current_dispatcher,'RemoteLocation')
    uq_addprop(current_dispatcher,'RemoteLocation');
    current_dispatcher.RemoteLocation = Internal.RemoteConfig.RemoteFolder;
end

%% Parse SSHClient
if ~isempty(remoteConfig.SavedSession)
    clientName = 'putty';
else
    if ispc
        clientName = 'putty';
    else
        clientName = 'openssh';
    end
end
SSHClientDefault = uq_Dispatcher_params_getDefaultOpt(clientName);

% Allow users to override options
sshClient = SSHClientDefault;

isSSHDefined = isfield(Options,'SSHClient') && ~isempty(Options.SSHClient);

if isSSHDefined
    % Client name
    [SSHClientNameOpt,Options.SSHClient] = uq_process_option(...
        Options.SSHClient, 'Name', SSHClientDefault.Name, 'char');
    % Validate type and size
    validateattributes(SSHClientNameOpt.Value,...
            {'char'}, {'row'}, mfilename, '*SSH.Client*')
    sshClient.Name = SSHClientNameOpt.Value;
    % If SSHClient is specifically selected
    SSHClientDefault = uq_Dispatcher_params_getDefaultOpt(sshClient.Name);

    % Command for secure copy
    [SSHClientSecureCopyOpt,Options.SSHClient] = uq_process_option(...
            Options.SSHClient, 'SecureCopy',...
            SSHClientDefault.SecureCopy, 'char');
    % Validate type and size
    validateattributes(...
        SSHClientSecureCopyOpt.Value, {'char'}, {'row'},...
        mfilename, '*SSH.SecureCopy*')
    sshClient.SecureCopy = SSHClientSecureCopyOpt.Value;

    % Command for secure connection
    [SSHClientSecureConnectOpt,Options.SSHClient] = uq_process_option(...
            Options.SSHClient, 'SecureConnect',...
            SSHClientDefault.SecureConnect, 'char');
    % Validate type and size
    validateattributes(SSHClientSecureConnectOpt.Value,...
            {'char'}, {'row'}, mfilename, '*SSH.SecureConnect*')
    sshClient.SecureConnect = SSHClientSecureConnectOpt.Value;
    
    % Extra arguments for secure copy
    [SSHClientSecureCopyArgsOpt,Options.SSHClient] = uq_process_option(...
            Options.SSHClient, 'SecureCopyArgs',...
            SSHClientDefault.SecureCopyArgs, {'char','cell'});
    % Validate type and size
    if ~isempty(SSHClientSecureCopyArgsOpt.Value)
       validateattributes(SSHClientSecureCopyArgsOpt.Value,...
           {'char','cell'}, {'row'}, mfilename, '*SSH.SecureCopyArgs*')
    end
    sshClient.SecureCopyArgs = SSHClientSecureCopyArgsOpt.Value;
    
    % Extra arguments for secure connection
    [SSHClientSecureConnectArgsOpt,Options.SSHClient] = uq_process_option(...
            Options.SSHClient, 'SecureConnectArgs',...
            SSHClientDefault.SecureConnectArgs, {'char','cell'});
    % Validate type and size
    if ~isempty(SSHClientSecureConnectArgsOpt.Value)
        validateattributes(SSHClientSecureConnectArgsOpt.Value,...
                {'char','cell'}, {'row'},...
                mfilename, '*SSH.SecureConnectArgs*')
    end
    sshClient.SecureConnectArgs = SSHClientSecureConnectArgsOpt.Value;
    
    % Location of the Client
    % (optional, if the commands are not callable from path)
    [SSHClientLocationOpt,Options.SSHClient] = uq_process_option(...
            Options.SSHClient, 'Location',...
            SSHClientDefault.Location, 'char');
    % Validate type and size
    if ~isempty(SSHClientLocationOpt.Value)
        validateattributes(SSHClientLocationOpt.Value,...
                {'char'}, {'row'}, mfilename, '*SSH.Location*')
    end
    sshClient.Location = SSHClientLocationOpt.Value;
    
    % Maximum number of trials *MaxNumTrials*
    [SSHClientMaxNumTrialsOpt,Options.SSHClient] = uq_process_option(...
            Options.SSHClient, 'MaxNumTrials',...
            SSHClientDefault.MaxNumTrials, 'double');
    % Validate type and size
    if ~isempty(SSHClientMaxNumTrialsOpt.Value)
        validateattributes(SSHClientMaxNumTrialsOpt.Value,...
                {'double'}, {'scalar'}, mfilename, '*SSH.MaxNumTrials*')
    end
    sshClient.MaxNumTrials = SSHClientMaxNumTrialsOpt.Value;
    
    % Remove SSH field from Options
    Options = rmfield(Options,'SSHClient');
end

Internal.SSHClient = sshClient;

%% Parse *CheckRequirements* Option
checkReqDefault = uq_Dispatcher_params_getDefaultOpt('checkrequirements');

[CheckReqOpt,Options] = uq_process_option(...
    Options, 'CheckRequirements', checkReqDefault, 'logical');

if CheckReqOpt.Invalid
    checkRequirements = checkReqDefault;
elseif CheckReqOpt.Missing
    checkRequirements = checkReqDefault;
elseif isempty(CheckReqOpt.Value)
    checkRequirements = checkReqDefault;
else
    checkRequirements = CheckReqOpt.Value;
end

%% Parse **LocalStagingLocation** Option
% The directory with a write option
localStagingLocationDefault = uq_Dispatcher_params_getDefaultOpt(...
    'LocalStagingLocation');

% Parse *LocalStagingLocation* field
[LocalStagingLocationOpt,Options] = uq_process_option(...
    Options, 'LocalStagingLocation', localStagingLocationDefault, 'char');

% Validate type and size
if ~isempty(LocalStagingLocationOpt.Value)
    validateattributes(LocalStagingLocationOpt.Value,...
        {'char'}, {'row'}, mfilename, '*LocalStagingLocation*')
end

% Add 'LocalStagingLocation' as a property of the Dispatcher object
if ~isprop(current_dispatcher,'LocalStagingLocation')
    uq_addprop(current_dispatcher,'LocalStagingLocation');
    current_dispatcher.LocalStagingLocation = LocalStagingLocationOpt.Value;
end

%% Parse *NumProcs* Option
% The number of processes requested on the remote machine.
numProcsDefault = uq_Dispatcher_params_getDefaultOpt('NumProcs');

% Parse *NumProcs* field
[NumProcsOpt,Options] = uq_process_option(...
    Options, 'NumProcs', numProcsDefault, 'double');

% Validate its presence
if NumProcsOpt.Missing
    msg = sprintf('Number of Processes is set to (default): %d',...
        numProcsDefault);
    EVT.Type = 'D';
    EVT.Message = msg;
    EVT.eventID = ...
        'uqlab:dispatcher:default_dispatcher:init:numprocss:defaultsub';
    uq_logEvent(current_dispatcher,EVT);
end

% Validate type and size
validateattributes(NumProcsOpt.Value, {'numeric'}, {'scalar','integer'},...
    mfilename, '*NumProcs*')

if ~isprop(current_dispatcher,'NumProcs')
    uq_addprop(current_dispatcher,'NumProcs');
    current_dispatcher.NumProcs = NumProcsOpt.Value;
end

%% Parse *NumCPUs* Option
% The number of CPUs requested in the remote machine
% (incl. multiple nodes).
numCPUsDefault = uq_Dispatcher_params_getDefaultOpt('NumCPUs');

% Parse *NumCPUs* field
[NumCPUsOpt,Options] = uq_process_option(...
    Options, 'NumCPUs', numCPUsDefault, 'double');

% Validate its presence
if NumCPUsOpt.Missing
    msg = sprintf('Number of CPUs is set to (default): %d',numCPUsDefault);
    EVT.Type = 'D';
    EVT.Message = msg;
    EVT.eventID = ...
        'uqlab:dispatcher:default_dispatcher:init:numcpus:defaultsub';
    uq_logEvent(current_dispatcher,EVT);
end
    
% Validate type and size
validateattributes(NumCPUsOpt.Value, {'numeric'}, {'scalar','integer'},...
    mfilename, '*NumCPUs*')

Internal.NumCPUs = NumCPUsOpt.Value;

%if ~isprop(current_dispatcher,'NumCPUs')
%    uq_addprop(current_dispatcher,'NumCPUs');
%    current_dispatcher.NumCPUs = NumCPUsOpt.Value;
%end

%% Parse *CPUsPerNode* and *NumNodes* Options
% Either the number of processors per node (*CPUsPerNode*)
% or the number of nodes (*NumNodes*) are specified.
% Both options are not mandatory, but they need to be consistent.

% Parse *CPUsPerNode* field
[CPUsPerNodeOpt,Options] = uq_process_option(...
    Options, 'CPUsPerNode', [], 'double');

% If *CPUsPerNode* is specified, validate the attributes
if ~CPUsPerNodeOpt.Missing
    validateattributes(CPUsPerNodeOpt.Value, {'numeric'},...
        {'scalar','positive'}, mfilename, '*CPUsPerNode*')
end

% Parse *NumNodes* field
NumNodesDefault = 1;
[NumNodesOpt,Options] = uq_process_option(...
    Options, 'NumNodes', NumNodesDefault, 'double');

% If *NumNodes* is specified, validate the attributes
if ~NumNodesOpt.Missing
    validateattributes(NumNodesOpt.Value, {'numeric'},...
        {'scalar','positive'}, mfilename, '*NumNodes*')
end

if CPUsPerNodeOpt.Missing
    if NumNodesOpt.Missing
        % Both *CPUsPerNode* and *NumNodes* are not specified
        Internal.NumNodes = NumNodesOpt.Default;
        Internal.CPUsPerNode = Internal.NumCPUs;
    else
        % *NumNodes* is specified, check for consistency
        if mod(Internal.NumCPUs,NumNodesOpt.Value)
            error('The number of total CPUs must be a multiple of nodes!')
        end
        Internal.NumNodes = NumNodesOpt.Value;
        Internal.CPUsPerNode = Internal.NumCPUs;
    end
    
else
    if NumNodesOpt.Missing
        % *CPUsPerNode* is specified, check for consistency
        if mod(Internal.NumCPUs,CPUsPerNodeOpt.Value)
             error('The number of total CPUs must be a multiple of CPUsPerNode!')
        end
        Internal.NumNodes = NumNodesOpt.Default;
        Internal.CPUsPerNode = CPUsPerNodeOpt.Value;
    else
        % Both *CPUsPerNode* and *NumNodes* are specified
        if (NumNodesOpt.Value*CPUsPerNodeOpt.Value) ~= Internal.NumCPUs
            error(['Both the number of nodes in the cluster ',...
                'and the number of processors per node\n',...
                'have been specified, ',...
                'but they are not compatible ',...
                'with the total number of CPUs!'],'')
        end
        Internal.NumNodes = NumNodesOpt.Value;
        Internal.CPUsPerNode = CPUsPerNodeOpt.Value;
    end
end

%% Parse *AddToPath* Option
% Add specified folders WITHOUT the subfolders to the path of the remote
% execution. *AddToPath* is not mandatory with an empty default value:
%   - invalid specification, throws an error
%   - missing specification, assign default value
addToPathDefault = uq_Dispatcher_params_getDefaultOpt('AddToPath');

% Parse *AddToPath* field
[AddToPathOpt,Options] = uq_process_option(...
    Options, 'AddToPath', addToPathDefault, {'cell','char'});

if AddToPathOpt.Invalid
    error(['Invalid value for AddToPath option!\n',...
        'It must be either char or cell array.'])
end

if AddToPathOpt.Missing
    AddToPath = AddToPathOpt.Default;
else
    if ischar(AddToPathOpt.Value)
        % Make it a cell array
        AddToPath = {AddToPathOpt.Value};
    else
        AddToPath = AddToPathOpt.Value;
    end
end

if ~isprop(current_dispatcher,'AddToPath')
    uq_addprop(current_dispatcher,'AddToPath');
    current_dispatcher.AddToPath = AddToPath;
end

%% Parse *AddTreeToPath* Option
% Add folders WITH the subfolders to the path of the remote execution
% *AddTreeToPath* is not mandatory with an empty default value:
%   - invalid specification, throws an error
%   - missing specification, assign default value
addTreeToPathDefault = uq_Dispatcher_params_getDefaultOpt('AddTreeToPath');

% Parse the *AddTreeToPath* field
[AddTreeToPathOpt,Options] = uq_process_option(...
    Options, 'AddTreeToPath', addTreeToPathDefault, {'cell','char'});

if AddTreeToPathOpt.Invalid
    error(['Invalid value for AddTreeToPath option!\n',...
        'It must be either char or cell array.'])
end

if AddTreeToPathOpt.Missing
    AddTreeToPath = AddTreeToPathOpt.Default;
else
    if ischar(AddTreeToPathOpt.Value)
        % Make it a cell array
        AddTreeToPath = {AddTreeToPathOpt.Value};
    else
        AddTreeToPath = AddTreeToPathOpt.Value;
    end
end

if ~isprop(current_dispatcher,'AddTreeToPath')
    uq_addprop(current_dispatcher,'AddTreeToPath');
    current_dispatcher.AddTreeToPath = AddTreeToPath;
end

%% Parse *SyncTimeout* Option
% How long to wait for a Job in synchronous mode of execution.
syncTimeoutDefault = uq_Dispatcher_params_getDefaultOpt('SyncTimeout');

[SyncTimeoutOpt,Options] = uq_process_option(...
    Options, 'SyncTimeout', syncTimeoutDefault, 'double');
if SyncTimeoutOpt.Invalid
    warning('Invalid *SyncTimeout* specification. Revert to the default.')
end
if isempty(SyncTimeoutOpt.Value)
    syncTimeout = SyncTimeoutOpt.Default;
else
    syncTimeout = SyncTimeoutOpt.Value;
end
% Create new property to the DISPATCHER object
if ~isprop(current_dispatcher,'SyncTimeout')
    uq_addprop(current_dispatcher,'SyncTimeout');
end
current_dispatcher.SyncTimeout = syncTimeout;

%% Parse *CheckInterval* Option
% How long between checking the results in the remote machine (in seconds)
checkIntervalDefault = uq_Dispatcher_params_getDefaultOpt('checkinterval');

% Parse the *CheckInterval* field
[CheckIntervalOpt,Options] = uq_process_option(...
    Options, 'CheckInterval', checkIntervalDefault, 'double');

% *CheckInterval* is not mandatory;
% if not properly given, assign default value
if CheckIntervalOpt.Invalid || ...
        CheckIntervalOpt.Missing || ...
        isempty(CheckIntervalOpt.Value)
    Internal.CheckInterval = CheckIntervalOpt.Default;
else
    Internal.CheckInterval = CheckIntervalOpt.Value;
end

%% *JobWallTime*
% How long the job should be executed on the remote machine (in minutes)
wallTimeDefault = uq_Dispatcher_params_getDefaultOpt('JobWallTime');

[WallTimeOpt,Options] = uq_process_option(...
    Options, 'JobWallTime', wallTimeDefault, 'double');
if WallTimeOpt.Invalid
    warning('Invalid specification of *JobWallTime*. Revert to the default.')
    wallTime = WallTimeOpt.Default;
else
    wallTime = WallTimeOpt.Value;
end
try
    validateattributes(...
            WallTimeOpt.Value, {'double'}, {'scalar'},...
            mfilename, '*JobWallTime*')
catch
    warning('Invalid specification of *JobWallTime*. Revert to the default.')
    wallTime = WallTimeOpt.Default;
end
% Create new property to the DISPATCHER object
if ~isprop(current_dispatcher,'JobWallTime')
    uq_addprop(current_dispatcher,'JobWallTime');
end
current_dispatcher.JobWallTime = wallTime;

%% Parse *FetchStreams**
% A Flag to fetch the streams from remote execution and store it at the
% Job object.

% Get the default values for 'FetchStreams'
fetchStreamsDefault = uq_Dispatcher_params_getDefaultOpt('FetchStreams');

% Parse the *FetchStreams* field
[FetchStreamsOpt,Options] = uq_process_option(...
    Options, 'FetchStreams', fetchStreamsDefault, 'logical');

% *CaptureStream* is not mandatory;
% if not properly given, assign default value
if FetchStreamsOpt.Invalid || FetchStreamsOpt.Missing
    Internal.FetchStreams = FetchStreamsOpt.Default;
else
    Internal.FetchStreams = FetchStreamsOpt.Value;
end

%% Parse *ExecMode* Option
execModeDefault = uq_Dispatcher_params_getDefaultOpt('execmode');
[execModeOpt,Options] = uq_process_option(...
        Options, 'ExecMode', execModeDefault, 'char');
% Throw warning if the specified input is invalid
try
    % Only certain supported values are supported
    uq_Dispatcher_util_isAsync(execModeOpt.Value);
catch
    execModeOpt.Invalid = true;
end
if execModeOpt.Invalid
    warning('Invalid value for the *ExecMode* option. Revert to default.')
end
% Create new property to the DISPATCHER object
if ~isprop(current_dispatcher,'ExecMode')
    uq_addprop(current_dispatcher,'ExecMode');
end
current_dispatcher.ExecMode = execModeOpt.Value;

%% Parse *AutoSave**
autoSaveDefault = uq_Dispatcher_params_getDefaultOpt('autosave');
[autoSaveOpt,Options] = uq_process_option(...
    Options, 'AutoSave', autoSaveDefault, 'logical');
if autoSaveOpt.Invalid
    warning('Invalid value for the *AutoSave* option. Revert to default.')
end
Internal.AutoSave = autoSaveOpt.Value;

%% Parse *RemoteScripts* Option
% Create a struct containing the JobSettings default values:
RemoteFilesDefault.MATLAB = 'uq_remote_script.m';
RemoteFilesDefault.Bash = 'uq_remote_script.sh';
RemoteFilesDefault.RuntimeInfo = 'uq_tmp_runtime_info';
RemoteFilesDefault.UQLabSession = 'uq_tmp_session.mat';
RemoteFilesDefault.MPI = 'mpifile.sh';
RemoteFilesDefault.JobScript = 'qfile.sh';
RemoteFilesDefault.MPIRunPID = 'mpirun.pid';
RemoteFilesDefault.JobScriptStdOut = 'uq_runtime.out';  % TODO: rename this!
RemoteFilesDefault.SetPATH = 'uq_remote_setpath.sh';
RemoteFilesDefault.Data = 'uq_tmp_data';
RemoteFilesDefault.Output = 'uq_tmp_out';
RemoteFilesDefault.LogSubmit = '.uq_job_submitted';
RemoteFilesDefault.LogStart = '.uq_job_started';
RemoteFilesDefault.LogError = '.uqProc_%s_ExecErr';
RemoteFilesDefault.LogCompleted = '.uqProc_%s_ExecCpl';
RemoteFilesDefault.JobObject = 'JobObj.mat';
Internal.RemoteFiles = RemoteFilesDefault;

%% Add **.Internal.RemoteSep**
% Because the remote system is always assumed to be running a Linux OS,
% the directory separator is fixed.
Internal.RemoteSep = uq_Dispatcher_params_getDefaultOpt('RemoteSep');

%% Check for Unparsed Options
uq_options_remainder(...
    Options, current_dispatcher.Name, skipFields, current_dispatcher);

%% Assigned Parse Internal
% the current Dispatcher object already has 'Internal' property with
% 'Runtime' field in it.
fnames = fieldnames(Internal);
for i = 1:numel(fnames)
    current_dispatcher.Internal.(fnames{i}) = Internal.(fnames{i});
end

%% Add *Job* Property
if ~isprop(current_dispatcher,'Jobs')
    uq_addprop(current_dispatcher,'Jobs');
end

%% Check if a passwordless SSH connection can be made
if checkRequirements
    uq_Dispatcher_checkRequirements(current_dispatcher);
end

%% Save the newly created DISPATCHER object in a file
if current_dispatcher.Internal.AutoSave
    autoSaveFile = sprintf('uq_Dispatcher_%s_%s.mat',...
        strrep(current_dispatcher.Name,' ',''),...
        current_dispatcher.Profile);
    try
        uq_saveDispatcher(autoSaveFile,current_dispatcher);
        current_dispatcher.Internal.AutoSaveFile = autoSaveFile;
    catch ME
        warning(ME.message)
    end
end

end
