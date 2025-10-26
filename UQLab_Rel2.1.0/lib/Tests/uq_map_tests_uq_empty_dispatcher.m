function pass = uq_Dispatcher_tests_map_uq_empty_dispatcher(level)
%UQ_DISPATCHER_TESTS_MAP_UQ_EMPTY_DISPATCHER tests uq_map with an empty
%   DISPATCHER unit (local execution).

%% Initialize test
if nargin < 1
    level = 'normal';
end

uqlab('-nosplash')

fprintf('Running: | %s | %s...', level, mfilename);

%% Get all local test functions
testFunctions = localfunctions;

%% Execute all test functions
warning('off')
for i = 1:numel(testFunctions)
    if ~any(strcmpi(func2str(testFunctions{i}),{'myVar','myMean','myStd','customErrorHandler'}))
        % Exclude helper functions from testing
        feval(testFunctions{i})
    end
end
warning('on')

%% Return the results
fprintf('PASS\n')

pass = true;

end


%% ------------------------------------------------------------------------
function testSimpleCellInput()
% A test for a simple cell as input.
inputs = {linspace(0,10); linspace(0,100); linspace(0,1000)};

refValues = cellfun(@mean, inputs, 'UniformOutput', false);
mappedValues = uq_map(@mean, inputs, 'ExpandCell', false);

assert(isequal(refValues,mappedValues))

% With parameter 'none'
mappedValues = uq_map(@mean, inputs, 'ExpandCell', false,...
    'Parameters', 'none');
assert(isequal(refValues,mappedValues))

end


%% ------------------------------------------------------------------------
function testNestedCellInput()
% A test for a nested cell as input.
inputs = {{10,2}; {100,0.5}; {10000,0.5}; {5,2}; {4,2}};

refValues = cellfun(@(x) power(x{:}), inputs, 'UniformOutput', false);
mappedValues = uq_map(@power, inputs, 'ExpandCell', true);

assert(isequal(refValues,mappedValues))

% With parameter 'none'
mappedValues = uq_map(@power, inputs,...
    'Parameters', 'none', 'ExpandCell', true);
assert(isequal(refValues,mappedValues))

end


%% ------------------------------------------------------------------------
function testStructArrayInput()
% A test for a struct array as input.
inputs(1).X = linspace(1,100);
inputs(1).Y = linspace(1,10);
inputs(2).X = linspace(1,10);
inputs(2).Y = linspace(0,1);
inputs(3).X = linspace(0,1);
inputs(3).Y = linspace(1,1000);

refValues = arrayfun(@funStruct, inputs, 'UniformOutput', false);
mappedValues = uq_map(@funStruct,inputs);

assert(isequal(refValues,mappedValues))

    function output = funStruct(S)
        output = mean(S.X) + var(S.Y);
    end

% With parameter 'none'
mappedValues = uq_map(@funStruct, inputs, 'Parameters', 'none');
assert(isequal(refValues,mappedValues))

end


%% ------------------------------------------------------------------------
function testMatrixInput()
% A test for a matrix as input with different ways of plucking an element.
inputs = rand(10,10);

refValues = arrayfun(@std, inputs, 'UniformOutput', false);
% By Elements (as the default)
mappedValues = uq_map(@std,inputs);
assert(isequal(refValues,mappedValues))
% With parameter 'none'
mappedValues = uq_map(@std, inputs, 'Parameters', 'none');
assert(isequal(refValues,mappedValues))

% By Elements (by explicit specification)
mappedValues = uq_map(@std, inputs, 'MatrixMapping', 'ByElements');
assert(isequal(refValues,mappedValues))
% With parameter 'none'
mappedValues = uq_map(@std, inputs, 'MatrixMapping', 'ByElements',...
    'Parameters', 'none');
assert(isequal(refValues,mappedValues))

% By Elements (the default, due to using invalid option)
mappedValues = uq_map(@std, inputs, 'MatrixMapping', 'bysomething');
assert(isequal(refValues,mappedValues))
% With parameter 'none'
mappedValues = uq_map(@std, inputs, 'MatrixMapping', 'bysomething',...
    'Parameters', 'none');
