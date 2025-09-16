function [status,results] = uq_Dispatcher_util_chmod(filename,options,varargin)
%UQ_DISPATCHER_UTIL_CHMOD modifies the access permission of a remote file.
%
%   UQ_DISPATCHER_UTIL_CHMOD(FILENAME,OPTIONS) modifies the access permis-
%   sion of FILENAME according to OPTIONS.
%
%   UQ_DISPATCHER_UTIL_CHMOD(..., NAME, VALUE) modifies the permission of 
%   FILENAME according to OPTIONS with additional NAME/VALUE argument 
%   pairs. The supported NAME/VALUE argument pairs are:
%
%       NAME            VALUE
%       'SSHConnect'    Command to establish a connection to a remote
%                       machine using an SSH protocol (char).
%                       Default: '' (empty)
%
%       'MaxNumTrials'  Maximum number of trials to establish an SSH
%                       connection if Timeout error is thrown (scalar
%                       double).
%                       Default: 5
%
%   [STATUS,RESULTS] = uq_Dispatcher_util_chmod(...) modifies the
%   permission of a file FILENAME according to OPTIONS and returns the exit
%   status of the command to STATUS as well as the output of the command to
%   RESULTS.
%   
%   See also UQ_DISPATCHER_UTIL_RUNCLICOMMAND.

%   NOTE
%   ----
%
%   - If 'SSHConnect' is empty, then the command 'chmod' is executed
%     locally.
%   - Empty 'SSHConnect' is only supported in Linux/Mac operating system.

%% Parse and verify the inputs

% SSH Connection
[sshConnect,varargin] = uq_parseNameVal(varargin, 'SSHConnect', '');

% Maximum number of trials
[maxNumTrials,varargin] = uq_parseNameVal(varargin, 'MaxNumTrials', 5);

if ~isempty(varargin)
    warning('There is unparsed varargin.')
end

%% Modifies the permission of a remote file

% Safeguard against possible whitespaces in 'filename'
filename = uq_Dispatcher_util_writePath(filename,'linux');

cmdName = 'chmod';
cmdArgs = {options, filename};

[status,results] = uq_Dispatcher_util_runCLICommand(...
        cmdName, cmdArgs, sshConnect, 'MaxNumTrials', maxNumTrials);

end
