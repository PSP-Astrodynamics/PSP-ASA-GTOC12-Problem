function scriptMATLAB = uq_Dispatcher_scripts_createMATLAB(DispatcherObj,JobObj)
%UQ_DISPATCHER_SCRIPTS_CREATEMATLAB creates a MATLAB script.

%% Input Verification

%% Define Local Variables

% Remote folder specific to a Job
remoteFolder = JobObj.RemoteFolder;

% Folder separator in the remote machine
remoteSep = DispatcherObj.Internal.RemoteSep;

scriptMATLAB = '';

%% Suppress Unnecessary Warnings
scriptMATLAB = appendChar(scriptMATLAB,...
    sprintf('warning(''off'',''MATLAB:DELETE:FileNotFound'')\n'));

%% Go to Remote Execution Folder
scriptMATLAB = appendChar(scriptMATLAB,...
    sprintf('cd ''%s''\n', remoteFolder));

%% Set Path to the Remote MATLAB Instance

% Additional folders: from both Job and Dispatcher
addToPath = [JobObj.AddToPath,DispatcherObj.Internal.AddToPath];
if ~isempty(addToPath)
    scriptMATLAB = appendChar(scriptMATLAB,sprintf('%% Add to Path\n'));
    for i = 1:length(addToPath)
        scriptMATLAB = appendChar(scriptMATLAB,...
            sprintf('addpath(''%s'')\n',addToPath{i}));
    end
end

% Additional folders with subfolders: from both Job and Dispatcher
addTreeToPath = [JobObj.AddTreeToPath,DispatcherObj.Internal.AddTreeToPath];
if ~isempty(addTreeToPath)
    scriptMATLAB = appendChar(scriptMATLAB,sprintf('%% Add Tree to Path\n'));
    for i = 1:length(addTreeToPath)
        scriptMATLAB = appendChar(scriptMATLAB,...
            sprintf('addpath(genpath(''%s''))\n',addTreeToPath{i}));
    end
end

scriptMATLAB = appendChar(scriptMATLAB,sprintf('\n'));

%% Get Node Number and Current CPU Rank and Index
scriptMATLAB = appendChar(scriptMATLAB,sprintf('%% Get Node and Rank\n'));

SchedulerVars = DispatcherObj.Internal.RemoteConfig.SchedulerVars;

% Get the node number from the environment variable
nodeNoName = strrep(SchedulerVars.NodeNo,'$','');
if strcmp(nodeNoName,'0')
    scriptMATLAB = appendChar(scriptMATLAB,...
        sprintf('NodeNo = %s;\n',nodeNoName));
else
    scriptMATLAB = appendChar(scriptMATLAB,...
        sprintf('NodeNo = str2double(getenv(''%s''));\n',nodeNoName));
end

% Get the current CPU rank number from the environment variable
rankNoName = strrep(SchedulerVars.RankNo,'$','');
scriptMATLAB = appendChar(scriptMATLAB,...
    sprintf('RankNo = str2double(getenv(''%s''));\n', rankNoName));

% Compute the current CPU index
% This index identifies a remote worker used in, for example,
% polling and merging results.
procPerNode = DispatcherObj.Internal.ProcPerNode;
scriptMATLAB = appendChar(scriptMATLAB,...
    sprintf('cpuIdx = NodeNo*%s + (RankNo+1);\n', num2str(procPerNode)));
% Save the variable also as a string with 4 digits
scriptMATLAB = appendChar(scriptMATLAB,...
    sprintf('cpuIdxStr = sprintf(''%%.4d'',cpuIdx);\n'));

scriptMATLAB = appendChar(scriptMATLAB,sprintf('\n'));

%% Logging - Execution is Running
scriptMATLAB = appendChar(scriptMATLAB,sprintf('%% Logging: Running\n'));