assert(isequal(refValues,mappedValues))

% ByRows
refValues = arrayfun(@(i) std(inputs(i,:)), transpose(1:size(inputs,1)),...
    'UniformOutput', false);
mappedValues = uq_map(@std, inputs, 'MatrixMapping', 'ByRows');
assert(isequal(refValues,mappedValues))
% With parameter 'none'
mappedValues = uq_map(@std, inputs, 'MatrixMapping', 'ByRows',...
    'Parameters', 'none');
assert(isequal(refValues,mappedValues))

% ByColumns
refValues = arrayfun(@(i) std(inputs(:,i)), 1:size(inputs,2),...
    'UniformOutput', false);
mappedValues = uq_map(@std, inputs, 'MatrixMapping', 'ByColumns');
assert(isequal(refValues,mappedValues))
% With parameter 'none'
mappedValues = uq_map(@std, inputs, 'MatrixMapping', 'ByColumns',...
    'Parameters', 'none');
assert(isequal(refValues,mappedValues))

end


%% ------------------------------------------------------------------------
function testCommandInput()
% A test for list of system commands as input.
if isunix
    funRef = 'echo "%4.2f/%4.2f" | bc';
    fun = 'echo "{2:%4.2f}/{1:%4.2f}" | bc';
    inputs = {{5,100};{200,2};{2,1}};
else
    % in Windows there's only a built-in support for arithmetic
    % integer operation
    funRef = 'set /a %d/%d';
    fun = 'set /a {2:%d}/{1:%d}';
    inputs = {{5,100};{200,2};{2,1}};
end

refValues1 = cell(numel(inputs),1);
refValues2 = cell(numel(inputs),1);
for i = 1:numel(inputs)
    cmd = sprintf(funRef, inputs{i}{2}, inputs{i}{1});
    [refValues1{i},refValues2{i}] = system(cmd);
end

[mappedValues1,mappedValues2] = uq_map(fun,inputs);

assert(isequal(refValues1,mappedValues1))
assert(isequal(refValues2,mappedValues2))

end


%% ------------------------------------------------------------------------
function testParameterCell()
% A test for a cell as input and using a parameters.
inputs = {randn(5,5); randn(10,10); randn(50,50); randn(1e2,1e2)};

Parameters.W = 1;
Parameters.All = 'All';
refValues = cellfun(@(x) myVar(x, Parameters.W, Parameters.All), inputs,...
    'UniformOutput', false);
mappedValues = uq_map(@(x,p) myVar(x, p.W, p.All), inputs,...
    'Parameters', Parameters, 'ExpandCell', false); 

assert(isequal(refValues,mappedValues));

end


%% ------------------------------------------------------------------------
function testParameterStruct()
% A test for using a parameter and a struct array as input.
inputs(1).X = rand(10,2);
inputs(1).Y = rand(100,10);
inputs(2).X = rand(10,10);
inputs(2).Y = rand(10,10);
inputs(3).X = rand(1e2,1e2);
inputs(3).Y = rand(1e4,10);

Parameters.W = 1;
Parameters.All = 'All';
refValues = arrayfun(...
    @(x) myVar(x.X, Parameters.W, Parameters.All) + ...
        myVar(x.Y, Parameters.W, Parameters.All),...
    inputs,...
    'UniformOutput', false);
mappedValues = uq_map(@funStruct, inputs,...
    'Parameters', Parameters); 

    function output = funStruct(S,P)
        output = myVar(S.X, P.W, P.All) + myVar(S.Y, P.W, P.All);
    end

assert(isequal(refValues,mappedValues));

end


%% ------------------------------------------------------------------------
function testParameterMatrix()
% A test for using a parameter and a matrix as input.
inputs = rand(100,100);

Parameters.W = 1;
Parameters.All = 'all';

refValues = arrayfun(...
    @(x) myStd(x, Parameters.W, Parameters.All), inputs,...
    'UniformOutput', false);
% ByElements
mappedValues = uq_map(@(x,P) myStd(x,P.W,P.All), inputs,...
    'Parameters', Parameters);
