function varargout = uq_map_uq_empty_dispatcher(fun, inputs, varargin)
%UQ_MAP_UQ_EMPTY_DISPATCHER maps a sequence of inputs to another sequence
%   with a given function executed using an empty DISPATCHER (i.e., local
%   execution).
%
%   See also UQ_MAP, UQ_REDUCE.

%% Parse and verify inputs

% Check inputs
if isempty(inputs)
    varargout{1} = {};  % nothing to do, return immediately
    return
end

if ischar(inputs)
    error('Character array as sequence not supported.')
end

% Check if a structure is empty
if isstruct(inputs) && isempty(fieldnames(inputs))
    varargout{1} = {};
    return
end

% Currently, only supports at most 2D matrix
if (isnumeric(inputs) || islogical(inputs)) && ~ismatrix(inputs)
    error('Matrix as inputs is supported only up to 2-dimension.')
end

% Parameters (parameters of the function)
if any(strcmpi('Parameters',varargin))
    DefaultValue.Parameters = 'none';
    [parameters,varargin] = uq_parseNameVal(...
        varargin, 'Parameters', DefaultValue.Parameters);
else
    parameters = 'none';
end

% NumArgsOut (number of output arguments)
Default.NumOfOutArgs = max(1,nargout);
[numOfOutArgs,varargin] = uq_parseNameVal(...
    varargin, 'NumOfOutArgs', Default.NumOfOutArgs);

% ExpandCell (flag to expand cell)
Default.ExpandCell = false;
[expandCell,varargin] = uq_parseNameVal(...
        varargin, 'ExpandCell', Default.ExpandCell);

% MatrixMapping (Way to pluck an element from a matrix)
Default.MatrixMapping = 'ByElements';
if ismatrix(inputs)
    [matrixMapping,varargin] = uq_parseNameVal(...
        varargin, 'MatrixMapping', Default.MatrixMapping);
    if isempty(matrixMapping) || ...
            ~any(strcmpi(matrixMapping,{'byelements','bycolumns','byrows'}))
        warning('Not recognized option value for *MatrixMapping*.')
        matrixMapping = Default.MatrixMapping;
    end
end

% ErrorHandler (a function to handle an error)
Default.ErrorHandler = @defaultErrorHandler;
[errorHandler,varargin] = uq_parseNameVal(...
    varargin, 'ErrorHandler', Default.ErrorHandler);
if ~islogical(errorHandler) && ~isa(errorHandler,'function_handle')
    error('*ErrorHandler* must either be a logical or a function handle.')
end
if islogical(errorHandler)
    if errorHandler
        errorHandler = Default.ErrorHandler;
    else
        errorHandler = [];
    end
end

% Check if there's a NAME/VALUE pair leftover
if ~isempty(varargin)
    warning('Unparsed NAME/VALUE argument pairs remain.')
end

%% Map 'inputs' sequence to another sequence using 'fun'

if ischar(fun)
    % if 'fun' is a char then it is a system command
    [varargout{1:numOfOutArgs}] = fevalSystem(fun, inputs, parameters);
elseif iscell(inputs)
    if numOfOutArgs == 1
        varargout{1} = fevalCell(...
            fun, inputs, parameters, expandCell, errorHandler);
    else
        [varargout{1:numOfOutArgs}] = fevalCell(...
            fun, inputs, parameters, expandCell, errorHandler);
    end
elseif isstruct(inputs)
    % Make sure struct inputs is in row format
    if numOfOutArgs == 1
        varargout{1} = fevalStruct(fun, inputs, parameters, errorHandler);
    else
        [varargout{1:numOfOutArgs}] = fevalStruct(...
            fun, inputs, parameters, errorHandler);
    end
elseif isnumeric(inputs) || islogical(inputs)
    if numOfOutArgs == 1
        varargout{1} = fevalArray(...
            fun, inputs, parameters, matrixMapping, errorHandler);
    else
        [varargout{1:numOfOutArgs}] = fevalArray(...
            fun, inputs, parameters, matrixMapping, errorHandler);
    end
end

end


%% ------------------------------------------------------------------------
function varargout = fevalCell(fun, inputs, parameters, expandCell, errorHandler)
% Applies a function to each element of a cell array.

if isempty(errorHandler)
    if strcmpi(parameters,'none')
        if expandCell
            [varargout{1:nargout}] = cellfun(@(x) fun(x{:}), inputs,...
                'UniformOutput', false);
        else
            [varargout{1:nargout}] = cellfun(fun, inputs,...
                'UniformOutput', false);
        end
    else
        if expandCell
            [varargout{1:nargout}] = cellfun(...
                @(x) fun(x{:},parameters), inputs,...
                'UniformOutput', false);
        else
            [varargout{1:nargout}] = cellfun(@(x) fun(x,parameters), inputs,...
                'UniformOutput', false);
        end
    end
else
    if strcmpi(parameters,'none')
        if expandCell
            [varargout{1:nargout}] = cellfun(@(x) fun(x{:}), inputs,...
                'UniformOutput', false, 'ErrorHandler', errorHandler);
        else
            [varargout{1:nargout}] = cellfun(fun, inputs,...
                'UniformOutput', false, 'ErrorHandler', errorHandler);
        end
    else
        if expandCell
            [varargout{1:nargout}] = cellfun(...
                @(x) fun(x{:},parameters), inputs,...
                'UniformOutput', false, 'ErrorHandler', errorHandler);
        else
            [varargout{1:nargout}] = cellfun(@(x) fun(x,parameters), inputs,...
                'UniformOutput', false, 'ErrorHandler', errorHandler);
        end
    end
