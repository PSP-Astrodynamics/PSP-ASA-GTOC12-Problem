function sessionName = uq_Dispatcher_helper_getSessionName(DispatcherObj)
%UQ_DISPATCHER_UTIL_GETSESSIONNAME gets the session name to connect to the 
%   remote machine from a DISPATCHER object.

if strcmpi(DispatcherObj.Internal.SSHClient.Name,'PuTTY') && ...
        isempty(DispatcherObj.Internal.RemoteConfig.PrivateKey)
    % PuTTY saved session is used
    sessionName = DispatcherObj.Internal.RemoteConfig.SavedSession;
else
    % username@hostname
    username = DispatcherObj.Internal.RemoteConfig.Username;
    hostname = DispatcherObj.Internal.RemoteConfig.Hostname;
    sessionName = [username '@' hostname];
end

end
