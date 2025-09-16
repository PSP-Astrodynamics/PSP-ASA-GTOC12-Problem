function pass = uq_Dispatcher_init_checkRemoteWriteAccess(dirName,DispatcherObj)
%UQ_DISPATCHER_INIT_CHECKREMOTEWRITEACCESS checks if the user has a write
%   access to a directory on the remote machine.
%
%   PASS = UQ_DISPATCHER_INIT_CHECKREMOTEWRITEACCESS(DIRNAME,DISPATCHEROBJ)
%   checks if the user has a write access to a directory DIRNAME on the
%   remote machine using the DISPATCHER object DISPATCHEROBJ.

%% Get local variables
displayOpt = DispatcherObj.Internal.Display;
maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;
sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);

%% Check write access to the remore directory
if displayOpt > 1
    msg = sprintf('[DISPATCHER] Check write access (remote): "%s"',dirName);
    fprintf(uq_Dispatcher_util_dispMsg(msg))
end

pass = uq_Dispatcher_util_checkWriteAccess(...
    dirName, sshConnect, maxNumTrials);

if ~pass
    if displayOpt > 1
        fprintf('(ERROR)\n')
    end
    error('User has no write access to *%s*.',dirName)
end
if displayOpt > 1
    fprintf('(OK)\n')
end

end
