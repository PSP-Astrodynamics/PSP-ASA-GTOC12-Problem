function pass = uq_Dispatcher_init_checkRemoteMPI(DispatcherObj)
%UQ_DISPATCHER_INIT_CHECKREMOTEUTIL checks if MPI exists in the remote.
%
%   PASS = UQ_DISPATCHER_INIT_CHECKREMOTEMPI(DISPATCHEROBJ) checks if an
%   implementation of MPI exists on the remote machine as specified
%   by the DISPATCHER object DISPATCHEROBJ. The command 'mpirun' must be
%   callable from the PATH. In some remote machines, an MPI module must be
%   loaded first; this command is typically stored in 'EnvSetup' of the
%   remote machine configuration. If 'mpirun' can't be found, an error is
%   thrown.

%% Get local variables
displayOpt = DispatcherObj.Internal.Display;
maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;
sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);
envSetup = DispatcherObj.Internal.RemoteConfig.EnvSetup;

%% Check remote MATLAB
if displayOpt > 1
    msg = sprintf('[DISPATCHER] Check MPI (remote)');
    fprintf(uq_Dispatcher_util_dispMsg(msg))
end

pass = uq_Dispatcher_util_checkCommand('mpirun',...
    'SSHConnect', sshConnect,...
    'MaxNumTrials', maxNumTrials,...
    'EnvCommands', envSetup);

if ~pass
    if displayOpt > 1
        fprintf('(ERROR)\n')
    end
    error('MPI can''t be found.')
end
if displayOpt > 1
    fprintf('(OK)\n')
end

end