assert(isequal(refValues,mappedValues))
% ByElements (explicit specification)
mappedValues = uq_map(@(x,P) myStd(x,P.W,P.All), inputs,...
    'Parameters', Parameters, 'MatrixMapping', 'ByElements');
assert(isequal(refValues,mappedValues))
% ByElements (the default, due to invalid specification)
mappedValues = uq_map(@(x,P) myStd(x,P.W,P.All), inputs,...
    'Parameters', Parameters, 'MatrixMapping', 'BySomething');
assert(isequal(refValues,mappedValues))

% ByRows
refValues = arrayfun(...
    @(i) myStd(inputs(i,:), Parameters.W, Parameters.All),...
    transpose(1:size(inputs,1)),...
    'UniformOutput', false);
mappedValues = uq_map(@(x,P) myStd(x,P.W,P.All), inputs,...
    'Parameters', Parameters, 'MatrixMapping', 'ByRows');
assert(isequal(refValues,mappedValues))

% ByColumns
refValues = arrayfun(...
    @(i) myStd(inputs(:,i), Parameters.W, Parameters.All),...
    1:size(inputs,2),...
    'UniformOutput', false);
mappedValues = uq_map(@(x,P) myStd(x,P.W,P.All), inputs,...
    'Parameters', Parameters, 'MatrixMapping', 'ByColumns');
assert(isequal(refValues,mappedValues))

end


%% ------------------------------------------------------------------------
function testParameterSystemCommand()
% A test for using a parameter and a list of system commands as input.
if isunix
    funRef = 'echo "%4.2f/%4.2f" | bc -l';
    fun = 'echo "{2:%4.2f}/{1:%4.2f}" | bc';
    inputs = {{5,100};{200,2};{2,1}};
    parameters = '-l';
    refValues1 = cell(size(inputs));
    refValues2 = cell(size(inputs));
    for i = 1:numel(inputs)
        cmd = sprintf(funRef, inputs{i}{2}, inputs{i}{1});
        [refValues1{i},refValues2{i}] = system(cmd);
    end
else
    funRef = '%s /?';
    fun = '{1:%s}';
    inputs = {'DIR', 'ECHO', 'SET'};
    parameters = '/?';
    refValues1 = cell(size(inputs));
    refValues2 = cell(size(inputs));
    for i = 1:numel(inputs)
        cmd = sprintf(funRef,inputs{i});
        [refValues1{i},refValues2{i}] = system(cmd);
    end
end

[mappedValues1,mappedValues2] = uq_map(fun, inputs,...
    'Parameters', parameters);

assert(isequal(refValues1,mappedValues1))
assert(isequal(refValues2,mappedValues2))

end


%% ------------------------------------------------------------------------
function testEmptyParameterMatrixInputByElements()
% A test for explicitly passing an empty value to 'Parameters'.
inputs = randi(10,20,10);

P = [];
refValues = arrayfun(@(i) testFunction(inputs(i,:),P),...
    transpose(1:size(inputs,1)), 'UniformOutput', false);
mappedValues = uq_map(@testFunction, inputs,...
    'Parameters', P, 'MatrixMapping', 'ByRows');
assert(isequal(refValues,mappedValues))

    function Z = testFunction(X,P)
        if isempty(P)
            Z = -1*sum(X);
        else
            Z = sum(X);
        end
    end

end


%% ------------------------------------------------------------------------
function testErrorHandlingSimpleCell()
% A test for error handling with a simple cell as input.
inputs = {rand(1e2,1e2); ''; randn(1e3,1e3)};

% Test without parameter
refValues = cellfun(@funCell, inputs,...
    'UniformOutput', false, 'ErrorHandler', @errorHandler);
mappedValues = uq_map(@funCell, inputs, 'ExpandCell', false);

assert(isequaln(refValues,mappedValues))

% Test with parameter
Parameters = 'all';
refValues = cellfun(@(x) funCell(x,Parameters), inputs,...
    'UniformOutput', false, 'ErrorHandler', @errorHandler);
