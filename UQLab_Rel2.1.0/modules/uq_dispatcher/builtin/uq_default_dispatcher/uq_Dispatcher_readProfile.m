function RemoteConfig = uq_Dispatcher_readProfile(remoteProfile)
%UQ_DISPATCHER_READPROFILE reads and parses the HPC profile file for the
%   remote machine configuration option. The remote machine configuration
%   is stored in a MATLAB script file.

%% Run the Profile File
run(remoteProfile)

%% Get and Check Authentication
% Three option groups are possible:
%   1. {Username,Hostname,PrivateKey}: used to make SSH connection with an
%      explicit private key (Default client: PuTTY (Windows), OpenSSH
%      (Linux)).
%      Note: PuTTY private key format differs from OpenSSH private key's.
%      Command:
%         - (OpenSSH) ssh -i <PrivateKey> <Username>@<Hostname>
%         - (PuTTY)   plink -ssh -i <PrivateKey> <Username>@<Hostname>  
%   2. {Username,Hostname}: used to make SSH connection assuming that a
%      passwordless SSH connection has been set up and the private key is
%      located in its default location (~/.ssh).
%      Command: ssh <Username>@<Hostname> ...
%   3. {SavedSession}: used to make SSH connection using PuTTY (plink)
%      assuming that a passwordless SSH connection has been set up as a
%      PuTTY session. The session is saved in its default location.
%      Command: plink <SavedSession> ...
%
% These option groups are mutually exclusive.
isUsernameDefined = exist('Username','var') && ~isempty(Username);
isHostnameDefined = exist('Hostname','var') && ~isempty(Hostname);
isPrivateKeyDefined = exist('PrivateKey','var') && ~isempty(PrivateKey);
isSavedSessionDefined = exist('SavedSession','var') && ~isempty(SavedSession);

if isUsernameDefined && isHostnameDefined
    if isSavedSessionDefined
        error(['Ambigous specification: specify only Username/Hostname',...
            ' or SavedSession, not both.'])
    end
    if isPrivateKeyDefined
        optionGroup = 1;
    else
        if ispc
            % with PuTTY in a Windows PC, private key or a saved session
            % must be used
            error(['With PuTTY (Windows PC), a private key or ',...
                'a saved session must be specified.'])
        end
        optionGroup = 2;
    end
elseif isSavedSessionDefined
    optionGroup = 3;
else
    error('Username/Hostname or SavedSession must be defined.')
end

switch optionGroup

    case 1
        validateattributes(Username,...
            {'char'}, {'row'}, mfilename, '*Username*')
        RemoteConfig.Username = Username;
        validateattributes(Hostname,...
            {'char'}, {'row'}, mfilename, '*Hostname*')
        RemoteConfig.Hostname = Hostname;
        validateattributes(PrivateKey,...
            {'char'}, {'row'}, mfilename, '*PrivateKey*')
        RemoteConfig.PrivateKey = PrivateKey;
        RemoteConfig.SavedSession = '';

    case 2
        validateattributes(Username,...
            {'char'}, {'row'}, mfilename, '*Username*')
        RemoteConfig.Username = Username;
        validateattributes(Hostname,...
            {'char'}, {'row'}, mfilename, '*Hostname*')
        RemoteConfig.Hostname = Hostname;
        RemoteConfig.PrivateKey = '';
        RemoteConfig.SavedSession = '';

    case 3
        RemoteConfig.Username = '';
        RemoteConfig.Hostname = '';
        RemoteConfig.PrivateKey = '';
        validateattributes(SavedSession,...
            {'char'}, {'row'}, mfilename, '*SavedSession*')
        RemoteConfig.SavedSession = SavedSession;

end

%% Job Scheduler

if exist('Scheduler','var')
    scheduler = lower(Scheduler);
else
    scheduler = 'none';
end

% Get the default values of Scheduler-specific variables
SchedulerDefault = uq_Dispatcher_params_getScheduler(scheduler);

% Users may override some specification
isCustomScheduler = strcmpi(scheduler,'custom');
isSchedulerVarsDefined = exist('SchedulerVars','var') &&...
    ~isempty(SchedulerVars);
if isCustomScheduler && ~isSchedulerVarsDefined
    error('Scheduler options for ''Custom'' scheduler must be specified.')
end

