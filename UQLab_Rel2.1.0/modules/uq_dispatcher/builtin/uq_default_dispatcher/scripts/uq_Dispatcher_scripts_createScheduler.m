function schedulerScript = uq_Dispatcher_scripts_createScheduler(JobObj,DispatcherObj)
%UQ_DISPATCHER_SCRIPTS_CREATESCHEDULER creates the content of a Job script.

%% Set Local Variables

remoteFolder = JobObj.RemoteFolder;
% Safe guard against possible whitespaces in 'remoteFolder'
remoteFolder = uq_Dispatcher_util_writePath(remoteFolder, 'linux', true);

numProcs = JobObj.Task.NumProcs;  % Number of actual (parallel) processes

% Get the requested number of CPUs and nodes
numCPUs = DispatcherObj.Internal.NumCPUs;
numNodes = DispatcherObj.Internal.NumNodes;
CPUsPerNode = numCPUs / numNodes;
if numProcs > numCPUs
    CPUsPerNode = numProcs;  % Follows the number of actual processes
end

% Commands to execute on the compute nodes (if applicable)
prevCommands = DispatcherObj.Internal.RemoteConfig.PrevCommands;

mpiFile = DispatcherObj.Internal.RemoteFiles.MPI;

RemoteConfig = DispatcherObj.Internal.RemoteConfig;
SchedulerVars = RemoteConfig.SchedulerVars;

%% Write the Shebang
schedulerScript{1} = RemoteConfig.Shebang;

%% Write the directives part
% Job name
if ~isempty(SchedulerVars.JobNameOption)
    jobName = sprintf(SchedulerVars.JobNameOption,JobObj.Name);
    schedulerScript{end+1} = sprintf(...
        '%s %s', SchedulerVars.Pragma, jobName);
end
% Standard output redirected file
if ~isempty(SchedulerVars.StdOutFileOption)
    stdOutFile = sprintf(...
        SchedulerVars.StdOutFileOption,[JobObj.Name '.stdout']);
    schedulerScript{end+1} = sprintf(...
        '%s %s', SchedulerVars.Pragma, stdOutFile);
end
% Standard error redirected file
if ~isempty(SchedulerVars.StdErrFileOption)
    stdErrFile = sprintf(...
        SchedulerVars.StdErrFileOption,[JobObj.Name '.stderr']);
    schedulerScript{end+1} = sprintf(...
        '%s %s', SchedulerVars.Pragma, stdErrFile);
end
% WallTime requirement
if ~isempty(SchedulerVars.WallTimeOption)
    wallTime = sprintf(SchedulerVars.WallTimeOption,JobObj.WallTime);
    schedulerScript{end+1} = sprintf(...
        '%s %s', SchedulerVars.Pragma, wallTime);
end
% Nodes requirement
if ~isempty(SchedulerVars.NodesOption)
    nodes = sprintf(SchedulerVars.NodesOption,numNodes);
    schedulerScript{end+1} = sprintf(...
        '%s %s', SchedulerVars.Pragma, nodes);
end
% CPUs requirement
if ~isempty(SchedulerVars.CPUsOption)
    cpus = sprintf(SchedulerVars.CPUsOption,CPUsPerNode);
    schedulerScript{end+1} = sprintf(...
        '%s %s', SchedulerVars.Pragma, cpus);
end
% Both Nodes and CPUs requirement
if ~isempty(SchedulerVars.NodesCPUsOption)
    nodesCPUs = sprintf(SchedulerVars.NodesCPUsOption, numNodes, CPUsPerNode);
    schedulerScript{end+1} = sprintf(...
        '%s %s', SchedulerVars.Pragma, nodesCPUs);
end

%% Write the Custom Job Settings
if ~isempty(RemoteConfig.SchedulerVars.CustomSettings)
    customDirectives = cellfun(...
        @(x) sprintf('\n%s %s', SchedulerVars.Pragma, x),...
        RemoteConfig.SchedulerVars.CustomSettings, 'UniformOutput', false);
    schedulerScript = [schedulerScript customDirectives];
end
schedulerScript{end+1} = '';

%% Write the body

% Add the hostname
schedulerScript{end+1} = 'echo Running on host `hostname`';

% Add the date
schedulerScript{end+1} = 'echo Time is `date`';

% Add the working directory
schedulerScript{end+1} = 'echo Directory is `pwd`';

schedulerScript{end+1} = '';

% Add possible previous commands (already formatted)
if ~isempty(prevCommands)
    schedulerScript = [schedulerScript prevCommands];
    schedulerScript{end+1} = '';
end

% Go to remote folder
schedulerScript{end+1} = sprintf('cd %s',remoteFolder);

% Create logs folder
schedulerScript{end+1} = 'mkdir logs';

schedulerScript{end+1} = '';

% Create log file that the job has started
schedulerScript{end+1} = sprintf(...
    'touch %s',DispatcherObj.Internal.RemoteFiles.LogStart);


mpiImplementation = DispatcherObj.Internal.RemoteConfig.MPI.Implementation;

if strcmpi(mpiImplementation,'openmpi')
    % '--report-pid' is only supported in OpenMPI
    schedulerScript{end+1} = sprintf(...
        'mpirun --report-pid %s -np %d %s ./%s',...
        DispatcherObj.Internal.RemoteFiles.MPIRunPID, numProcs,...
        SchedulerVars.HostFile, mpiFile);
else
    if strcmpi(myDispatcher.Internal.RemoteConfig.Scheduler,'none')
        % Create command to execute MPI (send to the background)
        % Then fetch the PID of 'mpirun' as the Job ID
        schedulerScript{end+1} = sprintf(...
            'mpirun -np %d %s ./%s &',...
             numProcs, SchedulerVars.HostFile, mpiFile);
        schedulerScript{end+1} = sprintf('echo $! > %s',...
            DispatcherObj.Internal.RemoteFiles.MPIRunPID);
    else
        % Otherwise Job ID is the one issued by the scheduler
        % and don't send the job to the background
        schedulerScript{end+1} = sprintf(...
            'mpirun -np %d %s ./%s',...
             numProcs, SchedulerVars.HostFile, mpiFile);        
    end
end

% Return the scheduler script as char vector
schedulerScript = sprintf('%s\n',schedulerScript{:});

end