end

end


%% ------------------------------------------------------------------------
function varargout = fevalStruct(fun, inputs, parameters, errorHandler)
% Applies a function to each element of a structure array.

if isempty(errorHandler)
    if strcmpi(parameters,'none')
        [varargout{1:nargout}] = arrayfun(fun, inputs,...
            'UniformOutput', false);
    else
        [varargout{1:nargout}] = arrayfun(@(x) fun(x,parameters), inputs,...
            'UniformOutput', false);
    end
else
    if strcmpi(parameters,'none')
        [varargout{1:nargout}] = arrayfun(fun, inputs,...
            'UniformOutput', false, 'ErrorHandler', errorHandler);
    else
        [varargout{1:nargout}] = arrayfun(@(x) fun(x,parameters), inputs,...
            'UniformOutput', false, 'ErrorHandler', errorHandler);
    end
end

end


%% ------------------------------------------------------------------------
function varargout = fevalArray(fun, inputs, parameters, matrixMapping, errorHandler)
% Applies a function to each element of a matrix. The notion of an element
% depends on the mapping.

switch lower(matrixMapping)
    case 'byelements'
        if isempty(errorHandler)
            if strcmpi(parameters,'none')
                [varargout{1:nargout}] = arrayfun(fun, inputs,...
                    'UniformOutput', false);
            else
                [varargout{1:nargout}] = arrayfun(...
                    @(x) fun(x,parameters), inputs,...
                    'UniformOutput', false);
            end
        else
            if strcmpi(parameters,'none')
                [varargout{1:nargout}] = arrayfun(fun, inputs,...
                'UniformOutput', false,...
                'ErrorHandler', errorHandler);
            else
                [varargout{1:nargout}] = arrayfun(...
                    @(x) fun(x,parameters), inputs,...
                    'UniformOutput', false,...
                    'ErrorHandler', errorHandler);
            end
        end

    case 'byrows'
        nRows = size(inputs,1);
        if isempty(errorHandler)
            if strcmpi(parameters,'none')
                [varargout{1:nargout}] = arrayfun(...
                    @(i) fun(inputs(i,:)), transpose(1:nRows),...
                    'UniformOutput', false);
            else
                [varargout{1:nargout}] = arrayfun(...
                    @(i) fun(inputs(i,:),parameters), transpose(1:nRows),...
                    'UniformOutput', false);
            end
        else
            if strcmpi(parameters,'none')
                [varargout{1:nargout}] = arrayfun(...
                    @(i) fun(inputs(i,:)), transpose(1:nRows),...
                    'UniformOutput', false,...
                    'ErrorHandler', errorHandler);
            else
                [varargout{1:nargout}] = arrayfun(...
                    @(i) fun(inputs(i,:),parameters), transpose(1:nRows),...
                    'UniformOutput', false,...
                    'ErrorHandler', errorHandler);
            end
        end
        
    case 'bycolumns'
        nCols = size(inputs,2);
        if isempty(errorHandler)
            if strcmpi(parameters,'none')
                [varargout{1:nargout}] = arrayfun(...
                    @(i) fun(inputs(:,i)), 1:nCols,...
                    'UniformOutput', false);
            else
                [varargout{1:nargout}] = arrayfun(...
                    @(i) fun(inputs(:,i),parameters), 1:nCols,...
                    'UniformOutput', false);
            end
        else
            if strcmpi(parameters,'none')
                [varargout{1:nargout}] = arrayfun(...
                    @(i) fun(inputs(:,i)), 1:nCols,...
                    'UniformOutput', false,...
                    'ErrorHandler', errorHandler);
            else
                [varargout{1:nargout}] = arrayfun(...
                    @(i) fun(inputs(:,i),parameters), 1:nCols,...
                    'UniformOutput', false,...
                    'ErrorHandler', errorHandler);
            end
        end
end

end


%% ------------------------------------------------------------------------
function varargout = fevalSystem(fun, inputs, parameters)
% Applies a system command to each element of a cell array input.

output1 = cell(size(inputs));
output2 = cell(size(inputs));

if strcmpi(parameters,'none')
    for i = 1:numel(inputs)
        if ~iscell(inputs{i})
            inputs(i) = {inputs(i)};
        end
        cmd = uq_Dispatcher_bash_printCommand(fun,inputs{i});
        [output1{i},output2{i}] = system(cmd);
    end
else
    for i = 1:numel(inputs)
        if ~iscell(inputs{i})
            inputs(i) = {inputs(i)};
        end
        cmd = uq_Dispatcher_bash_printCommand(fun,inputs{i});
        cmd = sprintf('%s %s', cmd, parameters);
        [output1{i},output2{i}] = system(cmd);
    end
end

outputs = {output1,output2};
[varargout{1:nargout}] = deal(outputs{:});

end


%% ------------------------------------------------------------------------
function varargout = defaultErrorHandler(varargin)
% Common error handler when an evaluation throws an error.

[varargout{1:nargout}] = deal(nan);

end
