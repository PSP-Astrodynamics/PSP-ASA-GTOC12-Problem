function pass = uq_Dispatcher_tests_reduce_uq_empty_dispatcher(level)
%UQ_DISPATCHER_TESTS_UQ_REDUCE_UQ_EMPTY_DISPATCHER tests uq_reduce with
%   an empty DISPATCHER unit (local execution).

%% Initialize the test
if nargin < 1
    level = 'normal';
end

uqlab('-nosplash')

fprintf('Running: | %s | %s...', level, mfilename);

%% Get all local test functions
testFunctions = localfunctions;

%% Execute all the test functions
for i = 1:numel(testFunctions)
    feval(testFunctions{i})
end

%% Return the results
fprintf('PASS\n')

pass = true;

end


%% ------------------------------------------------------------------------
function testSimpleCellInput()
% A test for simple cell input.
inputs = {randi(10,1,100); randi(20,1,100); randi(5,1,100)};

refValues = intersect(intersect(inputs{1},inputs{2}),inputs{3});

reducedValues = uq_reduce(@intersect,inputs);
assert(isequal(refValues,reducedValues))

% With explicit 'none' parameter
reducedValues = uq_reduce(@intersect, inputs, 'Parameters', 'none');
assert(isequal(refValues,reducedValues))

end


%% ------------------------------------------------------------------------
function testNestedCellInput()
% A test for nested cell input.
inputs = {{2, 3}; {3, 2}; {4, 5}};

refValues = {inputs{1}{1} * inputs{2}{1} * inputs{3}{1},...
    inputs{1}{2} + inputs{2}{2} + inputs{3}{2}};

reducedValues = uq_reduce(@(x,y) {x{1}*y{1} x{2}+y{2}},inputs);
assert(isequal(refValues,reducedValues));

% With explicit 'none' parameter
reducedValues = uq_reduce(@(x,y) {x{1}*y{1} x{2}+y{2}}, inputs,...
    'Parameters', 'none');
assert(isequal(refValues,reducedValues));

end


%% ------------------------------------------------------------------------
function testStructArrayInput()
% A test for struct array input.
inputs(1).X = 2*rand(1,1000);
inputs(1).Y = 2*randn(1,1000);
inputs(2).X = 3*rand(1,1000);
inputs(2).Y = 3*randn(1,1000);
inputs(3).X = 4*rand(1,1000);
inputs(3).Y = 4*randn(1,1000);

refValues.X = inputs(1).X + inputs(2).X + inputs(3).X; 
refValues.Y = inputs(1).Y - inputs(2).Y - inputs(3).Y;

reducedValues = uq_reduce(@funStruct,inputs);
assert(isequal(refValues,reducedValues))

% With explicit 'none' parameter
reducedValues = uq_reduce(@funStruct, inputs, 'Parameters', 'none');
assert(isequal(refValues,reducedValues))

    function output = funStruct(S1,S2)
        output.X = S1.X + S2.X;
        output.Y = S1.Y - S2.Y;
    end

end


%% ------------------------------------------------------------------------
function testMatrixByElements()
% A test for matrix input.
inputs = [2*randi(5,1,100); randi(5,1,100); 3*randi(5,1,100)];
refValues = sum(sum(arrayfun(@mean,inputs)));
% Default
reducedValues = uq_reduce(@(x,y) mean(x) + mean(y),inputs);
assert(isequal(refValues,reducedValues));
% With explicit 'none' parameter
reducedValues = uq_reduce(@(x,y) mean(x) + mean(y), inputs,...
    'Parameters', 'none');
assert(isequal(refValues,reducedValues));

% Explicit specification
reducedValues = uq_reduce(@(x,y) mean(x) + mean(y), inputs,...
    'MatrixReduction', 'ByElements');
assert(isequal(refValues,reducedValues));
% With explicit 'none' parameter
reducedValues = uq_reduce(@(x,y) mean(x) + mean(y), inputs,...
    'MatrixReduction', 'ByElements', 'Parameters', 'none');
assert(isequal(refValues,reducedValues));

