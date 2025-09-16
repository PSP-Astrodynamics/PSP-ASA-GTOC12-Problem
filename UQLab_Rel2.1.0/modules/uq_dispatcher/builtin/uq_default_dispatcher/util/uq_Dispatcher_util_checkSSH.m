function pass = uq_Dispatcher_util_checkSSH(sshConnect,maxNumTrials)
%UQ_DISPATCHER_UTIL_CHECKSSH checks if a passwordless SSH connection can be 
%   established to a remote machine.

%%
if nargin < 2
    maxNumTrials = 5;
end

%%
cmdName = 'exit';
cmdArgs = {'0'};

if ispc
    sshConnect = sprintf('ECHO %s | %s', uq_createUniqueID, sshConnect);
else
    sshConnect = sprintf(...
        '%s -o PasswordAuthentication=no -q -o "BatchMode=yes" -o "ConnectTimeout=60"',...
        sshConnect);
end

try
    [~,cmdout] = uq_Dispatcher_util_runCLICommand(...
        cmdName, cmdArgs, sshConnect, 'MaxNumTrials', maxNumTrials);
    if ~isempty(cmdout)
        error('%s',cmdout)
    end
    pass = true;
catch
    pass = false;
end

end