mappedValues = uq_map(@funCell, inputs, 'Parameters', Parameters,...
    'ExpandCell', false);

assert(isequaln(refValues,mappedValues))

    function output = funCell(x,P)
        if nargin == 1
            P = 'all';
        end
        if ischar(x)
            error('Input is a character array.')
        else
            output = myMean(x,P);
        end
    end

end


%% ------------------------------------------------------------------------
function testErrorHandlingNestedCell()
% A test for error handling with a nested cell as input.
inputs = {{1,2}; {'',''}; {3,2}};

% Test without parameter
refValues = cellfun(@(x) funCell(x{:}), inputs,...
    'UniformOutput', false, 'ErrorHandler', @errorHandler);
mappedValues = uq_map(@funCell, inputs, 'ExpandCell', true);

assert(isequaln(refValues,mappedValues))

% Test with parameter
P = 5;
refValues = cellfun(@(x) funCell(x{:},P), inputs,...
    'UniformOutput', false, 'ErrorHandler', @errorHandler);
mappedValues = uq_map(@funCell, inputs,...
    'Parameters', P, 'ExpandCell', true);

assert(isequaln(refValues,mappedValues))

    function output = funCell(x1,x2,P)
        if nargin < 3
            P = 1;
        end
        if ischar(x1) || ischar(x2)
            error('Input is a character array.')
        else
            output = power(x1,x2) * P;
        end
    end

end


%% ------------------------------------------------------------------------
function testErrorHandlingStruct()
% A test for error handling with a struct array as input.
inputs(1).X = rand(10,2);
inputs(1).Y = rand(100,10);
inputs(2).X = 'a';
inputs(2).Y = 'b';
inputs(3).X = rand(1e2,1e2);
inputs(3).Y = rand(1e4,10);

% Test without parameter
refValues = arrayfun(@funStruct, inputs,...
    'UniformOutput', false, 'ErrorHandler', @errorHandler);
mappedValues = uq_map(@funStruct,inputs); 

assert(isequaln(refValues,mappedValues));

% Test with parameter
Parameters.W = 1;
Parameters.All = 'All';
refValues = arrayfun(@(x) funStruct(x,Parameters), inputs,...
        'UniformOutput', false, 'ErrorHandler', @errorHandler);
mappedValues = uq_map(@funStruct, inputs,...
    'Parameters', Parameters); 

assert(isequaln(refValues,mappedValues));

    function output = funStruct(S,P)
        if nargin < 2
            P.W = 1;
            P.All = 'all';
        end
        if ischar(S.X) || ischar(S.Y)
            error('Input is a character array.')
        end
        output = myVar(S.X, P.W, P.All) + myVar(S.Y, P.W, P.All);
    end

end


%% ------------------------------------------------------------------------
function testErrorHandlingMatrix()
% A test for error handling with a matrix as input.
inputs = randi(10,10,5e1);
inputs([1 3 5],[8 9 10]) = nan;

% Test without parameter

refValues = arrayfun(@funMatrix, inputs,...
    'UniformOutput', false, 'ErrorHandler', @errorHandler);
% ByElements (as the default)
mappedValues = uq_map(@(x) funMatrix(x), inputs);
assert(isequaln(refValues,mappedValues))
% ByElements (explicit specification)
mappedValues = uq_map(@(x) funMatrix(x), inputs,...
    'MatrixMapping', 'ByElements');
assert(isequaln(refValues,mappedValues))
% ByElements (the default, due to invalid specification)
mappedValues = uq_map(@(x) funMatrix(x), inputs,...
    'MatrixMapping', 'Something');
assert(isequaln(refValues,mappedValues))

% ByRows
refValues = arrayfun(@(i) funMatrix(inputs(i,:)),...
    transpose(1:size(inputs,1)),...
    'UniformOutput', false, 'ErrorHandler', @errorHandler);
mappedValues = uq_map(@(x) funMatrix(x), inputs,...
    'MatrixMapping', 'ByRows');
assert(isequaln(refValues,mappedValues))