% Revert to Default due to invalid specification
warning('off')
reducedValues = uq_reduce(@(x,y) mean(x) + mean(y), inputs,...
    'MatrixReduction', 'BySomething');
warning('on')
assert(isequal(refValues,reducedValues));
% With explicit 'none' parameter
warning('off')
reducedValues = uq_reduce(@(x,y) mean(x) + mean(y), inputs,...
    'MatrixReduction', 'BySomething', 'Parameters', 'none');
warning('on')
assert(isequal(refValues,reducedValues));

end


%% ------------------------------------------------------------------------
function testMatrixByRows()
% A test for matrix as inputs with elements plucked by rows.
inputs = [2*randi(5,1,100); randi(5,1,100); 3*randi(5,1,100)];
refValues = mean(inputs(1,:)) + mean(inputs(2,:)) + mean(inputs(3,:));

reducedValues = uq_reduce(@(x,y) mean(x) + mean(y), inputs, ...
    'MatrixReduction', 'ByRows');
assert(isequal(refValues,reducedValues));

% With explicit 'none' parameter
reducedValues = uq_reduce(@(x,y) mean(x) + mean(y), inputs, ...
    'MatrixReduction', 'ByRows', 'Parameters', 'none');
assert(isequal(refValues,reducedValues));

end


%%-------------------------------------------------------------------------
function testMatrixByColumns()
% A test for matrix as inputs with elements plucked by columns.
inputs = randi(10, 20, 20);
refValues = sum(arrayfun(@(i) mean(inputs(:,i)), 1:size(inputs,2)));

reducedValues = uq_reduce(@(x,y) mean(x) + mean(y), inputs,...
    'MatrixReduction', 'ByColumns');
assert(isequal(refValues,reducedValues));

% With explicit 'none' parameter
reducedValues = uq_reduce(@(x,y) mean(x) + mean(y), inputs, ...
    'MatrixReduction', 'ByColumns', 'Parameters', 'none');
assert(isequal(refValues,reducedValues));

end


%% ------------------------------------------------------------------------
function testParameter2()
% A test for cell array as input with a parameter.
A = randi(10, 100, 100);
B = randi(10, 100, 100);
C = randi(10, 100, 100);
A(20,:) = 1:100;
B(20,:) = 1:100;
C(20,:) = 1:100;

inputs = {A; B; C};

refValues = intersect(intersect(inputs{1},inputs{2},'rows'),inputs{3},'rows');
parameter = 'rows';
reducedValues = uq_reduce(@intersect, inputs, 'Parameters', parameter);

assert(isequal(refValues,reducedValues));

end


%% ------------------------------------------------------------------------
function testExplicitEmptyParameter()
% A test for passing an explicit empty parameter.
inputs = randi(10,1,20);

refValues = inputs(1) - sum(inputs(2:end));
reducedValues = uq_reduce(@testFunc, inputs, 'Parameters', []);

assert(isequal(refValues,reducedValues));

    function Z = testFunc(X, Y, P)
        if isempty(P)
            Z = X - Y;
        else
            Z = X + Y;
        end
    end

end


%% ------------------------------------------------------------------------ 
function testInitMatrixByElements()
% A test for matrix as inputs with initial value.
inputs = magic(10);
refValues = -100 + sum(sum(inputs));

% Default
reducedValues = uq_reduce(@(x,y) x + y, inputs, 'InitialValue', -100);
assert(isequal(refValues,reducedValues));
% Explicit specification
reducedValues = uq_reduce(@(x,y) x + y, inputs,...
    'InitialValue', -100, 'MatrixReduction', 'ByElements');
assert(isequal(refValues,reducedValues));
% Revert to default due to invalid specification
warning('off')
reducedValues = uq_reduce(@(x,y) x + y, inputs,...
    'InitialValue', -100, 'MatrixReduction', 'BySomething');
warning('on')
assert(isequal(refValues,reducedValues));

end


%% ------------------------------------------------------------------------
function testInitMatrixByRows()
% A test for matrix as inputs with elements plucked by rows
% and initial value.
inputs = magic(10);

refValues = -100 + sum(inputs,1);
reducedValues = uq_reduce(@(x,y) x + y, inputs,...
    'InitialValue', -100, 'MatrixReduction', 'ByRows');

