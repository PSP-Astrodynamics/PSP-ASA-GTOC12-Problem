function success = uq_UQLink_util_execCommand(command, showEcho, msg)
%UQ_UQLINK_UTIL_EXECCOMMAND runs system command w/ graceful error handling.
%
%   Any exception simply throws a warning.
%
%   Inputs
%   ------
%   - command: command to execute, char
%   - msg: warning message to display, char
%       Warning message is displayed in case of non-zero exit status *or*
%       exception is catched.
%   - showEcho: flag to display the command output, logical
%
%   Output
%   ------
%   - success: flag that indicates successful execution of command, logical
%
%   Examples
%   --------
%       uq_UQLink_util_execCommand('ls')
%           % In Unix, display the list of directories
%
%       uq_UQLink_util_execCommand(num2str(rand()), true, 'Oh noo!')
%           % /bin/bash: 0.54688: command not found
%           % Warning: Oh noo! 
%           % > In uq_UQLink_util_execCommand (line 46) 

%% Verify inputs
if nargin < 2
    showEcho = false;
end

if nargin < 3
    msg = '';
end

%% Try to execute the command
try
    
    if showEcho
        [status,~] = system(command,'-echo');
    else
        [status,~] = system(command);
    end
    
    if status ~= 0
        % Execution command return non-zero status, throw warning
        warning(msg)
        success = false;
    else
        success = true;
    end
    
catch
    
    % Graceful exception handling, throw warning
    warning(msg)
    success = false;

end

end
