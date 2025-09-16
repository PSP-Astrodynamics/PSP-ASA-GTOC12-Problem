function pass = uq_Dispatcher_tests_util_flattenCell(level)

%% Initialize test
if nargin < 1
    level = 'normal';
end

uqlab('-nosplash')

fprintf('Running: | %s | %s...', level, mfilename);

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
function testSimpleCase
refC = {1; 2; 3; 4; 5};

C = {{1,2}, {{3,4}}, 5};

assert(isequal(uq_Dispatcher_util_flattenCell(C),refC))

end

%% ------------------------------------------------------------------------
function testComplexCase
refC = {'123'; 'abc'; 'def'; 'hij'; 'abc1'};

C = {'123', 'abc', 'def', {'hij'}, {{{{'abc1'}}}}};

assert(isequal(uq_Dispatcher_util_flattenCell(C),refC))

end