assert(isequal(refValues,reducedValues));

end


%% ------------------------------------------------------------------------
function testInitMatrixByColumns()
% A test for matrix as inputs with elements plucked by columns
% and initial value.
inputs = randi(5, 30, 30);

refValues = -100 + sum(inputs,2);
reducedValues = uq_reduce(@(x,y) x + y, inputs,...
    'InitialValue', -100, 'MatrixReduction', 'ByColumns');

assert(isequal(refValues,reducedValues));

end


%% ------------------------------------------------------------------------
function testInitSimpleCell()
% A test for passing an initial value with simple cell as input.
inputs = {linspace(1,10); linspace(1,10); linspace(1,10)};

initialValue = 10;
refValues = initialValue + sum(inputs{1}) + sum(inputs{2}) + sum(inputs{3});
reducedValues = uq_reduce(@(x,y) x + sum(y), inputs, 'InitialValue', initialValue);

assert(isequal(refValues,reducedValues))

end


%% ------------------------------------------------------------------------
function testInitNestedCell()
% A test for passing an initial value with nested cell as input.
inputs = {{randi(5,1,100), randi(10,1,100)};...
    {randi(10,1,100), randi(15,1,100)};...
    {randi(15,1,100), randi(20,1,100)}};

initialValue = [];
refValues = union(...
    union(...
        union(initialValue,intersect(inputs{1}{1},inputs{1}{2})),...
        intersect(inputs{2}{1},inputs{2}{2})),...
    intersect(inputs{3}{1},inputs{3}{2}));
reducedValues = uq_reduce(@(x,y) union(x,intersect(y{1},y{2})), inputs,...
    'InitialValue', initialValue);

assert(isequal(refValues,reducedValues))

end


%% ------------------------------------------------------------------------
function testInitStruct()
% A test for passing an initial value with struct array as input.
inputs(1).X = 2*rand(1,1000);
inputs(1).Y = 2*randn(1,1000);

initialValue.X = rand(1,1000);
initialValue.Y = randn(1,1000);
refValues.X = initialValue.X + inputs(1).X; 
refValues.Y = initialValue.Y - inputs(1).Y;
reducedValues = uq_reduce(@funStruct,inputs,'InitialValue',initialValue);

    function output = funStruct(S1,S2)
        output.X = S1.X + S2.X;
        output.Y = S1.Y - S2.Y;
    end

assert(isequal(refValues,reducedValues))

end


%% ------------------------------------------------------------------------
function testInvalidInput()
% A test for using an invalid input (should throw an error).
inputs = {1};
initialValue = {1};

try
    uq_reduce(@(x,y) x + y, inputs, 'InitialValue', initialValue);
    assert(false)
catch
    assert(true)
end

end


%% ------------------------------------------------------------------------
function testIdentitySimpleCell()
% A test for identity case of single element input with a simple cell as
% the input (should return that single element).
inputs = {1};

reducedValues = uq_reduce(@(x,y) x+y, inputs);

assert(isequal(inputs{1},reducedValues))

end


%% ------------------------------------------------------------------------
function testIdentityNestedCell()
% A test for identity case of single element input with a nested cell as
% the input (should return that single element).
inputs = {{randi(10,10,10)}};

reducedValues = uq_reduce(@(x,y) x+y, inputs);

assert(isequal(inputs{1},reducedValues))

end


%% ------------------------------------------------------------------------
function testIdentityStruct()
% A test for identity case of single element input with a struct array as
% the input (should return that single element).
inputs(1).X = 10;
inputs(1).Y = 'a';

reducedValues = uq_reduce(@(x,y) x+y, inputs);

assert(isequal(inputs,reducedValues))

end


%% ------------------------------------------------------------------------
function testIdentityMatrixByElements()
% A test for identity case of single element input with a matrix as the
% input (should return that single element)
inputs = randi(10, 1, 1);

% Default
reducedValues = uq_reduce(@(x,y) x+y, inputs);
assert(isequal(inputs,reducedValues))
% Explicit specification
reducedValues = uq_reduce(@(x,y) x+y, inputs,...
    'MatrixReduction', 'ByElements');
