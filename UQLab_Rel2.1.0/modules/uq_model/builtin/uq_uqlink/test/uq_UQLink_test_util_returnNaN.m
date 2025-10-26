function pass = uq_UQLink_test_util_returnNaN(level)
%UQ_UQLINK_TEST_UTIL_RETURNNAN tests the utility function to return NaN
%   values of a given dimension.

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
function testSingleOutputSingleDimension()
% Test for a case of single scalar output.
Yref = {NaN};

% Set up
outputSize = 1;

Y = uq_UQLink_util_returnNaN(outputSize);

assert(isequaln(Y,Yref))

end


%% ------------------------------------------------------------------------
function testSingleOutputMultipleDimensions()
% Test for a case of a single output having multiple dimensions.
Yref = {[NaN NaN NaN NaN NaN]};

% Set up
outputSize = 5;

Y = uq_UQLink_util_returnNaN(outputSize);

% Assertion
assert(isequaln(Y,Yref))

end


%% ------------------------------------------------------------------------
function testMultipleOutputsSingleDimension()
% Test for a case of multiple outputs each having a single dimension.
Yref = {[NaN] [NaN] [NaN]};

% Set up
outputSizes = [1 1 1];

Y = uq_UQLink_util_returnNaN(outputSizes);

% Assertion
assert(isequaln(Y,Yref))

end


%% ------------------------------------------------------------------------
function testMultipleOutputsMultipleDimensions()
% Test for a case of multiple outputs having a multiple dimension.
Yref = {[NaN NaN] [NaN] [NaN NaN NaN NaN] [NaN NaN] [NaN NaN NaN NaN NaN]};

% Set up
outputSizes = [2 1 4 2 5];

Y = uq_UQLink_util_returnNaN(outputSizes);

% Assertion
assert(isequaln(Y,Yref))

end
