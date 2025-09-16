function pass = uq_Dispatcher_tests_bash_parseFormat(level)
%UQ_DISPATCHER_TESTS_BASH_PARSEFORMAT tests parsing format
%
% Summary:
% Make sure that formatting string for data to string printing used in 
% uq_map with Linux command works.

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
    try 
        feval(testFunctions{i})
    catch e
        rethrow(e)
    end
end

%% Return the results
fprintf('PASS\n')

pass = true;

end

%%
function testEmpty

parsedFormat = uq_Dispatcher_bash_parseFormat('');

assert(isempty(parsedFormat))

end

%%
function testNoInput

parsedFormat = uq_Dispatcher_bash_parseFormat('echo');

assert(isempty(parsedFormat))

end

%%
function testWithInputNoFormat
command = 'echo {1}';

parsedFormat = uq_Dispatcher_bash_parseFormat(command);

assert(isempty(parsedFormat{1}))

end

%%
function testWithInputWithFormat
command = 'echo {1:%10s}';

parsedFormat = uq_Dispatcher_bash_parseFormat(command);

assert(ismember(parsedFormat,{'%10s'}))

end

%%
function testWithInputsNoFormat
command = 'echo {1} {2} {3}';

parsedFormat = uq_Dispatcher_bash_parseFormat(command);

assert(isempty(setdiff(parsedFormat,{'','',''})))

end

%%
function testWithInputsWithFormat
command = 'echo {1:%10.4f} {2:%s} {3:%g}';

parsedFormat = uq_Dispatcher_bash_parseFormat(command);

assert(isempty(setdiff(parsedFormat,{'%10.4f', '%s', '%g'})))

end

%%
function testSimpleWithRearrangedInputsNoFormat
command = 'echo {2} {3} {4} {1}';

parsedFormat = uq_Dispatcher_bash_parseFormat(command);

assert(isempty(setdiff(parsedFormat,{'', '', ''})))

end

%%
function testSimpleWithRearrangedInputsWithFormat
command = 'echo {2:%s} {3:%g} {4:%4.2f} {1:%10.8e}';

parsedFormat = uq_Dispatcher_bash_parseFormat(command);

assert(isempty(setdiff(parsedFormat,{'%10.8e', '%s', '%g', '%4.2f'})))

end