if isCustomScheduler || isSchedulerVarsDefined
    
    % *NodeNo* environment variable
    % Optional for custom scheduler
    NodeNoOpt = uq_process_option(...
        SchedulerVars, 'NodeNo', SchedulerDefault.NodeNo, 'char');
    validateattributes(NodeNoOpt.Value,...
        {'char'}, {'row'}, mfilename, '*SchedulerVars.NodeNo*')
    SchedulerVars.NodeNo = NodeNoOpt.Value;

    % *WorkingDirectory* environment variable
    % Mandatory for custom scheduler
    WorkingDirectoryOpt = uq_process_option(...
        SchedulerVars,...
        'WorkingDirectory',...
        SchedulerDefault.WorkingDirectory,...
        'char');
    validateattributes(WorkingDirectoryOpt.Value,...
        {'char'}, {}, mfilename, '*SchedulerVars.WorkingDirectory*')
    if strcmpi(scheduler,'custom') && WorkingDirectoryOpt.Missing
        error('Missing *.WorkingDirectory* for Custom scheduler.')
    end
    SchedulerVars.WorkingDirectory = WorkingDirectoryOpt.Value;
    
    % *HostFile* (command option to use a hostfile)
    % Optional for custom scheduler
    HostFileOpt = uq_process_option(...
        SchedulerVars, 'HostFile', SchedulerDefault.HostFile, 'char');
    validateattributes(HostFileOpt.Value,...
        {'char'}, {}, mfilename, '*SchedulerVars.HostFile*')
    SchedulerVars.HostFile = HostFileOpt.Value;

    % *Pragma* (prefix of a scheduler-specific directive)
    % Mandatory for custom scheduler
    PragmaOpt = uq_process_option(...
        SchedulerVars, 'Pragma', SchedulerDefault.Pragma, 'char');
    validateattributes(PragmaOpt.Value,...
        {'char'}, {}, mfilename, '*SchedulerVars.Pragma*')
    if strcmpi(scheduler,'custom') && PragmaOpt.Missing
        error('Missing *.Pragma* for Custom scheduler.')
    end
    SchedulerVars.Pragma = PragmaOpt.Value;
    
    % *JobNameOption* (option to specify the job name)
    % Mandatory for custom scheduler
    JobNameOptionOpt = uq_process_option(...
        SchedulerVars, 'JobNameOption', SchedulerDefault.JobNameOption, 'char');
    validateattributes(JobNameOptionOpt.Value,...
        {'char'}, {}, mfilename, '*SchedulerVars.JobNameOption*')
    if strcmpi(scheduler,'custom') && JobNameOptionOpt.Missing
        error('Missing *.JobNameOption* for Custom scheduler.')
    end
    SchedulerVars.JobNameOption = JobNameOptionOpt.Value;
    
    % *StdOutFileOption* (option to specify file to redirect std. output)
    % Mandatory for custom scheduler
    StdOutFileOptionOpt = uq_process_option(...
        SchedulerVars, 'StdOutFileOption', SchedulerDefault.StdOutFileOption, 'char');
    validateattributes(StdOutFileOptionOpt.Value,...
        {'char'}, {}, mfilename, '*SchedulerVars.StdOutFileOption*')
    if strcmpi(scheduler,'custom') && StdOutFileOptionOpt.Missing
        error('Missing *.StdOutFileOption* for Custom scheduler.')
    end
    SchedulerVars.StdOutFileOption = StdOutFileOptionOpt.Value;
    
    % *StdErrFileOption* (option to specify file to redirect std. error)
    % Mandatory for custom scheduler
    StdErrFileOptionOpt = uq_process_option(...
        SchedulerVars, 'StdErrFileOption', SchedulerDefault.StdErrFileOption, 'char');
    validateattributes(StdErrFileOptionOpt.Value,...
        {'char'}, {}, mfilename, '*SchedulerVars.StdErrFileOption*')
    if strcmpi(scheduler,'custom') && StdErrFileOptionOpt.Missing
        error('Missing *.StdErrFileOption* for Custom scheduler.')
    end
    SchedulerVars.StdErrFileOption = StdErrFileOptionOpt.Value;
    
    % *WallTimeOption* (option to specify walltime requirement)
    % Mandatory for custom scheduler
    WallTimeOptionOpt = uq_process_option(...
        SchedulerVars, 'WallTimeOption', SchedulerDefault.WallTimeOption, 'char');
    validateattributes(WallTimeOptionOpt.Value,...
        {'char'}, {}, mfilename, '*SchedulerVars.WallTimeOption*')
    if strcmpi(scheduler,'custom') && WallTimeOptionOpt.Missing
        error('Missing *.WallTimeOption* for Custom scheduler.')
    end
    SchedulerVars.WallTimeOption = WallTimeOptionOpt.Value;
    
    % *NodesOption* (option to specify nodes requirement)
    % Optional for custom scheduler
    NodesOptionOpt = uq_process_option(...
        SchedulerVars, 'NodesOption', SchedulerDefault.NodesOption, 'char');
    validateattributes(NodesOptionOpt.Value,...
        {'char'}, {}, mfilename, '*SchedulerVars.NodesOption*')
    SchedulerVars.NodesOption = NodesOptionOpt.Value;
    
    % *CPUsOption* (option to specify CPUs requirement)
    % Mandatory for custom scheduler
    CPUsOptionOpt = uq_process_option(...
        SchedulerVars, 'CPUsOption', SchedulerDefault.CPUsOption, 'char');
    validateattributes(CPUsOptionOpt.Value,...
        {'char'}, {}, mfilename, '*SchedulerVars.CPUsOption*')
    if strcmpi(scheduler,'custom') && CPUsOptionOpt.Missing
        error('Missing *.CPUsOption* for Custom scheduler.')
    end
    SchedulerVars.CPUsOption = CPUsOptionOpt.Value;

    % *NodesCPUsOption* (option to specify both nodes and CPUs requirement)
    % Optional for custom scheduler
    NodesCPUsOptionOpt = uq_process_option(...
        SchedulerVars, 'NodesCPUsOption', SchedulerDefault.NodesCPUsOption, 'char');
    validateattributes(NodesCPUsOptionOpt.Value,...
        {'char'}, {}, mfilename, '*SchedulerVars.NodesCPUsOption*')
    SchedulerVars.NodesCPUsOption = NodesCPUsOptionOpt.Value;

    % *SubmitCommand* (scheduler command to submit a job)
    % Mandatory for custom scheduler
    SubmitCommandOpt = uq_process_option(...
        SchedulerVars, 'SubmitCommand', SchedulerDefault.SubmitCommand, 'char');
    validateattributes(SubmitCommandOpt.Value,...
        {'char'}, {}, mfilename, '*SchedulerVars.SubmitCommand*')
    if strcmpi(scheduler,'custom') && SubmitCommandOpt.Missing
        error('Missing *.SubmitCommand* for Custom scheduler.')
    end
    SchedulerVars.SubmitCommand = SubmitCommandOpt.Value;
    
    % *CancelCommand* (scheduler command to cancel a job)
    % Mandatory for custom scheduler
    CancelCommandOpt = uq_process_option(...
        SchedulerVars, 'CancelCommand', SchedulerDefault.CancelCommand, 'char');
    validateattributes(CancelCommandOpt.Value,...
        {'char'}, {}, mfilename, '*SchedulerVars.CancelCommand*')
    if strcmpi(scheduler,'custom') && CancelCommandOpt.Missing
        error('Missing *.CancelCommand* for Custom scheduler.')
    end
    SchedulerVars.CancelCommand = CancelCommandOpt.Value;
    
    % *SubmitOutputPattern* (pattern for parse job ID)
    % Mandatory for custom scheduler
    SubmitOutputPatternOpt = uq_process_option(...
        SchedulerVars, 'SubmitOutputPattern', SchedulerDefault.SubmitOutputPattern, 'char');
    validateattributes(SubmitOutputPatternOpt.Value,...
        {'char'}, {}, mfilename, '*SchedulerVars.SubmitOutputPattern*')
    if strcmpi(scheduler,'custom') && SubmitOutputPatternOpt.Missing
        error('Missing *.SubmitOutputPattern* for Custom scheduler.')
    end
    SchedulerVars.SubmitOutputPattern = SubmitOutputPatternOpt.Value;
    
    % *CustomSettings* (Additional custom and static settings)
    % Optional for any type of schedulers
    CustomSettingsOpt = uq_process_option(...
        SchedulerVars, 'CustomSettings',...
        SchedulerDefault.CustomSettings, {'cell','char'});
    if CustomSettingsOpt.Invalid
        warning('Invalid *CustomSettings* specification. Revert to default.')
        SchedulerVars.CustomSettings = CustomSettingsOpt.Default;
    else
        if iscell(CustomSettingsOpt.Value)
            SchedulerVars.CustomSettings = CustomSettingsOpt.Value;
        else
            SchedulerVars.CustomSettings = {CustomSettingsOpt.Value};
        end
    end

