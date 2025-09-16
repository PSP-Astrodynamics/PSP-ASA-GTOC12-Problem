function dirExists = uq_Dispatcher_util_checkDir(...
    dirnames, sshConnect, maxNumTrials)
%UQ_DISPATCHER_UTIL_CHECKDIR checks if directories exist in the remote.

%% Parse and verify inputs
if nargin < 3
    maxNumTrials = 1;
end

%% Check remote directories

cmdName = 'test';
if ~iscell(dirnames)
    dirnames = {dirnames};
end

dirExists = false(numel(dirnames),1);

for i = 1:numel(dirnames)
    dirName = uq_Dispatcher_util_writePath(dirnames{i},'linux');
    cmdArgs = {'-d', dirName};
    try
        uq_Dispatcher_util_runCLICommand(cmdName, cmdArgs, sshConnect,...
            'MaxNumTrials', maxNumTrials);
        dirExists(i) = true;
    catch
        dirExists(i) = false;
        continue
    end
end

end
