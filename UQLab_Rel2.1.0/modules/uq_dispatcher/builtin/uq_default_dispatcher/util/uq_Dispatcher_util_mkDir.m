function [status,results] = uq_Dispatcher_util_mkDir(dirName,varargin)
%UQ_DISPATCHER_UTIL_MKDIR creates a directory.

%% Parse and verify inputs

% SSH Connection
[sshConnect,varargin] = uq_parseNameVal(varargin, 'SSHConnect', '');

% Maximum number of trials
[maxNumTrials,varargin] = uq_parseNameVal(varargin, 'MaxNumTrials', 1);

% Options
if isempty(sshConnect) && ispc
    optionsDefault = '';
else
    optionsDefault = '-p';
end
[options,varargin] = uq_parseNameVal(varargin, 'Options', optionsDefault);

if ~isempty(varargin)
    warning('There is unparsed varargin.')
end

%% Create the remote directory

cmdName = 'mkdir';

if isempty(sshConnect) && ispc
    dirName = uq_Dispatcher_util_writePath(dirName,'pc');
else
    dirName = uq_Dispatcher_util_writePath(dirName,'linux');
end
cmdArgs = {options, dirName};
        
[status,results] = uq_Dispatcher_util_runCLICommand(...
    cmdName, cmdArgs, sshConnect, 'MaxNumTrials', maxNumTrials);

end
