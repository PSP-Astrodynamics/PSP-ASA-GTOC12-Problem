function uq_Dispatcher_checkRequirements(DispatcherObj)
%UQ_DISPATCHER_CHECKREQUIREMENTS checks all the requirements to dispatch a
%   computation using the DISPATCHER object DISPATCHEROBJ.

%% Check SSH Client (SSH/PLINK)
SSHClient = DispatcherObj.Internal.SSHClient;
if ~isempty(SSHClient.Location)
    cmdName = fullfile(SSHClient.Location,SSHClient.SecureConnect);
else
    cmdName = SSHClient.SecureConnect;
end

uq_Dispatcher_init_checkLocalUtil(cmdName,DispatcherObj);

%% Check SSH Client (SCP/PSCP)
if ~isempty(SSHClient.Location)
    cmdName = fullfile(SSHClient.Location,SSHClient.SecureCopy);
else
    cmdName = SSHClient.SecureCopy;
end

uq_Dispatcher_init_checkLocalUtil(cmdName,DispatcherObj);

%% Check passwordless SSH connection
uq_Dispatcher_init_checkSSH(DispatcherObj);

%% Check existence of local staging location
dirName = DispatcherObj.LocalStagingLocation;
uq_Dispatcher_init_checkLocalDir(dirName,DispatcherObj);

%% Check write access to local staging location
uq_Dispatcher_init_checkLocalWriteAccess(dirName,DispatcherObj);

%% Check existence of the remote folder
dirName = DispatcherObj.Internal.RemoteConfig.RemoteFolder;
uq_Dispatcher_init_checkRemoteDir(dirName,DispatcherObj);

%% Check write access to remote folder
uq_Dispatcher_init_checkRemoteWriteAccess(dirName,DispatcherObj);

%% Check MPI on the remote
uq_Dispatcher_init_checkRemoteMPI(DispatcherObj);

%% Check MATLAB command on the remote
if ~isempty(DispatcherObj.Internal.RemoteConfig.MATLABCommand)
    uq_Dispatcher_init_checkRemoteMATLAB(DispatcherObj);
end

%% Check UQLab on the remote
if ~isempty(DispatcherObj.Internal.RemoteConfig.RemoteUQLabPath)
    uq_Dispatcher_init_checkRemoteUQLab(DispatcherObj);
end

%% Check AddToPath
if ~isempty(DispatcherObj.AddToPath)
    addToPath = DispatcherObj.AddToPath;
    if ~iscell(addToPath)
        addToPath = {addToPath};
    end
    if DispatcherObj.Internal.Display > 1
        fprintf('[DISPATCHER] Check directories in *AddToPath*\n')
    end
    for i = 1:numel(addToPath)
        uq_Dispatcher_init_checkRemoteDir(addToPath{i},DispatcherObj);
    end
end

%% Check AddTreeToPath
if ~isempty(DispatcherObj.AddTreeToPath)
    addTreeToPath = DispatcherObj.AddTreeToPath;
    if ~iscell(addTreeToPath)
        addTreeToPath = {addTreeToPath};
    end
    if DispatcherObj.Internal.Display > 1
        fprintf('[DISPATCHER] Check directories in *AddTreeToPath*\n')
    end
    for i = 1:numel(addTreeToPath)
        uq_Dispatcher_init_checkRemoteDir(addTreeToPath{i},DispatcherObj);
    end
end

%% Check scheduler command
if ~strcmpi(DispatcherObj.Internal.RemoteConfig.Scheduler,'none')
    if DispatcherObj.Internal.Display > 1
        fprintf('[DISPATCHER] Check scheduler tools\n')
    end
    SchedulerVars = DispatcherObj.Internal.RemoteConfig.SchedulerVars;
    
    % Job submission command
    cmdName = SchedulerVars.SubmitCommand;
    uq_Dispatcher_init_checkRemoteUtil(cmdName,DispatcherObj);
    
    % Job cancel command
    cmdName = SchedulerVars.CancelCommand;
    uq_Dispatcher_init_checkRemoteUtil(cmdName,DispatcherObj);

end

%% Check remote utilities (they all must be in PATH)
if DispatcherObj.Internal.Display > 1
    fprintf('[DISPATCHER] Check remote tools\n')
end

% 'command'
cmdName = 'command';
uq_Dispatcher_init_checkRemoteUtil(cmdName,DispatcherObj);

% 'cat'
cmdName = 'cat';
uq_Dispatcher_init_checkRemoteUtil(cmdName,DispatcherObj);

% 'test'
cmdName = 'test';
uq_Dispatcher_init_checkRemoteUtil(cmdName,DispatcherObj);

% 'chmod'
cmdName = 'chmod';
uq_Dispatcher_init_checkRemoteUtil(cmdName,DispatcherObj);

% 'du'
cmdName = 'du';
uq_Dispatcher_init_checkRemoteUtil(cmdName,DispatcherObj);

% 'cut'
cmdName = 'cut';
uq_Dispatcher_init_checkRemoteUtil(cmdName,DispatcherObj);

% 'date'
cmdName = 'date';
uq_Dispatcher_init_checkRemoteUtil(cmdName,DispatcherObj);

% 'sed'
cmdName = 'sed';
uq_Dispatcher_init_checkRemoteUtil(cmdName,DispatcherObj);

% 'printf'
cmdName = 'printf';
uq_Dispatcher_init_checkRemoteUtil(cmdName,DispatcherObj);

end