else
    
    % Otherwise, use the default
    SchedulerVars = SchedulerDefault;

end

% Add Scheduler name and variables to the RemoteConfig
RemoteConfig.Scheduler = lower(scheduler);
RemoteConfig.SchedulerVars = SchedulerVars;

%% MATLAB Settings

% MATLABCommand
% The full path of MATLAB command in the remote machine
if ~exist('MATLABCommand','var')
    MATLABCommand = '';
end
validateattributes(MATLABCommand,...
        {'char'}, {}, mfilename, '*MATLABCommand*')
RemoteConfig.MATLABCommand = MATLABCommand;

% MATLABOptions (Startup options)
% The additional arguments used in the call to MATLAB in the remote machine
singleCompThreadFound = false;
singleCompThreadFlag = '-singleCompThread';  % Run MATLAB in single thread
runInteractiveOption = '-r';                 % Run statements interactively
if ~exist('MATLABOptions','var')
    % Interactive run is mandatory
    MATLABOptions = runInteractiveOption;
else
    validateattributes(MATLABOptions,...
        {'char'}, {}, mfilename, '*MATLABOptions*')
    % -r is mandatory
    if isempty(strfind(MATLABOptions,runInteractiveOption))
        MATLABOptions = [uq_strip(MATLABOptions) ' ' runInteractiveOption];
    end
    
    % -singleCompThread is mandatory
    if ~isempty(strfind(MATLABOptions,singleCompThreadFlag))
        singleCompThreadFound = true;
        MATLABOptions = strrep(MATLABOptions, singleCompThreadFlag, '');
    end