% ByColumns
refValues = arrayfun(@(i) funMatrix(inputs(:,i)),...
    1:size(inputs,2),...
    'UniformOutput', false, 'ErrorHandler', @errorHandler);
mappedValues = uq_map(@(x) funMatrix(x), inputs,...
    'MatrixMapping', 'ByColumns');
assert(isequaln(refValues,mappedValues))

% Test with parameter
Parameters.W = 1;
Parameters.All = 'all';

refValues = arrayfun(@(x) funMatrix(x,Parameters), inputs,...
    'UniformOutput', false, 'ErrorHandler', @errorHandler);
% ByElements (as the default)
mappedValues = uq_map(@funMatrix, inputs, 'Parameters', Parameters);
assert(isequaln(refValues,mappedValues))
% ByElements (explicit specification)
mappedValues = uq_map(@funMatrix, inputs,...
    'Parameters', Parameters, 'MatrixMapping', 'ByElements');
assert(isequaln(refValues,mappedValues))
% ByElements (the default, due to invalid specification)
mappedValues = uq_map(@funMatrix, inputs,...
    'Parameters', Parameters, 'MatrixMapping', 'BySomething');
assert(isequaln(refValues,mappedValues))

% ByRows
refValues = arrayfun(...
    @(i) funMatrix(inputs(i,:),Parameters), transpose(1:size(inputs,1)),...
    'UniformOutput', false, 'ErrorHandler', @errorHandler);
mappedValues = uq_map(@funMatrix, inputs,...
    'Parameters', Parameters, 'MatrixMapping', 'ByRows');
assert(isequaln(refValues,mappedValues))

% ByColumns
refValues = arrayfun(...
    @(i) funMatrix(inputs(:,i),Parameters), 1:size(inputs,2),...
    'UniformOutput', false, 'ErrorHandler', @errorHandler);
mappedValues = uq_map(@funMatrix, inputs,...
    'Parameters', Parameters, 'MatrixMapping', 'ByColumns');
assert(isequaln(refValues,mappedValues))

    function output = funMatrix(X,P)
        if nargin < 2
            P.W = 1;
            P.All = 'all';
        end
        if any(isnan(X),'all')
            error('NaN value.')
        end
        output = myStd(X, P.W, P.All);
    end

end


%% ------------------------------------------------------------------------
function testCustomErrorHandling()
% A test for using a user-defined error handler.
inputs = {1, 2, 3};
fun = @(x,y) x + y;

% No error handler
try
    uq_map(fun, inputs, 'ErrorHandler', false);
catch
    assert(true)
end

% Custom error handler
output = uq_map(fun, inputs, 'ErrorHandler', @customErrorHandler);
assert(isstruct(output{1}.ME))
assert(isstruct(output{2}.ME))
assert(isstruct(output{3}.ME))
assert(iscell(output{1}.ArgIn))
assert(iscell(output{2}.ArgIn))
assert(iscell(output{3}.ArgIn))

end


%% ------------------------------------------------------------------------
function testMultipleOutputsSimpleCell()
% A test for a function with multiple outputs using a simple cell as input.
inputs = {rand(1e1,1e1); rand(1e2,1e2); randn(1e3,1e3)};

% Test without parameter
numOfOutArgs = 2;
[refValues{1:numOfOutArgs}] = cellfun(@funCell, inputs,...
    'UniformOutput', false, 'ErrorHandler', @errorHandler);
[mappedValues{1:numOfOutArgs}] = uq_map(@funCell, inputs,...
    'ExpandCell', false);

assert(isequal(refValues,mappedValues))

% Test with parameter
P.W = 1;
P.All = 'all';
[refValues{1:numOfOutArgs}] = cellfun(@(x) funCell(x,P), inputs,...
    'UniformOutput', false, 'ErrorHandler', @errorHandler);
[mappedValues{1:numOfOutArgs}] = uq_map(@funCell, inputs,...
    'Parameters', P, 'ExpandCell', false);

assert(isequal(refValues,mappedValues))

    function [output1,output2] = funCell(x,P)
        if nargin == 1
            P.W = 1;
            P.All = 'all';
        end
        if ischar(x)
            error('Input is a character array.')
        else
            output1 = myMean(x,P.All);
            output2 = myStd(x, P.W, P.All);
        end
    end