% Delete the residual file indicating that execution has been completed
% from previous execution
% execCompletedFile = '[''.uqlab_process_'' ExIdxStr ''_execution_completed'']';
% cmdLine = sprintf('delete(%s);\n',execCompletedFile);
% scriptMATLAB = sprintf('%s %s', scriptMATLAB, cmdLine);
% 
% % Delete the residual file indicating that execution has errors
% execErrorFile = '[''.uqlab_process_'' ExIdxStr ''_execution_error'']';
% cmdLine = sprintf('delete(%s);\n',execErrorFile);
% scriptMATLAB = sprintf('%s %s', scriptMATLAB, cmdLine);

% Create a file indicating the initialization of the execution
logFileRunning = '[''.uqlab_process_'' cpuIdxStr ''_execution_running'']';
scriptMATLAB = appendChar(scriptMATLAB,...
    sprintf('f = fopen(%s,''wt'');\nfclose(f);\n',logFileRunning));
scriptMATLAB = appendChar(scriptMATLAB,sprintf('\n'));

%% Start UQLab and Retrieve Session (Optional)
if JobObj.UQLab
    scriptMATLAB = appendChar(scriptMATLAB,sprintf('%% Load UQLab\n'));
    % Add Remote UQLab folder
    remoteUQLabPath = DispatcherObj.Internal.RemoteConfig.RemoteUQLabPath;
    remoteUQLabPath = [remoteUQLabPath remoteSep 'core'];
    % NOTE: Don't use 'fullfile' as the separator will be client dependent,
    % while the remote script is always run in a Linux machine.
    scriptMATLAB = appendChar(scriptMATLAB,...
        sprintf('addpath(''%s'')\n', remoteUQLabPath));
    
    % Start UQLab
    if ~isempty(JobObj.UQLabSessionFile)
        % Start UQLab with a session file
        sessionFile = JobObj.UQLabSessionFile;
        scriptMATLAB = appendChar(scriptMATLAB,...
            sprintf('uqlab(''-nosplash'',''%s'');\n', sessionFile));
        % Retrieve the session
        scriptMATLAB = appendChar(scriptMATLAB,sprintf('uq_retrieveSession\n'));
    else
        scriptMATLAB = appendChar(scriptMATLAB,sprintf('uqlab(''-nosplash'');\n'));
    end
end
scriptMATLAB = appendChar(scriptMATLAB,sprintf('\n'));

%% Load Data
scriptMATLAB = appendChar(scriptMATLAB,sprintf('%% Loading Local Data\n'));
loadData = JobObj.Commands.LoadData;
if ~isempty(loadData)
    for i = 1:numel(loadData)
        scriptMATLAB = appendChar(scriptMATLAB,...
            sprintf('%s\n',loadData{i}));
    end
end
scriptMATLAB = appendChar(scriptMATLAB,sprintf('\n'));

%% Main Execution Body
scriptMATLAB = appendChar(scriptMATLAB,sprintf('%% Main Execution\n'));
mainTasks = JobObj.Commands.Main;
if ~isempty(mainTasks)
    for i = 1:numel(mainTasks)
        scriptMATLAB = appendChar(scriptMATLAB,...
            sprintf('%s\n',mainTasks{i}));
    end
end
scriptMATLAB = appendChar(scriptMATLAB,sprintf('\n'));

%% Dump Data
scriptMATLAB = appendChar(scriptMATLAB,sprintf('%% Dumping Output Data\n'));
dumpData = JobObj.Commands.DumpData;
if ~isempty(dumpData)
    for i = 1:numel(dumpData)
        scriptMATLAB = appendChar(scriptMATLAB,...
            sprintf('%s\n',dumpData{i}));
    end
end
scriptMATLAB = appendChar(scriptMATLAB,sprintf('\n'));

%% Generate the Task within the Remote Script

% tasks = DispatcherObj.command;
% % if iscell(tasks)
% %     for i = 1:numel(tasks)
% %         fprintf(fOut, [tasks{i}, '\n']);
% %     end
% % end
%         
% if ~isempty(tasks)
%     if strcmp(tasks(end), ';')
%         taskSemicolon = '';
%     else
%         taskSemicolon = ';';
%     end
%     cmdLine = sprintf([tasks, taskSemicolon, '\n']);
%     scriptMATLAB = sprintf('%s%s', scriptMATLAB, cmdLine);
% end

