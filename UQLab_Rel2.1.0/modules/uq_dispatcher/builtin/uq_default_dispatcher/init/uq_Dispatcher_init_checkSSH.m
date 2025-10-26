function pass = uq_Dispatcher_init_checkSSH(DispatcherObj)
%UQ_DISPATCHER_INIT_CHECKSSH checks if a passwordless SSH connection to a 
%   remote machine can be made using the DISPATCHER object.

%% Get local variables
RemoteConfig = DispatcherObj.Internal.RemoteConfig;
SSHClient = DispatcherObj.Internal.SSHClient;
displayOpt = DispatcherObj.Internal.Display;

%% Check if passwordless SSH connection can be established

if displayOpt > 1
    msg = '[DISPATCHER] Attempt passwordless SSH connection';
    fprintf(uq_Dispatcher_util_dispMsg(msg))
end

if ~isempty(RemoteConfig.SavedSession)
    sshConnect = sprintf('%s %s %s',...
        SSHClient.SecureConnect,...
        SSHClient.SecureConnectArgs,...
        RemoteConfig.SavedSession);
else
    if ~isempty(RemoteConfig.PrivateKey)
        % Safe guard against possible whitespaces in 'PrivateKey'
        % Windows and Linux differ in escaping the whitespaces
        if ispc
            privateKey = uq_Dispatcher_util_writePath(...
                RemoteConfig.PrivateKey, 'pc');
        else
            privateKey = uq_Dispatcher_util_writePath(...
                RemoteConfig.PrivateKey, 'linux');
        end
        sshConnect = sprintf('%s %s -i %s %s@%s',...
            SSHClient.SecureConnect, SSHClient.SecureConnectArgs,...
            privateKey,...
            RemoteConfig.Username,...
            RemoteConfig.Hostname);
    else
        sshConnect = sprintf('%s %s %s@%s',...
            SSHClient.SecureConnect, SSHClient.SecureConnectArgs,...
            RemoteConfig.Username,...
            RemoteConfig.Hostname);
    end
end

pass = uq_Dispatcher_util_checkSSH(sshConnect,...
    SSHClient.MaxNumTrials);

if ~pass 
    if displayOpt > 1
        fprintf('(ERROR)\n')
    end

    if ~isempty(RemoteConfig.SavedSession)
        error('SavedSession *%s*\ncan''t be used to connect to the remote machine.',...
            RemoteConfig.SavedSession)
    end
    
    if ~isempty(RemoteConfig.PrivateKey)
        error(...
            'PrivateKey *%s*\ncan''t be used to connect to the remote machine.',...
            RemoteConfig.PrivateKey)
    else
        error(['Passwordless SSH connection can''t be established. ',...
            'Use uq_setUpSSHKey() to set up a private key.'])
    end 
end

if displayOpt > 1
    fprintf('(OK)\n')
end

end