end


%% ------------------------------------------------------------------------
function testMultipleOutputsNestedCell()
% A test for a function with multiple outputs using a nested cell as input.
inputs = {{1,2}; {4,5}; {3,2}};
numOfOutArgs = 2;

% Test without parameter
[refValues{1:numOfOutArgs}] = cellfun(@(x) funCell(x{:}), inputs,...
    'UniformOutput', false, 'ErrorHandler', @errorHandler);
[mappedValues{1:numOfOutArgs}] = uq_map(@funCell, inputs,...
    'ExpandCell', true);

assert(isequal(refValues,mappedValues))

% Test with parameter
P = 5;
[refValues{1:numOfOutArgs}] = cellfun(@(x) funCell(x{:},P), inputs,...
    'UniformOutput', false, 'ErrorHandler', @errorHandler);
[mappedValues{1:numOfOutArgs}] = uq_map(@funCell, inputs,...
    'Parameters', P, 'NumOfOutArgs', numOfOutArgs, 'ExpandCell', true);

assert(isequal(refValues,mappedValues))

    function [output1,output2] = funCell(x1,x2,P)
        if nargin < 3
            P = 1;
        end
        if ischar(x1) || ischar(x2)
            error('Input is a character array.')
        else
            output1 = power(x1,x2) * P;
            output2 = power(x2,x1) * P;
        end
    end

end


%% ------------------------------------------------------------------------
function testMultipleOutputsStruct()
% A test for a function with multiple outputs using a struct array as input.
inputs(1).X = rand(10,2);
inputs(1).Y = rand(100,10);
inputs(2).X = 'a';
inputs(2).Y = 'b';
inputs(3).X = rand(1e2,1e2);
inputs(3).Y = rand(1e4,10);
numOfOutArgs = 2;

% Test without parameter
[refValues{1:numOfOutArgs}] = arrayfun(@funStruct, inputs,...
        'UniformOutput', false, 'ErrorHandler', @errorHandler);
[mappedValues{1:numOfOutArgs}] = uq_map(@funStruct, inputs); 

assert(isequaln(refValues,mappedValues));

% Test with parameter
Parameters.W = 1;
Parameters.All = 'All';
[refValues{1:numOfOutArgs}] = arrayfun(@(x) funStruct(x,Parameters), inputs,...
        'UniformOutput', false, 'ErrorHandler', @errorHandler);
[mappedValues{1:numOfOutArgs}] = uq_map(@funStruct, inputs,...
    'Parameters', Parameters); 

assert(isequaln(refValues,mappedValues));

    function [output1,output2] = funStruct(S,P)
        if nargin < 2
            P.W = 1;
            P.All = 'all';
        end
        if ischar(S.X) || ischar(S.Y)
            error('Input is a character array.')
        end
        output1 = myVar(S.X, P.W, P.All) + myVar(S.Y, P.W, P.All);
        output2 = myMean(S.X,P.All) + myMean(S.Y,P.All);
    end

end


%% ------------------------------------------------------------------------
function testMultipleOutputsMatrix()
% A test for a function with multiple outputs using a matrix as input.
inputs = randi(10,10,5e2);
inputs([1 3 5],[8 9 10]) = nan;
numOfOutArgs = 2;

% Test without parameter
[refValues{1:numOfOutArgs}] = arrayfun(@funMatrix, inputs,...
    'UniformOutput', false, 'ErrorHandler', @errorHandler);
% ByElements (as the default)
[mappedValues{1:numOfOutArgs}] = uq_map(@funMatrix, inputs);
assert(isequaln(refValues,mappedValues))
% ByElements (explicit specification)
[mappedValues{1:numOfOutArgs}] = uq_map(@funMatrix, inputs,...
    'MatrixMapping', 'ByElements');
assert(isequaln(refValues,mappedValues))
% ByElements (the default, due to invalid specification)
[mappedValues{1:numOfOutArgs}] = uq_map(@funMatrix, inputs,...
    'MatrixMapping', 'BySomething');
