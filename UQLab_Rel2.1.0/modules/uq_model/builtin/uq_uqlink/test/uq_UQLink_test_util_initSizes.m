function pass = uq_UQLink_test_util_initSizes(level)
%UQ_UQLINK_TEST_UTIL_INITSIZES tests the utility function to initialize
%   size of each element in a cell array.

%% Initialize test
if nargin < 1
    level = 'normal';
end

uqlab('-nosplash')

fprintf('Running: | %s | %s...\n', level, mfilename);

%% Get all local test functions
testFunctions = localfunctions;

%% Execute all test functions
for i = 1:numel(testFunctions)
    feval(testFunctions{i})
end

pass = true;

end


%% ------------------------------------------------------------------------
function testDefaultArguments()
% Test case for default arguments.

refSize = 1;

initSize = uq_UQLink_util_initSizes();

%% Assert
assert(isequal(initSize,refSize))

end


%% ------------------------------------------------------------------------
function testSingleColumn()
% Test case for single column.

refSize = 1;

% Set up test case
numCols = 1;

initSize = uq_UQLink_util_initSizes(numCols);

% Assert
assert(isequal(initSize,refSize))

end


%% ------------------------------------------------------------------------
function testMultipleColumns()
% Test case for multiple columns.

% Set up test case
numOfOutArgs = 100;

refSizes = ones(1,numOfOutArgs);

initSizes = uq_UQLink_util_initSizes(numOfOutArgs);

% Assert
assert(isequal(initSizes,refSizes))

end


%% ------------------------------------------------------------------------
function testGivenYSingleColumn()
% Test case for given Y, multiple elements @ single column.

% Set up test case
numOfOutArgs = 5;

refSizes = [1 1 1 1 1];
Y = {rand(1) rand(1) rand(1) rand(1) rand(1)};

initSizes = uq_UQLink_util_initSizes(numOfOutArgs,Y);

% Assert
assert(isequal(initSizes,refSizes))

end


%% ------------------------------------------------------------------------
function testOtherGivenYMultipleColumns()
% Test case for given Y, multiple elements @ different number of columns.

% Set up test case
numOfOutArgs = 5;

refSizes = [1 2 10 1 7];
Y = {rand(1) rand(1,2) rand(1,10) rand(1) rand(1,7)};

initSizes = uq_UQLink_util_initSizes(numOfOutArgs,Y);

% Assert
assert(isequal(initSizes,refSizes))

end


%% ------------------------------------------------------------------------
function testGivenYSelectedColumns()
% Test case for given Y, selected elements.

% Set up test case
numOfOutArgs = 3;

refSizes = [1 2 10];
Y = {rand(1) rand(1,2) rand(1,10) rand(1) rand(1,7)};

initSizes = uq_UQLink_util_initSizes(numOfOutArgs,Y);

% Assert
assert(isequal(initSizes,refSizes))

end
