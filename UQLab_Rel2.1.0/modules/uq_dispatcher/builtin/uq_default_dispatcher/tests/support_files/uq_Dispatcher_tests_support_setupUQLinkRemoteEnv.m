function pass = uq_Dispatcher_tests_support_setupUQLinkRemoteEnv(...
    DispatcherObj, execFile, srcDir)

% Get command to send remote command
sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);

% Get the remote separator
remoteSep = DispatcherObj.Internal.RemoteSep;

% Create a remote folder
uq_Dispatcher_util_mkDir(srcDir, 'SSHConnect', sshConnect);

try
    % Send the executable to the remote folder
    uq_Dispatcher_helper_copy(DispatcherObj, execFile, srcDir);
    
    % Change the execution right
    [~,rmtExecFilename,rmtExecFileExt] = fileparts(execFile); 
    execFileName = [srcDir, remoteSep, rmtExecFilename, rmtExecFileExt];
    uq_Dispatcher_util_chmod(execFileName, 'u+x', 'SSHConnect', sshConnect);

    % Update the newline character (make sure its UNIX compliant)
    uq_Dispatcher_util_runCLICommand(...
        'sed', {'-i.bak', '''s/\r$//''', execFileName}, sshConnect);
catch e
    uq_Dispatcher_util_runCLICommand('rm', {'-rf', srcDir}, sshConnect);
    rethrow(e)
end

pass = true;

end