assert(isequal(inputs,reducedValues))
% Revert to default due to invalid specification
warning('off')
reducedValues = uq_reduce(@(x,y) x+y, inputs,...
    'MatrixReduction', 'BySomething');
warning('on')
assert(isequal(inputs,reducedValues))

end


%% ------------------------------------------------------------------------
function testIdentityMatrixByRows()
% A test for identity case of single element input w/ a matrix as input
% with the elements plucked by rows (should return that single element)

inputs = randi(10, 1, 10);

reducedValues = uq_reduce(@(x,y) x+y, inputs, 'MatrixReduction', 'ByRows');

assert(isequal(inputs,reducedValues))

end


%% ------------------------------------------------------------------------
function testIdentityMatrixByColumns()
% A test for identity case of single element input w/ a matrix as input
% with the elements plucked by columns (should return that single element)

inputs = randi(10,10,1);

reducedValues = uq_reduce(@(x,y) x+y, inputs,...
    'MatrixReduction', 'ByColumns');

assert(isequal(inputs,reducedValues))

end


%% ------------------------------------------------------------------------
function testZeroLengthSimpleCell()
% A test for using a zero-length simple cell as input without initial value
% (should throw an error).
inputs = {};

try
    uq_reduce(@(x,y) x + y, inputs);
    assert(true)
catch ME
    assert(strcmp(ME.message,...
        'inputs are empty and no initial value is provided.'))
end

end


%% ------------------------------------------------------------------------
function testZeroLengthSimpleCellInitialValue()
% A test for using a zero-length simple cell as input w/ initial value.
inputs = {};

initialValue = 10;
reducedValues = uq_reduce(@(x,y) x + y, inputs, 'InitialValue', initialValue);

assert(isequal(initialValue,reducedValues))

end


%% ------------------------------------------------------------------------
function testZeroLengthMatrix()
% A test for using a zero-length matrix as input w/o initial value.
inputs = [];

try
    uq_reduce(@(x,y) x + y, inputs);
    assert(true)
catch ME
    assert(strcmp(ME.message,...
        'inputs are empty and no initial value is provided.'))
end

end


%% ------------------------------------------------------------------------
function testZeroLengthMatrixInitialValue()
% A test for using a zero-length matrix as input w/ initial value.
inputs = [];

initialValue = 10;
reducedValues = uq_reduce(@(x,y) x + y, inputs, 'InitialValue', initialValue);

assert(isequal(initialValue,reducedValues))

end

%% ------------------------------------------------------------------------
function testZeroLengthMatrixByRowsInitialValue()
% A test for using a zero-length matrix (elements plucked by rows)
% as input w/ initial value.
inputs = [];

initialValue = 10;
reducedValues = uq_reduce(@(x,y) x + y, inputs,...
    'InitialValue', initialValue, 'MatrixReduction', 'ByRows');

assert(isequal(initialValue,reducedValues))

end

%% ------------------------------------------------------------------------
function testZeroLengthMatrixByColumnsInitialValue()
% A test for using a zero-length matrix (elements plucked by columns)
% as input w/ initial value.
inputs = [];

initialValue = 10;
reducedValues = uq_reduce(@(x,y) x + y, inputs,...
    'InitialValue', initialValue, 'MatrixReduction', 'ByColumns');

assert(isequal(initialValue,reducedValues))

end


%% ------------------------------------------------------------------------
function testZeroLengthStruct()
% A test for using a zero-length struct array as input w/o initial value.
inputs = struct();

try
    uq_reduce(@(x,y) x + y, inputs);
    assert(true)
catch ME
    assert(strcmp(ME.message,...
        'inputs are empty and no initial value is provided.'))
end

end


%% ------------------------------------------------------------------------
function testZeroLengthStructInitialValue()
% A test for using a zero-length struct array as input w/ initial value.
inputs = struct();

initialValue.X = 10;
initialValue.Y = 20;
reducedValues = uq_reduce(@(x,y) x + y, inputs,...
    'InitialValue', initialValue);

assert(isequal(initialValue,reducedValues))

end
