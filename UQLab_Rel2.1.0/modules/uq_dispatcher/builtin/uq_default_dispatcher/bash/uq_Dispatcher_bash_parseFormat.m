function parsedFormat = uq_Dispatcher_bash_parseFormat(command)
%UQ_DISPATCHER_MAP_PARSEFORMAT parses Linux commands specified in uq_map.
%
%   Inputs
%   ------
%   - command: char array
%       May include placeholder with inputs ordering and formats.
%
%   Output
%   ------
%   - parsedFormat: parsed formatting string
%       The formatting string follows MATLAB (i.e., C) format.
%
%   Example
%   -------
%       command = 'echo {1:%g} {3:%s} {2:%10.4f}'
%       uq_Dispatcher_map_parseFormat(command) % {'%g'; '%10.4f'; '%s'}
%
%       command = 'echo {1} {2} {3}';  % w/o formatting
%       uq_Dispatcher_map_parseFormat(command) % {''; ''; ''}
%
%       command = 'echo';  % w/o formatting, no inputs
%       uq_Dispatcher_map_parseFormat(command) % {}

%% Parse formatting string
posFmtPlaceholder = '{.*?}';
posFmtChar = regexp(command, posFmtPlaceholder, 'match');

if isempty(posFmtChar)
    % No position or formatting string
    parsedFormat = {};
else
    % With position or formatting string
    numInputs = numel(posFmtChar);
    posChar = cell(numInputs,1);
    fmtChar = cell(numInputs,1);
    for i = 1:numInputs
        posFmtChar{i} = regexprep(posFmtChar{i}, {'{','}'},'');
        splitChar = strsplit(posFmtChar{i},':');
        posChar{i} = splitChar{1};
        if numel(splitChar) == 2
            fmtChar{str2double(posChar{i})} = splitChar{2};
        else
            % if formatting string not specified, assign empty char
            fmtChar{str2double(posChar{i})} = '';
        end
    end
    parsedFormat = fmtChar;
end

end
