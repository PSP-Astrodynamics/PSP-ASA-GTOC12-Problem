function output = uq_reduce_uq_empty_dispatcher(fun, inputs, varargin)
%UQ_REDUCE_UQ_EMPTY_DISPATCHER combines and accumulates each pair of values
%   from inputs with a given function executed using an empty DISPATCHER
%   (i.e., local execution).
%
%   See also UQ_REDUCE, UQ_MAP.

%% Parse and verify inputs

% Parameters (parameters of the function)
DefaultValue.Parameters = 'none';
% Users might still pass empty initial value as parameter explicitly
if any(strcmpi('Parameters',varargin))
    [parameters,varargin] = uq_parseNameVal(...
        varargin, 'Parameters', DefaultValue.Parameters);
else
    parameters = 'none';
end

% InitialValue (the initial value of the accumulator)
% Anything that users pass as InitialValue will be taken as is
if any(strcmpi('InitialValue',varargin))
    isInitialValueDefined = true;
    [initialValue,varargin] = uq_parseNameVal(...
        varargin, 'InitialValue', '');
else
    isInitialValueDefined = false;
end


% MatrixMapping (a way to pluck an element from a matrix)
Default.MatrixReduction = 'ByElements';
if isMatrix(inputs)
    [matrixReduction,varargin] = uq_parseNameVal(...
        varargin, 'MatrixReduction', Default.MatrixReduction);
    if isempty(matrixReduction) || ...
            ~any(strcmpi(matrixReduction,{'byelements','bycolumns','byrows'}))
        warning('Not recognized option value for *MatrixReduction*.')
        matrixReduction = Default.MatrixReduction;
    end
else
    matrixReduction = '';
end

% Check if there's a NAME/VALUE pair leftover
if ~isempty(varargin)
    warning('Unparsed NAME/VALUE argument pairs remain.')
end


%% How many elements?
if isstruct(inputs) && isempty(fieldnames(inputs))
    nElems = 0;
elseif isMatrix(inputs)
    switch lower(matrixReduction)
        case 'byelements'
            nElems = numel(inputs);
        case 'byrows'
            nElems = size(inputs,1);
        case 'bycolumns'
            nElems = size(inputs,2);
    end
else
    nElems = numel(inputs);
end

%% Get the initial value
if isInitialValueDefined
    accum = initialValue;
    idxStart = 1;
else
    accum = pluckInputs(inputs, 1, matrixReduction);
    idxStart = 2;
end

% Return immediately if:
%   - inputs are single element w/o initial value defined
%   - inputs are empty w/ initial value defined
if (nElems == 0 && isInitialValueDefined) || ...
        (nElems == 1 && ~isInitialValueDefined)
    output = accum;
    return
end

%% Reduce the sequence using fun    
for i = idxStart:nElems
    input = pluckInputs(inputs, i, matrixReduction);
    if strcmpi(parameters,'none')
        accum = fun(accum,input);
    else
        accum = fun(accum, input, parameters);
    end
end

output = accum;

end


%% ------------------------------------------------------------------------
function input = pluckInputs(inputs, idx, matrixReduction)
% Pluck an element from a sequence of inputs.

if numel(inputs) == 0 || (isstruct(inputs) && isempty(fieldnames(inputs)))
    error('inputs are empty and no initial value is provided.')
end


if iscell(inputs)
    % Make the inputs a column vector
    inputs = inputs(:);
    input = inputs{idx};
elseif isMatrix(inputs)
    switch lower(matrixReduction)
        case 'byelements'
            input = inputs(idx);
        case 'byrows'
            input = inputs(idx,:);
        case 'bycolumns'
            input = inputs(:,idx);
    end
else
    % Make the inputs a column vector
    inputs = inputs(:);
    input = inputs(idx);
end

end


%% ------------------------------------------------------------------------
function isAMatrix = isMatrix(inputs)
% Custom definition of a matrix in uq_reduce.

isAMatrix = (isnumeric(inputs) || islogical(inputs)) && ismatrix(inputs);

end

