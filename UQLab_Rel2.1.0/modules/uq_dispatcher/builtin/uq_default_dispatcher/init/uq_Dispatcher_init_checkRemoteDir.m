function pass = uq_Dispatcher_init_checkRemoteDir(dirName,DispatcherObj)
%UQ_DISPATCHER_INIT_CHECKREMOTEDIR checks if a directory exists on the
%   remote machine.
%
%   PASS = UQ_DISPATCHER_INIT_CHECKREMOTEDIR(DIRNAME,DISPATCHEROBJ) checks
%   a directory DIRNAME exists on the remote machine using the DISPATCHER
%   object DISPATCHEROBJ. If the directory does not exist, it will be
%   created. If the creation fails, an error is thrown.

%% Get local variables
displayOpt = DispatcherObj.Internal.Display;
maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;
sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);

%% Check if remote directory exists
if displayOpt > 1
    msg = sprintf('[DISPATCHER] Check directory (remote): "%s"',dirName);
    fprintf(uq_Dispatcher_util_dispMsg(msg))
end

dirExists = uq_Dispatcher_util_checkDir(dirName, sshConnect, maxNumTrials);

if dirExists
    if displayOpt > 1
        fprintf('(OK)\n')
    end
    pass = true;
else
    if displayOpt > 1
        fprintf('(ERROR)\n')
    end
end

%% Create a remote directory if it does not exist
if ~dirExists
    if displayOpt > 1
        msg = sprintf('[DISPATCHER] Create directory (remote): "%s"',dirName);
        fprintf(uq_Dispatcher_util_dispMsg(msg))
    end
    
    try
        pass = uq_Dispatcher_util_mkDir(dirName,...
            'SSHConnect', sshConnect,...
            'MaxNumTrials', maxNumTrials);
        if displayOpt > 1
           fprintf('(OK)\n')
        end
    catch e
       if displayOpt > 1
           fprintf('(ERROR)\n')
       end
       rethrow(e)
   end

end

end
