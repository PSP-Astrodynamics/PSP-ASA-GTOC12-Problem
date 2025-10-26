function [status,results] = uq_Dispatcher_util_cat(file,sshConnect,maxNumTrials)
%UQ_DISPATCHER_UTIL_CAT returns the content of a file.

%% Parse and verify inputs

if nargin < 2
    sshConnect = '';
end

if nargin < 3
    maxNumTrials = 1;
end

%% Create command
if ispc && isempty(sshConnect)
    cmdName = 'type';
    % Safe guard against possible whitespaces in the file
    file = uq_Dispatcher_util_writePath(file,'pc');
else
    cmdName = 'cat';
    % Safe guard against possible whitespaces in the file
    file = uq_Dispatcher_util_writePath(file,'linux');
end

cmdArgs = {file};

[status,results] = uq_Dispatcher_util_runCLICommand(...
    cmdName, cmdArgs, sshConnect, 'MaxNumTrials', maxNumTrials);

end
