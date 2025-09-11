function scriptMATLAB = uq_Dispatcher_scripts_createMapMATLAB(JobObj,DispatcherObj)
%UQ_DISPATCHER_SCRIPTS_CREATEMAPMATLAB creates a MATLAB parallel mapping script.

scriptMATLAB = {};

%% Suppress warnings
scriptMATLAB{end+1} = 'warning(''off'',''MATLAB:DELETE:FileNotFound'')';
scriptMATLAB{end+1} = '';

%% Go to remote execution folder
scriptMATLAB{end+1} = sprintf('cd(''%s'')',JobObj.RemoteFolder);
scriptMATLAB{end+1} = '';

%% Set additional paths to the remote MATLAB instance

% Additional directories
addDirectories = [JobObj.AddToPath,DispatcherObj.AddToPath];
scriptMATLAB{end+1} = '%% Add directories to Path';
if ~isempty(addDirectories)
    scriptMATLAB{end+1} = uq_Dispatcher_matlab_addToPath(addDirectories);
end
scriptMATLAB{end+1} = '';

% Additional directories including their sub-directories
addTrees = [JobObj.AddTreeToPath,DispatcherObj.AddTreeToPath];
scriptMATLAB{end+1} = '%% Add trees to Path';
if ~isempty(addTrees)
    scriptMATLAB{end+1} = uq_Dispatcher_matlab_addTreeToPath(addTrees);
end
scriptMATLAB{end+1} = '';

%% Get node number and current CPU rank and index
SchedulerVars = DispatcherObj.Internal.RemoteConfig.SchedulerVars;
cpusPerNode = DispatcherObj.Internal.CPUsPerNode;
MPIVars = DispatcherObj.Internal.RemoteConfig.MPI;

scriptMATLAB{end+1} = '%% Get node number and rank number';
scriptMATLAB{end+1} =  uq_Dispatcher_scripts_getNodeRank(...
    'matlab', SchedulerVars, MPIVars, cpusPerNode);
scriptMATLAB{end+1} = '';

%% Parallel mapping execution section

% Start UQLab and retrieve saved session (optional)
if JobObj.Task.UQLab
    remoteUQLabPath = DispatcherObj.Internal.RemoteConfig.RemoteUQLabPath;
    if JobObj.Task.SaveUQLabSession
        sessionFile = DispatcherObj.Internal.RemoteFiles.UQLabSession;
    else
        sessionFile = '';
    end
    scriptMATLAB{end+1} = '%% Load UQLab';
    scriptMATLAB{end+1} = uq_Dispatcher_matlab_loadUQLab(...
        remoteUQLabPath,sessionFile);
    scriptMATLAB{end+1} = '';
end

% Load data
% Compute the chunk size
numTasks = JobObj.Task.NumTasks;  % Number of tasks in the Job
numProcs = JobObj.Task.NumProcs;  % Number of actual (parallel) processes
chunkSize = uq_Dispatcher_util_getChunkSize(numTasks,numProcs);

scriptMATLAB{end+1} = '%% Load data';
scriptMATLAB{end+1} = sprintf('chunkSize = %d;',chunkSize);
scriptMATLAB{end+1} = sprintf('minIdx = (cpuIdx-1)*chunkSize + 1;');
scriptMATLAB{end+1} = sprintf('maxIdx = (minIdx-1) + chunkSize;');
scriptMATLAB{end+1} = sprintf('if cpuIdx == %d',numProcs);
scriptMATLAB{end+1} = sprintf('maxIdx = %d;',numTasks);
scriptMATLAB{end+1} = sprintf('end');

dataFile = sprintf('%s.mat',...
    DispatcherObj.Internal.RemoteFiles.Data);
scriptMATLAB{end+1} = sprintf('matInpObj = matfile(''%s'');',dataFile);
scriptMATLAB{end+1} = '';

% Must cell input be expanded?
if JobObj.Task.ExpandCell
    scriptMATLAB{end+1} = 'expandCell = true;';
else
    scriptMATLAB{end+1} = 'expandCell = false;';
end
scriptMATLAB{end+1} = '';

