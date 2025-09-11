function exeSuccess = uq_UQLink_helper_execExtCode(InternalProp)
%UQ_UQLINK_HELPER_EXECEXTCODE executes external (3rd-party) code.
%
%   Inputs
%   ------
%   - InternalProp: Internal properties of the UQLink MODEL object, struct
%
%   Output
%   ------
%   - exeSuccess: Flag indicating successful code execution, logical

%% Set local runtime variables
runIdx = InternalProp.Runtime.RunIdx;
runDirIdx = InternalProp.Runtime.RunDirIdx;

%% Create the command to execute 3rd-party code

% Get the execution command
exeCmd = InternalProp.Command;
splitCmd = strsplit(exeCmd);
inpChar = strjoin(splitCmd(2:end));

% Substitute the input basenames in the command with the indexed ones
inputBasenamesIndexed = strcat(...
    InternalProp.Runtime.InputFileName,...
    num2str(runIdx,InternalProp.Runtime.DigitFormat));
inpChar = uq_UQLink_util_replaceFilenames(...
    inpChar, InternalProp.Runtime.InputFileName, inputBasenamesIndexed);

% Substitute the output filenames in the command line with the indexed one
outputBasenamesIndexed = strcat(InternalProp.Runtime.OutputFileName,...
    num2str(runIdx,InternalProp.Runtime.DigitFormat));
% Note: match and replace the filenames, not only the basename
inpChar = uq_UQLink_util_replaceFilenames(...
    inpChar,...
    InternalProp.Runtime.OutputFileName,...
    outputBasenamesIndexed,...
    InternalProp.Runtime.OutputExtension);

exeCmd = [splitCmd{1} ' ' inpChar];

% Note:
%   Input and output might have the same basename, they might appear with
%   extension (if they have extensions) such as
%       $ myCode myProblem.inp myProblem.out
%   or without (if they don't have any), such as:
%       $ myCode -i myProblem -o myProblem

% Add the executable path if it is given (otherwise, it's assumed in PATH)
if ~isempty(InternalProp.ExecutablePath)
    exeCmd = fullfile(InternalProp.ExecutablePath,exeCmd);
end
    
% Add double quotes around directory names with spaces
exeCmd = uq_UQLink_util_addQuotesOnPath(exeCmd,filesep);
% Append a 'cd'-to-the-running-directory to the command
exeCmd = uq_UQLink_util_addCD(exeCmd,runDirIdx);

%% TODO: Make this consistent with UQLab Display option (numeric ID)
if strcmpi(InternalProp.Display,'verbose')
    showEcho = true;
else
    showEcho = false;
end

%% Create a warning message if execution is unsuccessful
msg = sprintf(['Third party software returned an error for run #%d:\n',...
            'Returning NaN in the corresponding output'],...
            runIdx);

%% Execute the 3rd-party executable
exeSuccess = uq_UQLink_util_execCommand(exeCmd, showEcho, msg);

end
