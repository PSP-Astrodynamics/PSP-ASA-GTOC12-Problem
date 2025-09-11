function outCmd = uq_UQLink_util_addCD(inpCmd,executionPath,os)
%UQ_UQLINK_UTIL_ADDCD adds 'cd' to execution path to an execution command.

%% Parse and verify inputs
if nargin < 3
    if ispc
        os = 'pc';
    else
        os = 'unix';
    end
end

%% Add CD to a command
% Create a new command that also include cd to execution path
% Note that the command includes double quotes around the main quote
switch lower(os)
    case 'pc'
        % add /d to force drive change if necessary: cd /d C: ...
        outCmd = ['cd /d "', executionPath, '" && ', inpCmd];
    case 'unix'
        outCmd = ['cd "', executionPath, '" && ', inpCmd];
    otherwise
        error('Unsupported OS.')
end

end

