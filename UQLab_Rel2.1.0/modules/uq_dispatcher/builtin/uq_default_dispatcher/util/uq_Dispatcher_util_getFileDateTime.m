function timestamp = uq_Dispatcher_util_getFileDateTime(fullname,sshConnect,maxNumTrials)
%UQ_DISPATCHER_UTIL_GETFILEDATETIME gets the timestamp (last modified)
%   of a file in UTC format.
%

% NOTE: datenum is used to do the conversion from the string return
% by the 'date' utility to be compatible with MATLAB R2014a. Note that
% 'datetime' class is only available in R2014b.

%% Parse and verify inputs
if nargin < 3
    maxNumTrials = 1;
end

%% Return the timestamp of a local file
if nargin == 1
    % Get the date of local file
    lst = dir(fullname);
    if isempty(lst)
        error('File not found.')
    end
    timestamp = datestr(lst.datenum,'mm/dd/yyHH:MM:SS PM (UTC)');
    return
end

%% Create the command to get the timestamp of a remote command

% Safe guard against possible white spaces in 'fullname'
fullname = uq_Dispatcher_util_writePath(fullname, 'linux');

cmdName = 'date';
cmdArgs = {'+''%D %r'' -u',... % 'dd/mm/yy HH:MM:SS PM' in UTC standard
    '-r', fullname};           % the last modification on a file

%% Execute the command
[~,timestamp] = uq_Dispatcher_util_runCLICommand(...
        cmdName, cmdArgs, sshConnect, 'MaxNumTrials', maxNumTrials);

%% Parse the output
timestamp = uq_strip(timestamp);

% Possible additional outputs before 'date' command is executed
timestamp = regexp(timestamp, '\n', 'split');
timestamp = uq_strip(timestamp{end});  % Grab the last line ('date' output)

end
