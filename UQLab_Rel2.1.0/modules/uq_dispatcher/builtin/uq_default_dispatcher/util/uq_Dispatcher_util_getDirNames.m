function [status,dirNames] = uq_Dispatcher_util_getDirNames(...
    parentDir, sshConnect, maxNumTrials)
%UQ_DISPATCHER_UTIL_GETDIRNAMES gets all the directory names inside a
%   directory.

%% Parse and verify inputs
if nargin < 1
    if ispc
        parentDir = pwd;
    else
        parentDir = '.';
    end
end

if nargin < 2
    sshConnect = '';
end

if nargin < 3
    maxNumTrials = 5;
end

%% Create command
if ispc && isempty(sshConnect)
    % Safe guard against possible whitespaces in 'parentDir'
    parentDir = uq_Dispatcher_util_writePath(parentDir,'pc');
    cmdName = 'dir';
    cmdArgs = {parentDir, '/AD', '/B', '/ON'};
else
    % Safe guard against possible whitespaces in 'parentDir'
    parentDir = uq_Dispatcher_util_writePath(parentDir,'linux');
    cmdName = 'find';
    cmdArgs = {parentDir,...
        '-maxdepth 1',...         % Don't look for sub-directories
        '-mindepth 1',...         % Don't list the base directory
        '-type d',...             % Find only directory type
        '-exec basename {} \;'};  % Get only the base name
end

%% Submit command
[status,results] = uq_Dispatcher_util_runCLICommand(...
    cmdName, cmdArgs, sshConnect, 'MaxNumTrials', maxNumTrials);

%% Post-process the output
dirNames = strsplit(results,'\n');

% Remove empty lines
dirNames = dirNames(~cellfun(@isempty,dirNames));

if isrow(dirNames)
    dirNames = transpose(dirNames);
end

% Sort in alphabetical order (A -> Z)
dirNames = sort(dirNames);

end