end
RemoteConfig.MATLABOptions = uq_strip(MATLABOptions);

% MATLABSingleThread
% In some cluster policy, multiple MATLAB processes have to be executed
% in single thread.
if exist('MATLABSingleThread','var') && singleCompThreadFound
    if ~MATLABSingleThread
        error(['Both MATLABSingleThread option defined and they are',...
            'inconsistent.'])
    end
elseif ~exist('MATLABSingleThread','var') || singleCompThreadFound
    MATLABSingleThread = true;
else
    validateattributes(MATLABSingleThread,...
        {'logical'}, {}, mfilename, '*SingleThreadMATLAB*')
end
RemoteConfig.MATLABSingleThread = MATLABSingleThread;

%% UQLab Settings

% RemoteUQLabPath
% Location of UQLab in the remote machine
if ~exist('RemoteUQLabPath','var')
    RemoteUQLabPath = '';
end
validateattributes(RemoteUQLabPath,...
        {'char'}, {}, mfilename, '*RemoteUQLabPath*')
RemoteConfig.RemoteUQLabPath = RemoteUQLabPath;

%% Remote machine configuration

% RemoteFolder
% The (main) remote execution folder (default: home)
if ~exist('RemoteFolder','var')
    error('Directory to store files in the remote machine must be specified.')
end
% 'RemoteFolder' must be a char
validateattributes(RemoteFolder,...
        {'char'}, {}, mfilename, '*RemoteFolder*')
% Remote trailing slash
if strcmpi(RemoteFolder(end),'/')
    RemoteFolder = RemoteFolder(1:end-1);
end
% Remote folder cannot be specified with the tilde notation
if strcmpi(RemoteFolder(1),'~')
    error('Directory in the remote machine must not be specified with tilde.')
end
RemoteConfig.RemoteFolder = RemoteFolder;

% Special checks for a known issue in certain versions of TORQUE
% Remote folder cannot contain whitespaces (produce a warning)
if ~isempty(regexp(RemoteFolder, '\s+', 'once')) && strcmpi(scheduler,'torque')
    warning('Directory in the remote machine must not contain whitespaces.\n%s',...
        'For certain versions of TORQUE (< v5.1.2), this might cause a problem.')
end

% EnvSetup
% The commands that will be run on the login (front) node
% before running the parallel job, use to set up the environment.
if ~exist('EnvSetup','var')
    EnvSetup = {};
end
if ~iscell(EnvSetup)
    EnvSetup = {EnvSetup};
end
if isrow(EnvSetup)
    EnvSetup = transpose(EnvSetup);
end
RemoteConfig.EnvSetup = EnvSetup;

% PrevCommands
% The commands that will be run on each node,
% use to set up the environment of each compute node.
if ~exist('PrevCommands','var')
    PrevCommands = {};
end
if isempty(PrevCommands)
    PrevCommands = {};
end
if ~iscell(PrevCommands)
    PrevCommands = {PrevCommands};
end
if isrow(PrevCommands)
    PrevCommands = transpose(PrevCommands);
end
RemoteConfig.PrevCommands = PrevCommands;

% Shebang (bash)
if ~exist('Shebang','var')
    Shebang = uq_Dispatcher_params_getDefaultOpt('Shebang');
end

RemoteConfig.Shebang = Shebang;

%% MPI
MPIDefault = uq_Dispatcher_params_getDefaultOpt('MPI');

if exist('MPI','var')
    % MPI Implementation
    MPIImplementationOpt = uq_process_option(...
        MPI, 'Implementation', MPIDefault.Implementation, 'char');
    % Validate type and size
    validateattributes(MPIImplementationOpt.Value,...
            {'char'}, {'row'}, mfilename, '*MPI.Implementation*')
    mpiName = MPIImplementationOpt.Value;
    
    % Get MPI-specific options, if 'RankNo' is specified, use it as-is.
    if ~isfield(MPI,'RankNo') || isempty(MPI.RankNo)
        MPI = uq_Dispatcher_params_getMPI(mpiName);
    end
else
    MPI = MPIDefault;
end

RemoteConfig.MPI = MPI;

end