function pass = uq_Dispatcher_tests_util_isAsync(level)
%UQ_DISPATCHER_TESTS_UTIL_ISASYNC tests the conversion of execution mode
%   (a char) to a isAsync flag (a logical).

%% Initialize the test
if nargin < 1
    level = 'normal';
end

uqlab('-nosplash')

fprintf('Running: | %s | %s...', level, mfilename)

%% Get all local test functions
testFunctions = localfunctions;

%% Execute all test functions
for i = 1:numel(testFunctions)
    feval(testFunctions{i})
end

%% Return the results
fprintf('PASS\n')

pass = true;

end


%% ------------------------------------------------------------------------
function testAsync()
% A test with 'async'.
isAsync = uq_Dispatcher_util_isAsync('async');

assert(isAsync)

end


%% ------------------------------------------------------------------------
function testASYNC()
% A test with 'ASYNC' (the function should work without case sensitivity).
isAsync = uq_Dispatcher_util_isAsync('ASYNC');

assert(isAsync)

end


%% ------------------------------------------------------------------------
function testSync()
% A test with 'sync'.
isAsync = uq_Dispatcher_util_isAsync('sync');

assert(~isAsync)

end


%% ------------------------------------------------------------------------
function testSYNC()
% A test with 'SYNC' (the function should work without case sensitivity).
isAsync = uq_Dispatcher_util_isAsync('SYNC');

assert(~isAsync)

end


%%
function testUnsupported()
% A test for non-supported execution mode (should throw an error).

try
    uq_Dispatcher_util_isAsync('synchronized');
    error('Execution mode is either ''sync'' or ''async''.') 
catch
    return
end

end
