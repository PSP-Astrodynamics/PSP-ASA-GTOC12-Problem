function pass = uq_Dispatcher_init_checkRemoteUtil(cmdName,DispatcherObj)
%UQ_DISPATCHER_INIT_CHECKREMOTEUTIL checks whether a given utility exists
%   on the remote machine.
%
%   PASS = UQ_DISPATCHER_INIT_CHECKREMOTEUTIL(CMDNAME,DISPATCHEROBJ) checks
%   if a utility CMDNAME exists on the remote machine using the DISPATCHER
%   object DISPATCHEROBJ. If the utility is not available, an error is
%   thrown.

%% Get local variables
displayOpt = DispatcherObj.Internal.Display;
maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;
sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);

%% Check remote utility
if displayOpt > 1
    msg = sprintf('[DISPATCHER] Check required (remote) tool: *%s*',...
        cmdName);
    fprintf(uq_Dispatcher_util_dispMsg(msg))
end

pass = uq_Dispatcher_util_checkCommand(cmdName,...
    'SSHConnect', sshConnect,...
    'MaxNumTrials', maxNumTrials);

if ~pass
    if displayOpt > 1
        fprintf('(ERROR)\n')
    end
    error('*%s* can''t be found. Make sure it is in the correct path.',...
        cmdName)
end
if displayOpt > 1
    fprintf('(OK)\n')
end

end