%% Logging - Execution is Completed
scriptMATLAB = appendChar(scriptMATLAB,sprintf('%% Logging: Completed\n'));

scriptMATLAB = appendChar(scriptMATLAB,sprintf('if ~exist(''ME'')\n'));

% Create an empty file to indicate that the task has been finished
logFileCompleted = '[''.uqlab_process_'' cpuIdxStr ''_execution_completed'']';
scriptMATLAB = appendChar(scriptMATLAB,...
    sprintf('f = fopen(%s,''wt'');\nfclose(f);\n',logFileCompleted));

% Remove the file indicating that the execution is running
scriptMATLAB = appendChar(scriptMATLAB,sprintf('end\n'));
scriptMATLAB = appendChar(scriptMATLAB,...
    sprintf('delete(%s);\n',logFileRunning));

scriptMATLAB = appendChar(scriptMATLAB,sprintf('\n'));

%% Exit Remote MATLAB Instance
scriptMATLAB = appendChar(scriptMATLAB,sprintf('exit\n'));


%% Check and delete any existing remote script
%remoteScriptFullname = DispatcherObj.Internal.RemoteFiles.Matlab;
%if exist(remoteScriptFullname,'file')
%    delete(which(remoteScriptFullname))
%end

%% Open a File for Writing
%fOut = fopen(remoteScriptFullname, 'wt', 'n', 'UTF-8');

%% Open a try/catch Statement
% cmdLine = sprintf('try\n');
% scriptMATLAB = cmdLine;

%% Create and Remove Remote Polling Files (1/2)

%% Set the Total CPUs and Execution Index to the Dispatcher object
% totalCPUs = DispatcherObj.Internal.TotalCPUs;
% cmdLine = sprintf('UQ_dispatcher.Runtime.ncpu = %d;\n', totalCPUs);
% scriptMATLAB = sprintf('%s %s', scriptMATLAB, cmdLine);
% cmdLine = sprintf('UQ_dispatcher.Runtime.cpuID = ExIdx;\n');
% scriptMATLAB = sprintf('%s %s', scriptMATLAB, cmdLine);

%% Generate All Variables that Are Needed in the Remote Execution
% if isfield(DispatcherObj.Internal,'Data') && ...
%         isstruct(DispatcherObj.Internal.Data)
%     fNames = fieldnames(DispatcherObj.Internal.Data);
%     for i = 1:length(fNames)
%         cmdLine = sprintf('%s = UQ_dispatcher.Internal.Data.%s;\n',...
%             fNames{i}, fNames{i});
%         scriptMATLAB = sprintf('%s %s', scriptMATLAB, cmdLine);
%     end
% end



%% Save the Session
% resultTag = DispatcherObj.Internal.RemoteFiles.ResultTag;
% cmdLine = sprintf('uq_saveSession([''%s_'' ExIdxStr ''.mat'']);\n', resultTag);
% scriptMATLAB = sprintf('%s %s', scriptMATLAB, cmdLine);

%% Write down the Catch Block

% cmdLine = sprintf('catch me\n');
% scriptMATLAB = sprintf('%s %s', scriptMATLAB, cmdLine);
% 
% % Write the error message
% errMsgFile = '[''.uqlab_process_'' ExIdxStr ''_execution_error'']';
% addFileCommand = sprintf('f = fopen(%s,''wt'');\n',errMsgFile);
% cmdLine = sprintf(addFileCommand);
% scriptMATLAB = sprintf('%s %s', scriptMATLAB, cmdLine);
% cmdLine = sprintf('fprintf(f,me.message);\n');
% scriptMATLAB = sprintf('%s %s', scriptMATLAB, cmdLine);
% cmdLine = sprintf('fclose(f);\n');
% scriptMATLAB = sprintf('%s %s', scriptMATLAB, cmdLine);
% 
% % end of try/catch block
% cmdLine = sprintf('end\n');
% scriptMATLAB = sprintf('%s %s', scriptMATLAB, cmdLine);


end

function currentChar = appendChar(currentChar,newChar)

currentChar = sprintf('%s%s', currentChar, newChar);

end