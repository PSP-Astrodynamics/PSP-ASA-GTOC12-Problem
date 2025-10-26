function formattedInputs = uq_Dispatcher_bash_printData(inputs,formatChar)
%UQ_DISPATCHER_MAP_PRINTINPUT prints a formatted char of input data.
%
%   Inputs
%   ------
%       - inputs: cell array of inputs
%           Each element must either be char array or scalar numeric.
%       - formatChar: cell array of formatting string
%           If a cell element has an empty string, num2str() with default
%           option will be used for that input element.
%           If not given, num2str() will be used for all input elements.
%
%   Output
%   ------
%       - formattedInputs: char array of formatted input
%
%   Example
%   -------
%       inputs = {}
%       uq_Dispatcher_bash_printData(inputs)   % ''
%
%       inputs = {100; 'abc'; 45.0; -78}
%       uq_Dispatcher_bash_printData(inputs) % '100 abc 45 -78'
%
%       inputs = {100; 'abc'; 45.0; -78};  % with formatting
%       formatChar = {'%d'; '%s'; '%7.4f'; '%5.3e'}
%       uq_Dispatcher_bash_printData(inputs) % '100 abc 45.0000 -7.800e+01'
%
%       inputs = {100; 'abc'; 45.0; -78};  % with formatting
%       formatChar = {'%d', '', '', '%5.3e'}
%       uq_Dispatcher_bash_printData(inputs) % '100 abc 45 -7.800e+01'

%% Verify inputs, make everything a cell array
if ~iscell(inputs) && ~isempty(inputs)
    if isnumeric(inputs)
        inputs = num2cell(inputs);
    else
        inputs = {inputs};
    end
end

% If required, change the dimension of 'formatChar' cell array to conform
% with 'inputs'
if nargin == 2 && ~iscell(formatChar)
    if isempty(formatChar)
        formatChar = cell(numel(inputs),1);
        formatChar(:) = {''};
    else
        formatChar = {formatChar};
    end
end

%% If empty inputs, return immediately
if isempty(inputs)
    formattedInputs = '';
    return
end

%% If formatting string not specified, print inputs as string ('num2str')
if nargin < 2 || isempty(formatChar)
    formattedInputs = cellfun(@num2str, inputs, 'UniformOutput', false);
    formattedInputs = [sprintf('%s ',formattedInputs{1:end-1}),...
        formattedInputs{end}];
    return
end

%% If dimension does not match, throw an error
if numel(inputs) ~= numel(formatChar)
    error('Number of formatting strings is inconsistent with the number of inputs.')
end

%% Format inputs for printing
nInputs = numel(inputs);
formattedInputs = cell(nInputs,1);
for i = 1:nInputs
    if isempty(formatChar{i})
        formattedInput = sprintf('%s',num2str(inputs{i}));
    else
        templateChar = sprintf('%s', formatChar{i});
        formattedInput = sprintf(templateChar,inputs{i});
    end
    formattedInputs{i} = formattedInput;
end

formattedInputs = [sprintf('%s ',formattedInputs{1:end-1}),...
    formattedInputs{end}];

end
