function nowDateTime = uq_Dispatcher_util_getNowDateTime(sshConnect,maxNumTrials)
%UQ_DISPATCHER_UTIL_GETNOWDATETIME returns current date and time as char.

%% Parse and verify inputs
if nargin < 2
    maxNumTrials = 1;
end

%% Command specification
cmdName = 'date';             % Linux command
cmdArgs = {'+''%D %r'' -u'};  % 'dd/mm/yy HH:MM:SS PM' in UTC

%% Command execution
[~,nowDateTime] = uq_Dispatcher_util_runCLICommand(...
        cmdName, cmdArgs, sshConnect, 'MaxNumTrials', maxNumTrials);

%% Parse output
% Remove leading and trailing whitespaces
nowDateTime = uq_strip(nowDateTime);

% Possible additional outputs before 'date' command is executed
nowDateTime = regexp(nowDateTime, '\n', 'split');
nowDateTime = nowDateTime{end};  % Grab the last line ('date' output)

end
