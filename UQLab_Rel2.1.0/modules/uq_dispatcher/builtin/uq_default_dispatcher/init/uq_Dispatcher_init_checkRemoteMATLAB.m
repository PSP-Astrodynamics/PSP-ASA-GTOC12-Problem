function pass = uq_Dispatcher_init_checkRemoteMATLAB(DispatcherObj)
%UQ_DISPATCHER_INIT_CHECKREMOTEUTIL checks if MATLAB exists on the remote
%   machine.
%
%   PASS = UQ_DISPATCHER_CHECKREMOTEMATLAB(DISPATCHEROBJ) checks if MATLAB
%   exists on the remote machine. In some remote machines, a MATLAB module
%   must be loaded first; the command is typically stored in 'PrevCommands'
%   of the remote machine configuration. If MATLAB can't be found, an error
%   is thrown.

%% Get local variables
displayOpt = DispatcherObj.Internal.Display;
maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;
sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);
prevCommands = DispatcherObj.Internal.RemoteConfig.PrevCommands;
matlabCommand = DispatcherObj.Internal.RemoteConfig.MATLABCommand;

%% Check remote MATLAB
if displayOpt > 1
    msg = sprintf('[DISPATCHER] Check MATLAB (remote)');
    fprintf(uq_Dispatcher_util_dispMsg(msg))
end

pass = uq_Dispatcher_util_checkCommand(matlabCommand,...
    'SSHConnect', sshConnect,...
    'MaxNumTrials', maxNumTrials,...
    'EnvCommands', prevCommands);

if ~pass
    if displayOpt > 1
        fprintf('(ERROR)\n')
    end
    error('MATLAB can''t be found. Make sure it is in the correct path.')
end
if displayOpt > 1
    fprintf('(OK)\n')
end

end
