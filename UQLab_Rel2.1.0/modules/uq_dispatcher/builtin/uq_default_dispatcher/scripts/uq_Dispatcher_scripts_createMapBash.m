function scriptBash = uq_Dispatcher_scripts_createMapBash(JobObj,DispatcherObj)
%UQ_DISPATCHER_SCRIPTS_CREATEMAPBASH creates a Bash parallel mapping script.

%% Set local variables

remoteFolder = JobObj.RemoteFolder;
% Safe guard against possible whitespaces in 'remoteFolder'
remoteFolder = uq_Dispatcher_util_writePath(remoteFolder, 'linux', true);

scriptBash = {};

%% Use the appropriate Shebang
scriptBash{end+1} = DispatcherObj.Internal.RemoteConfig.Shebang;
scriptBash{end+1} = '';

%% Go to Remote Execution Folder
scriptBash{end+1} = sprintf('cd %s',remoteFolder);
scriptBash{end+1} = '';

%% Set Additional Path the Remote BASH Environment PATH
bashEnvFile = DispatcherObj.Internal.RemoteFiles.SetPATH;
scriptBash{end+1} = '# Update PATH';
scriptBash{end+1} = sprintf('. %s',bashEnvFile);  % Dot notation to source
scriptBash{end+1} = '';

%% Get Node Number and Current CPU Rank and Index
SchedulerVars = DispatcherObj.Internal.RemoteConfig.SchedulerVars;
cpusPerNode = DispatcherObj.Internal.CPUsPerNode;
MPIVars = DispatcherObj.Internal.RemoteConfig.MPI;

nodeRank = uq_Dispatcher_scripts_getNodeRank(...
    'bash', SchedulerVars, MPIVars, cpusPerNode);

scriptBash{end+1} = '# Get Node and Rank';
scriptBash{end+1} = nodeRank;

%% Parallel mapping execution section

% Compute the chunk size
numTasks = JobObj.Task.NumTasks;  % Number of tasks in the Job
numProcs = JobObj.Task.NumProcs;  % Number of actual (parallel) processes
chunkSize = uq_Dispatcher_util_getChunkSize(numTasks,numProcs);

% Create wrapped function
scriptBash{end+1} = '# Create Wrapped Function';
scriptBash{end+1} = 'function wrappedCommand() {';
scriptBash{end+1} = uq_Dispatcher_bash_parseCommand(JobObj.Task.Command);
scriptBash{end+1} = '}';
scriptBash{end+1} = '';

% Load data (create indices of runs)
scriptBash{end+1} = '# Load Local Data';
scriptBash{end+1} = sprintf('chunkSize=%d',chunkSize);
scriptBash{end+1} = 'minIdx=$(( ($cpuIdx - 1) * $chunkSize + 1 ))';
scriptBash{end+1} = 'maxIdx=$(( ($minIdx - 1) + $chunkSize ))';
scriptBash{end+1} = sprintf('if [ $cpuIdx -eq %d ]; then',numProcs);
scriptBash{end+1} = sprintf('maxIdx=%d;',numTasks);
scriptBash{end+1} = 'fi';
scriptBash{end+1} = 'runList=( $( seq  $minIdx $maxIdx ) )';

% Load data (get the name of the data file)
dataFile = 'uq_tmp_data.txt';
scriptBash{end+1} = sprintf('inputsFile="%s"',dataFile);
scriptBash{end+1} = '';

% Main Execution Body
scriptBash{end+1} = '# Main Execution';
scriptBash{end+1} = 'for j in ${runList[@]}; do';         % Loop over lines
scriptBash{end+1} = 'input=`sed "${j}q;d" $inputsFile`';  % Get the line
scriptBash{end+1} = ['wrappedCommand ${input} ',...
    '1> ./logs/wrappedCommand_${j}.stdout ',...
    '2> ./logs/wrappedCommand_${j}.stderr'];
scriptBash{end+1} = 'exitStatus=$?';
scriptBash{end+1} = sprintf('echo $exitStatus > %s/logs/wrappedCommand_${j}.stat',...
    remoteFolder);

% Go back to Remote Execution Folder
scriptBash{end+1} = sprintf('cd %s',remoteFolder);
scriptBash{end+1} = '';

scriptBash{end+1} = 'if [ $exitStatus -ne 0 ]; then';
scriptBash{end+1} = 'touch ./logs/wrappedCommand_${j}.err';
scriptBash{end+1} = 'fi';
scriptBash{end+1} = 'done';
scriptBash{end+1} = '';

% Check for any execution error, write down process-based error log file
scriptBash{end+1} = '# Check if any of the execution error';
scriptBash{end+1} = 'for j in ${runList[@]}; do';
scriptBash{end+1} = 'if [ -e "./logs/wrappedCommand_${j}.err" ]; then';
scriptBash{end+1} = 'touch .uqProc_${cpuIdxStr}_ExecErr';
scriptBash{end+1} = 'break';
scriptBash{end+1} = 'fi';
scriptBash{end+1} = 'done';
scriptBash{end+1} = '';

% Log that execution is completed
scriptBash{end+1} = '# Logging: Completed';
scriptBash{end+1} = 'if [ ! -f .uqProc_${cpuIdxStr}_ExecErr ]; then';
scriptBash{end+1} = 'touch .uqProc_${cpuIdxStr}_ExecCpl';
scriptBash{end+1} = 'fi';
scriptBash{end+1} = '';

scriptBash = sprintf('%s\n',scriptBash{:});

end
