function uq_Dispatcher_scripts_createProfile(outputFile,RemoteConfig)
%UQ_DISPATCHER_SCRIPTS_CREATEPROFILE creates a DISPATCHER profile file.

%%
[~,profileName,~] = fileparts(outputFile);

%% Prepare
Descriptions.SavedSession = 'Name of the session saved with PuTTY';
Descriptions.Username = 'Username used to log into the remote machine';
Descriptions.Hostname = 'Hostname of the remote machine';
Descriptions.PrivateKey = 'SSH private key';
Descriptions.Scheduler = 'Job scheduler used in the remote machine and its settings';
Descriptions.RemoteFolder = sprintf([...
    'Directory in the remote machine in which files for remote execution\n',...
    '%% is located (must have write access and don''t use tilde notation ',...
    'for $HOME)']);
Descriptions.MATLABCommand = 'Command that runs MATLAB in the remote machine';
Descriptions.MATLABSingleThread = 'Flag that sets (remote) MATLAB to run in single thread';
Descriptions.MATLABOptions = 'Options to provide MATLAB on startup (e.g., disable graphic)';
Descriptions.RemoteUQLabPath = 'Location of UQLab in the remote machine';
Descriptions.EnvSetup = sprintf([...
    'Commands to execute in the shell before submission, used for\n',...
    '%% setting up the environment of the *login node* (e.g., for loading MPI)']);
Descriptions.PrevCommands = sprintf([...
    'Commands to execute in the shell before starting, used for\n',...
    '%% setting up the environment of all the *compute nodes*\n',...
    '%% (e.g., for loading specific version of MATLAB)']);
Descriptions.MPI = 'MPI implementation used in the remote machine and associated settings';
Descriptions.Shebang = 'Shell interpreter in the remote machine';

%% Open the file
fid = fopen(outputFile,'w');

%% Header
fprintf(fid, '%%%% Profile file: %s\n', profileName);
fprintf(fid, '%%\n');
fprintf(fid, '%% This is a remote machine profile file for DISPATCHER unit.\n');
fprintf(fid, '\n');

%% Authentication information
% SavedSession, Username/Hostname, Username/Hostname/PrivateKey
printHeader(fid,'Authentication info.')
printConfigVar(fid, 'Username', RemoteConfig, Descriptions);
printConfigVar(fid, 'Hostname', RemoteConfig, Descriptions);
printConfigVar(fid, 'PrivateKey', RemoteConfig, Descriptions);
printConfigVar(fid, 'SavedSession', RemoteConfig, Descriptions);

fprintf(fid,'\n');

%% Scheduler settings
% SchedulerVars
printHeader(fid,'Scheduler settings')
printConfigVar(fid, 'Scheduler', RemoteConfig, Descriptions);
if isfield(RemoteConfig,'SchedulerVars')
    subfnames = fieldnames(RemoteConfig.SchedulerVars);
    for i = 1:numel(subfnames)
        printSubConfigVar(fid, 'SchedulerVars', subfnames{i}, RemoteConfig);
    end
end

fprintf(fid,'\n');

%% Remote folder
% RemoteFolder
printHeader(fid,'Remote folder/directory')
printConfigVar(fid, 'RemoteFolder', RemoteConfig, Descriptions);

fprintf(fid,'\n');

%% MATLAB
% MATLABCommand, MATLABSingleThread, MATLABOptions
printHeader(fid,'MATLAB')
printConfigVar(fid, 'MATLABCommand', RemoteConfig, Descriptions);
printConfigVar(fid, 'MATLABSingleThread', RemoteConfig, Descriptions);
printConfigVar(fid, 'MATLABOptions', RemoteConfig, Descriptions);

fprintf(fid,'\n');

%% UQLab
% RemoteUQLabPath
printHeader(fid,'UQLab')
printConfigVar(fid, 'RemoteUQLabPath', RemoteConfig, Descriptions);

fprintf(fid,'\n');

%% EnvSetup
% EnvSetup
printHeader(fid,'EnvSetup')
printConfigVar(fid, 'EnvSetup', RemoteConfig, Descriptions);

fprintf(fid,'\n');

%% PrevCommands
% PrevCommand
printHeader(fid,'PrevCommands')
printConfigVar(fid, 'PrevCommands', RemoteConfig, Descriptions);

fprintf(fid,'\n');

%% MPI
% MPI
printHeader(fid,'MPI implementation')
if isfield(RemoteConfig,'MPI')
    subfnames = fieldnames(RemoteConfig.MPI);
    for i = 1:numel(subfnames)
        printSubConfigVar(fid, 'MPI', subfnames{i}, RemoteConfig);
    end
end

fprintf(fid,'\n');

%% Shebang
% Shebang
printHeader(fid,'Shebang')
printConfigVar(fid, 'Shebang', RemoteConfig, Descriptions);

%% Close the file
fclose(fid);

end


%% ------------------------------------------------------------------------
function printHeader(fid,header)
% prints the header section of the profile file.

fprintf(fid, '%%%% %s\n',header);
fprintf(fid, '%%\n');

end


%% ------------------------------------------------------------------------
function printConfigVar(fid, varName, RemoteConfig, Description)
% prints a given variable from remote configuration struct.

if isfield(RemoteConfig,varName)
    fprintf(fid, '%% %s:\n', Description.(varName));
    fprintf(fid, '%s = %s;\n', varName, printVal(RemoteConfig.(varName)));
end

end


%% ------------------------------------------------------------------------
function printSubConfigVar(fid, varName1, varName2, RemoteConfig)
% prints a given subfield from remote configuration struct.

if isfield(RemoteConfig.(varName1),varName2)
    fprintf(fid, '%s.%s = %s;\n',...
        varName1, varName2, printVal(RemoteConfig.(varName1).(varName2)));
end

end


%% ------------------------------------------------------------------------
function charVal = printVal(val)
% prints a value of from remote configuration struct value as char.

if iscell(val)
    if isempty(val)
        charVal = '{}';
    else
        charVal = ['{' sprintf('''%s'';...\n', val{:}), '}'];
    end
elseif islogical(val)
    logicalVal = {'false','true'};
    charVal = logicalVal{val+1};
else
    charVal = sprintf('''%s''', val);
end

end