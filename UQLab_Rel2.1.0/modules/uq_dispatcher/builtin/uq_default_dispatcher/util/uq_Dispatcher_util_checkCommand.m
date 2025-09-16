function cmdExists = uq_Dispatcher_util_checkCommand(cmd,varargin)
%UQ_DISPATCHER_UTIL_CHECKCOMMAND checks if a given command is callable from
%   the PATH.
%
%   This function wraps UQ_DISPATCHER_UTIL_RUNCLICMD to check if a given
%   command is callable from the path.

%% Parse and verify inputs

% SSH Connection
[sshConnect,varargin] = uq_parseNameVal(varargin, 'SSHConnect', '');

% Maximum number of trials
[maxNumTrials,varargin] = uq_parseNameVal(varargin, 'MaxNumTrials', 1);

% EnvCommands
[envCommands,varargin] = uq_parseNameVal(varargin, 'EnvCommands', '');

if ~isempty(varargin)
    warning('There is unparsed varargin.')
end

%%

if ispc && isempty(sshConnect)
    cmdName = 'WHERE';
    [dirPart,cmdPart,extPart] = fileparts(cmd);
    if ~isempty(dirPart)
        cmdArgs = {sprintf('%s:%s%s',...
            uq_Dispatcher_util_writePath(dirPart,'pc'),...
            cmdPart, extPart)};
    else
        cmdArgs = {cmd};
    end
else
    if isempty(envCommands) || all(cellfun(@isempty,envCommands))
        cmdName = 'command';
        cmdArgs = {'-v', uq_Dispatcher_util_writePath(cmd,'linux')};
    else
        cmdName = [envCommands 'command'];
        [cmdArgs{1:numel(envCommands)}] = deal('');
        cmdArgs = {cmdArgs,...
            {'-v', uq_Dispatcher_util_writePath(cmd,'linux')}};
    end
end

try
    uq_Dispatcher_util_runCLICommand(...
        cmdName, cmdArgs, sshConnect, 'MaxNumTrials', maxNumTrials);
    cmdExists = true;
catch
    cmdExists = false;
end

end
