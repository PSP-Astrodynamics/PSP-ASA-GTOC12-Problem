function scriptMATLAB = uq_Dispatcher_scripts_createEvalModel(JobObj,DispatcherObj)
%UQ_DISPATCHER_SCRIPTS_CREATEEVALMODEL creates the content of a MATLAB
%   parallel uq_evalModel remote script.

scriptMATLAB = {};

%% Suppress warnings
scriptMATLAB{end+1} = 'warning(''off'',''MATLAB:DELETE:FileNotFound'')';
scriptMATLAB{end+1} = '';

%% Go to remote execution folder
% NOTE: 'remoteFolder' does not need to be safe guarded against whitespaces
% because MATLAB 'cd' command can take care of that.
scriptMATLAB{end+1} = sprintf('cd(''%s'')',JobObj.RemoteFolder);
scriptMATLAB{end+1} = '';

%% Set additional paths to the remote MATLAB instance
addDirectories = DispatcherObj.AddToPath;
scriptMATLAB{end+1} = '%% Add directories to Path';
if ~isempty(addDirectories)
    scriptMATLAB{end+1} = uq_Dispatcher_matlab_addToPath(addDirectories);
end
scriptMATLAB{end+1} = '';

% Additional directories including their sub-directories
addTrees = DispatcherObj.AddTreeToPath;
scriptMATLAB{end+1} = '%% Add trees to Path';
if ~isempty(addTrees)
    scriptMATLAB{end+1} = uq_Dispatcher_matlab_addTreeToPath(addTrees);
end
scriptMATLAB{end+1} = '';

%% Get node number and the current CPU rank and index
SchedulerVars = DispatcherObj.Internal.RemoteConfig.SchedulerVars;
cpusPerNode = DispatcherObj.Internal.CPUsPerNode;
MPIVars = DispatcherObj.Internal.RemoteConfig.MPI;

scriptMATLAB{end+1} = '%% Get node number and rank number';
scriptMATLAB{end+1} =  uq_Dispatcher_scripts_getNodeRank(...
    'matlab', SchedulerVars, MPIVars, cpusPerNode);
scriptMATLAB{end+1} = '';

%% Parallel uq_evalModel execution section

% Start UQLab and retrieve saved session
remoteUQLabPath = DispatcherObj.Internal.RemoteConfig.RemoteUQLabPath;
sessionFile = DispatcherObj.Internal.RemoteFiles.UQLabSession;
scriptMATLAB{end+1} = '%% Load UQLab';
scriptMATLAB{end+1} = uq_Dispatcher_matlab_loadUQLab(...
    remoteUQLabPath,sessionFile);
scriptMATLAB{end+1} = '';
    
% Load data
scriptMATLAB{end+1} = '%% Load data';
dataFile = sprintf('%s.mat',...
    DispatcherObj.Internal.RemoteFiles.Data);
scriptMATLAB{end+1} = sprintf('matInpObj = matfile(''%s'');',dataFile);
scriptMATLAB{end+1} = 'inputs = matInpObj.Inputs;';
scriptMATLAB{end+1} = 'model = matInpObj.Model;';
scriptMATLAB{end+1} = 'UQ_dispatcher = uq_getDispatcher;';

% NOTE: Make sure that the number of CPUs *does not* exceed
% the number of tasks (use the pre-computed number of processes)
numProcs = JobObj.Task.NumProcs;
scriptMATLAB{end+1} = sprintf('UQ_dispatcher.Runtime.ncpu = %d;',numProcs);
scriptMATLAB{end+1} = 'UQ_dispatcher.Runtime.cpuID = cpuIdx;';
scriptMATLAB{end+1} = '';

% Get the requested number of output arguments
scriptMATLAB{end+1} = '%% Number of output arguments';
scriptMATLAB{end+1} = sprintf('numOfOutArgs = %d;', JobObj.Task.NumOfOutArgs);
scriptMATLAB{end+1} = '';

% Main execution body
scriptMATLAB{end+1} = 'try';
% TODO: when the NumOfOutArgs are available we can grab multiple output
% arguments
commandChar = sprintf('[Y{1:numOfOutArgs}] = %s(model, inputs, ''HPC'');',...
    func2str(JobObj.Task.Command));
scriptMATLAB{end+1} = commandChar;

% Catch error, open a log file, and dump the error message
scriptMATLAB{end+1} = 'catch ME';
scriptMATLAB{end+1} = [...
    'fid = fopen(sprintf(''',...
    DispatcherObj.Internal.RemoteFiles.LogError,...
    ''',cpuIdxStr),''at'');'];
scriptMATLAB{end+1} = 'fprintf(fid, ''%s\n'', ME.message);';
scriptMATLAB{end+1} = 'fclose(fid);';
scriptMATLAB{end+1} = 'save(sprintf(''uqProc_%s_ME.mat'',cpuIdxStr),''ME'')';
scriptMATLAB{end+1} = 'end';

% Dump output
outFile = [DispatcherObj.Internal.RemoteFiles.Output,'_%s.mat'];

scriptMATLAB{end+1} = '%% Dump output';
scriptMATLAB{end+1} = sprintf(...
    'matOutObj = matfile(sprintf(''%s'',cpuIdxStr));',outFile);
scriptMATLAB{end+1} = 'matOutObj.Y = Y;';
scriptMATLAB{end+1} = '';

% Log that execution has been completed
scriptMATLAB{end+1} = '%% Log completed execution';
scriptMATLAB{end+1} = 'if ~exist(''ME'',''var'')';
logFileCompleted = [...
    'sprintf(''',...
    DispatcherObj.Internal.RemoteFiles.LogCompleted,...
    ''',cpuIdxStr)'];
scriptMATLAB{end+1} = sprintf('f = fopen(%s,''wt'');',logFileCompleted);
scriptMATLAB{end+1} = 'fclose(f);';
scriptMATLAB{end+1} = 'end';
scriptMATLAB{end+1} = '';

%% Exit remote MATLAB session
scriptMATLAB{end+1} = 'exit';

%% Return the script as multiline char array
scriptMATLAB = [sprintf('%s\n',scriptMATLAB{1:end-1}),scriptMATLAB{end}];

end
