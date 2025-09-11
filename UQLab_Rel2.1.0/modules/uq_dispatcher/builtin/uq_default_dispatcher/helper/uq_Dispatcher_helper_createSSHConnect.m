function sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj)
%UQ_DISPATCHER_HELPER_CREATESSHCONNECT creates a command to connect to
%   the remote machine via SSH.

%% Parse and and Verify Inputs

% Verify the type of input argument
if ~isa(DispatcherObj,'uq_dispatcher')
    error('Input argument must be of *uq_dispatcher* type!')
end

% Get additional SSH arguments from DISPATCHER unit
sshArgs = DispatcherObj.Internal.SSHClient.SecureConnectArgs;
if iscell(sshArgs)
    sshArgs = strjoin(sshArgs);
end

%% Passwordless SSH connection with identity file (if applies)
privateKey = DispatcherObj.Internal.RemoteConfig.PrivateKey;
isPrivateKeyDefined =  ~isempty(privateKey);

if isPrivateKeyDefined
    % Safe guard against possible whitespaces in 'privateKey'
    % (linux/Windows differ)
    if ispc
        privateKey = uq_Dispatcher_util_writePath(...
            privateKey, 'pc');
    else
        privateKey = uq_Dispatcher_util_writePath(...
            privateKey, 'linux');
    end
    sshArgs = strjoin({sshArgs, sprintf('-i %s',privateKey)});
end

%% Create an SSH Connection Command String
% Create a command to make an SSH connection to the remote machine

% Session Name
sessionName = uq_Dispatcher_helper_getSessionName(DispatcherObj);

% App to establish the SSH connection
sshSecureConnect = DispatcherObj.Internal.SSHClient.SecureConnect;
sshClientLocation = DispatcherObj.Internal.SSHClient.Location;
if ~isempty(sshClientLocation)
    sshSecureConnect = fullfile(sshClientLocation,sshSecureConnect);
    if ispc
        sshSecureConnect = uq_Dispatcher_util_writePath(...
            sshSecureConnect,'pc');
    else
        sshSecureConnect = uq_Dispatcher_util_writePath(...
            sshSecureConnect,'linux');
    end
end
sshConnect = sprintf('%s %s %s', sshSecureConnect, sshArgs, sessionName);

end
