function [status,results] = uq_Dispatcher_util_runCLICommand(...
    cmdName, cmdArgs, sshConnect, varargin)
%UQ_DISPATCHER_UTIL_RUNCLICOMMAND executes CLI command in the remote
%   machine sent via SSH.

%% Parse and Verify Inputs
if ~iscell(cmdName)
    cmdName = {cmdName};
    cmdArgs = {cmdArgs};
end

% Maximum number of trials
[maxNumTrials,varargin] = uq_parseNameVal(varargin, 'MaxNumTrials', 5);

% Chain operator
[chainOperator,varargin] = uq_parseNameVal(varargin, 'ChainOperator', ';');

if ~isempty(varargin)
    warning('There is unparsed varargin.')
end

%% Command Creation
cliCmd = [cmdName{1} ' ' strjoin(cmdArgs{1}, ' ')];
for i = 2:numel(cmdName)
    cliCmd = [cliCmd chainOperator cmdName{i} ' ' strjoin(cmdArgs{i}, ' ')];
end

if nargin > 2 && ~isempty(sshConnect)
    cliCmd = sprintf('%s "%s"', sshConnect, cliCmd);
end

%% Command Execution
errorCount = 0;
while errorCount < maxNumTrials

    [status,results] = system(cliCmd);
    if status ~= 0
        expr = 'connection timed out';
        if ~isempty(regexpi(uq_strip(results),expr,'once'))
            errorCount = errorCount + 1;
            warning('Connection timed out, retrying (%d/%d)...',...
                errorCount, maxNumTrials)
            continue
        else
            error(results)
        end
    end
    break
end

%     if strcmp(me.message,'FATAL ERROR: Network error: Connection timed out')

%% Throw Error if Exit Status is Non-Zero
if status
    error('Error with ''%s'':\n%s', cmdName{1}, results)
end

end