% Load the inputs
inputs = JobObj.Data.Inputs;
if isa(inputs,'function_handle')
    % Load the parameters for the sequence generator
    scriptMATLAB{end+1} = 'seqGenParameters = matInpObj.SeqGenParameters;';
    % Matrix mapping
    scriptMATLAB{end+1} = sprintf('matrixMapping = ''%s'';',...
        JobObj.Task.MatrixMapping);
    % Execute sequence generator function in the remote
    % The last element of 'seqGenParameters' is used for matrix mapping
    scriptMATLAB{end+1} = sprintf('inputs = %s(seqGenParameters{:});',...
        func2str(inputs));
    % Make things a column format
    scriptMATLAB{end+1} = 'if (isnumeric(inputs) || islogical(inputs)) && ismatrix(inputs)';
    scriptMATLAB{end+1} = '    switch lower(matrixMapping)';
    scriptMATLAB{end+1} = '        case ''byrows''';
    scriptMATLAB{end+1} = '            inputs = arrayfun(@(i) {inputs(i,:)},...';
    scriptMATLAB{end+1} = '                transpose(1:size(inputs,1)), ''UniformOutput'', false);';
    scriptMATLAB{end+1} = '        case ''bycolumns''';
    scriptMATLAB{end+1} = '            inputs = arrayfun(@(i) {inputs(:,i)}, 1:size(inputs,2),...';
    scriptMATLAB{end+1} = '                ''UniformOutput'', false);';
    scriptMATLAB{end+1} = '    end';
    scriptMATLAB{end+1} = '    expandCell = true;';
    scriptMATLAB{end+1} = 'end';
    scriptMATLAB{end+1} = 'inputs = inputs(:);';
    % Select only the relevant row
    scriptMATLAB{end+1} = 'inputs = inputs(minIdx:maxIdx);';
else
    scriptMATLAB{end+1} = 'inputs = matInpObj.Inputs(minIdx:maxIdx,:);';
end
scriptMATLAB{end+1} = 'parameters = matInpObj.Parameters;';
if ~isempty(JobObj.Data.Model)
    % For anonymous function, the formula is load into 'model' variable.
    % The same name is used in JobObj.Task.Command for such function.
    scriptMATLAB{end+1} = sprintf('model = %s;',JobObj.Data.Model);
end
scriptMATLAB{end+1} = '';

% Get the requested number of output arguments
scriptMATLAB{end+1} = '%% Number of output arguments';
scriptMATLAB{end+1} = sprintf('numOfOutArgs = %d;', JobObj.Task.NumOfOutArgs);
scriptMATLAB{end+1} = '';

% Main execution body
scriptMATLAB{end+1} = 'try';
% The command
if isempty(JobObj.Data.Model)
    commandChar = sprintf(...
        '[Y{1:numOfOutArgs}] = uq_map(@%s, inputs, ''Parameters'', parameters, ''ExpandCell'', expandCell, ''ErrorHandler'', %s);',...
        func2str(JobObj.Task.Command), JobObj.Task.ErrorHandler);
else
    commandChar = sprintf(...
        '[Y{1:numOfOutArgs}] = uq_map(model, inputs, ''Parameters'', parameters, ''ExpandCell'', expandCell, ''ErrorHandler'', %s);',...
        JobObj.Task.ErrorHandler);
end
scriptMATLAB{end+1} = commandChar;
% Catch error
scriptMATLAB{end+1} = 'catch ME';
scriptMATLAB{end+1} = [...
    'fid = fopen(sprintf(''',...
    DispatcherObj.Internal.RemoteFiles.LogError,...
    ''',cpuIdxStr),''at'');'];
scriptMATLAB{end+1} = 'fprintf(fid, ''%s\n'', ME.message);';
scriptMATLAB{end+1} = 'fclose(fid);';
scriptMATLAB{end+1} = 'save(sprintf(''uqProc_%s_ME.mat'',cpuIdxStr),''ME'')';
scriptMATLAB{end+1} = 'error(''Error(s) is thrown in the process. Check the process-based error message.'')';
scriptMATLAB{end+1} = 'end';
scriptMATLAB{end+1} = '';

% Dump output
outFile = [DispatcherObj.Internal.RemoteFiles.Output,'_%s.mat'];

scriptMATLAB{end+1} = '%% Dump output';
scriptMATLAB{end+1} = sprintf(...
    'matOutObj = matfile(sprintf(''%s'',cpuIdxStr));',outFile);
scriptMATLAB{end+1} = 'matOutObj.Y = Y;';
scriptMATLAB{end+1} = '';

% Logging (execution is completed)
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

%% Return the script as multiline char
scriptMATLAB = [sprintf('%s\n',scriptMATLAB{1:end-1}), scriptMATLAB{end}];

end
