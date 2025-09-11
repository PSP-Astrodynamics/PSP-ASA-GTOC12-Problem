function pass = uq_Dispatcher_init_checkRemoteUQLab(DispatcherObj)
%UQ_DISPATCHER_INIT_CHECKREMOTEUTIL checks if UQLab exists on the remote
%   machine.
%
%   PASS = UQ_DISPATCHER_INIT_CHECKREMOTEUQLAB(DISPATCHEROBJ) checks if
%   UQLab and its license exist on the remote machine as specified in the
%   DISPATCHER object DISPATCHEROBJ. If UQLab or its license are not
%   available, an error is thrown.

%% Get local variables
displayOpt = DispatcherObj.Internal.Display;
maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;
sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);

%% Check remote UQLab
if displayOpt > 1
    msg = sprintf('[DISPATCHER] Check UQLab (remote)');
    fprintf(uq_Dispatcher_util_dispMsg(msg))
end

dirName = DispatcherObj.Internal.RemoteConfig.RemoteUQLabPath;
pass = uq_Dispatcher_util_checkDir(dirName, sshConnect, maxNumTrials);

if ~pass
    if displayOpt > 1
        fprintf('(ERROR)\n')
    end
    error('UQLab can''t be found. Make sure it is in the correct path.')
end
if displayOpt > 1
    fprintf('(OK)\n')
end


end
