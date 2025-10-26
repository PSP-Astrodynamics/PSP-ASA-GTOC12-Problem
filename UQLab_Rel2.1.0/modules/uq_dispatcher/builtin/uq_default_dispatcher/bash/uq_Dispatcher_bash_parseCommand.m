function parsedCommand = uq_Dispatcher_bash_parseCommand(command,numInputs)
%UQ_DISPATCHER_MAP_PARSECOMMAND parses Linux commands specified in uq_map.
%
%   Inputs
%   ------
%   - command: char array
%       may include placeholder with inputs ordering and formats.
%   - numInputs: scalar integer
%
%   Output
%   ------
%   - parsedCommand: parsed Linux command
%       placeholders are replaced with linux position argument list,
%       enclosed with '{}' to allow a list of more than 9 arguments.
%
%   Example
%   -------
%       command = 'echo {1} {3} {4} {2}'
%       uq_Dispatcher_map_parseCommand(command) % echo ${1} ${3} ${4} ${2}
%
%       command = 'echo {1:%g} {2:%s}';  % with formatting
%       uq_Dispatcher_map_parseCommand(command) % echo ${1} ${2}

%% Inputs verification
if nargin < 2 || numInputs < 0
    numInputs = 0;
end

%% Parse Map Command
posFmtPlaceholder = '{.*?}';
posFmtChar = regexp(command,posFmtPlaceholder,'match');

if isempty(posFmtChar)
    % Simple specification
    if numInputs ~= 0
        % Create argument list
        argsList = cellstr(num2str(transpose(1:numInputs)));
        % Remove whitespace
        argsList = regexprep(argsList,'\s','');
        argsList = strcat('$',argsList);
        parsedCommand = sprintf('%s %s ', command, argsList{:});
    else
        parsedCommand = [command ' ' '"$@"'];  % Use all arguments
    end
else
    % Complex specification
    numInputs = numel(posFmtChar);
    argsList = cell(numInputs,1);
    for i = 1:numInputs
        posFmtChar{i} = regexprep(posFmtChar{i}, {'{','}'},'');
        splitChar = strsplit(posFmtChar{i},':');
        argsList{i} = splitChar{1};
    end
    % Enclose with '{}' to accept more than 10 arguments
    % NOTE: '$' is a special character in the replacement text (escape)
    argsList = strcat('$',argsList);
    parsedCommand = regexprep(command, posFmtPlaceholder, argsList, 'once');
end

% Enclose with '{}' to accept more than 10 arguments
% Group matching (use tokens)
parsedCommand = regexprep(parsedCommand,'\$(\d+)', '\${$1}');

% Remove trailing whitespace
parsedCommand = regexprep(parsedCommand,'\s+$','');
% Remove leading whitespace
parsedCommand = regexprep(parsedCommand,'^\s+','');

end