assert(isequaln(refValues,mappedValues))

% ByRows
[refValues{1:numOfOutArgs}] = arrayfun(@(i) funMatrix(inputs(i,:)),...
    transpose(1:size(inputs,1)),...
    'UniformOutput', false, 'ErrorHandler', @errorHandler);
[mappedValues{1:numOfOutArgs}] = uq_map(@(x) funMatrix(x), inputs,...
    'MatrixMapping', 'ByRows');
assert(isequaln(refValues,mappedValues))

% ByColumns
[refValues{1:numOfOutArgs}] = arrayfun(@(i) funMatrix(inputs(:,i)),...
    1:size(inputs,2),...
    'UniformOutput', false, 'ErrorHandler', @errorHandler);
[mappedValues{1:numOfOutArgs}] = uq_map(@(x) funMatrix(x), inputs,...
    'MatrixMapping', 'ByColumns');
assert(isequaln(refValues,mappedValues))

% Test with parameter
Parameters.W = 1;
Parameters.All = 'all';

[refValues{1:numOfOutArgs}] = arrayfun(...
    @(x) funMatrix(x,Parameters), inputs,...
    'UniformOutput', false, 'ErrorHandler', @errorHandler);
% ByElements (as the default)
[mappedValues{1:numOfOutArgs}] = uq_map(@funMatrix, inputs,...
    'Parameters', Parameters);
assert(isequaln(refValues,mappedValues))
% ByElements (explicit specification)
[mappedValues{1:numOfOutArgs}] = uq_map(@funMatrix, inputs,...
    'Parameters', Parameters,...
    'MatrixMapping', 'ByElements');
assert(isequaln(refValues,mappedValues))
% ByElements (the default, due to invalid specification)
[mappedValues{1:numOfOutArgs}] = uq_map(@funMatrix, inputs,...
    'Parameters', Parameters,...
    'MatrixMapping', 'BySomething');
assert(isequaln(refValues,mappedValues))

% ByRows
[refValues{1:numOfOutArgs}] = arrayfun(@(i) funMatrix(inputs(i,:)),...
    transpose(1:size(inputs,1)),...
    'UniformOutput', false, 'ErrorHandler', @errorHandler);
[mappedValues{1:numOfOutArgs}] = uq_map(@(x) funMatrix(x), inputs,...
    'MatrixMapping', 'ByRows');
assert(isequaln(refValues,mappedValues))

% ByColumns
[refValues{1:numOfOutArgs}] = arrayfun(@(i) funMatrix(inputs(:,i)),...
    1:size(inputs,2),...
    'UniformOutput', false, 'ErrorHandler', @errorHandler);
[mappedValues{1:numOfOutArgs}] = uq_map(@(x) funMatrix(x), inputs,...
    'MatrixMapping', 'ByColumns');
assert(isequaln(refValues,mappedValues))

    function [output1,output2] = funMatrix(X,P)
        if nargin < 2
            P.W = 1;
            P.All = 'all';
        end
        if any(isnan(X),'all')
            error('NaN value.')
        end
        output1 = myStd(X, P.W, P.All);
        output2 = myMean(X,P.All);
    end

end


%% ------------------------------------------------------------------------
function varargout = errorHandler(varargin)

[varargout{1:nargout}] = deal(nan);

end


%% ------------------------------------------------------------------------
function output = customErrorHandler(S,varargin)

output.ME = S;
output.ArgIn = varargin;

end


%% ------------------------------------------------------------------------
function y = myMean(X,flag)

if strcmpi(flag,'all')
    y = mean(X(:));
else
    y = mean(X);
end

end


%% ------------------------------------------------------------------------
function y = myVar(X, w, flag)

if strcmpi(flag,'all')
    y = var(X(:),w);
else
    y = var(X,w);
end

end


%% ------------------------------------------------------------------------
function y = myStd(X, w, flag)

if strcmpi(flag,'all')
    y = sqrt(var(X(:),w));
else
    y = sqrt(var(X,w));
end

end
