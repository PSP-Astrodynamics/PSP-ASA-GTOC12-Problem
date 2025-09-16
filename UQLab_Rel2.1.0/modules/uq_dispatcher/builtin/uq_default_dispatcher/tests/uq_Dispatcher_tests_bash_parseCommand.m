function pass = uq_Dispatcher_tests_bash_parseCommand(level)
% pass = UQ_KRIGING_TEST_CONSTANT(LEVEL): non-regression test for the
% constants support in the Kriging module
%
% Summary:
% Make sure that various Kriging configurations are working as expected
% when using constants in some of the input components

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

%%
function testEmpty
refChar = '"$@"';

parsedCommand = uq_Dispatcher_bash_parseCommand('');

assert(strcmp(parsedCommand,refChar))

end

%%
function testEmptyWithInput
refChar = '${1}';

parsedCommand = uq_Dispatcher_bash_parseCommand('',1);

assert(strcmp(parsedCommand,refChar))

end

function testEmptyWithInputs
refChar = '${1} ${2} ${3} ${4} ${5} ${6} ${7} ${8} ${9} ${10} ${11} ${12}';

parsedCommand = uq_Dispatcher_bash_parseCommand('',12);

assert(strcmp(parsedCommand,refChar))

end

%%

function testSimpleNoInput
refChar = 'echo "$@"';

parsedCommand = uq_Dispatcher_bash_parseCommand('echo');

assert(strcmp(parsedCommand,refChar))

end

%%
function testSimpleWithInput
refChar = 'echo ${1}';

parsedCommand = uq_Dispatcher_bash_parseCommand('echo',1);

assert(strcmp(parsedCommand,refChar))

end

function testSimpleWithInputs
refChar = 'echo ${1} ${2} ${3} ${4} ${5}';

parsedCommand = uq_Dispatcher_bash_parseCommand('echo',5);

assert(strcmp(parsedCommand,refChar))

end

function testComplexNoFormat
refChar = 'echo ${1} ${2} ${3} ${4}';

parsedCommand = uq_Dispatcher_bash_parseCommand('echo {1} {2} {3} {4}');

assert(strcmp(parsedCommand,refChar))

end


function testComplexNoFormatAlreadyWithNumbers
refChar = 'echo 1 2 3 4 ${1} ${2} ${3} ${4}';

parsedCommand = uq_Dispatcher_bash_parseCommand(...
    'echo 1 2 3 4 {1} {2} {3} {4}');

assert(strcmp(parsedCommand,refChar))

end



function testComplexNoFormatRearrangeInputs
refChar = 'echo ${4} ${2} ${3} ${1}';

parsedCommand = uq_Dispatcher_bash_parseCommand('echo {4} {2} {3} {1}');

assert(strcmp(parsedCommand,refChar))

end

function testComplexWithFormat
refChar = 'echo ${1} | ls ${2} | runthis ${3} ${4}';

parsedCommand = uq_Dispatcher_bash_parseCommand(...
    'echo {1} | ls {2:%g} | runthis {3:%s} {4:%s}');

assert(strcmp(parsedCommand,refChar))

end

function testComplexWithFormatRearrangeInputs
refChar = 'echo ${4} | ls ${1} | runthis ${3} ${2}';

parsedCommand = uq_Dispatcher_bash_parseCommand(...
    'echo {4} | ls {1:%g} | runthis {3:%s} {2:%s}');

assert(strcmp(parsedCommand,refChar))

end


%%
function testComplexWithFormatRearrangeInputsAlreadyWithNumbers
refChar = 'echo 4 ${4} | ls 1 ${1} | runthis 3 2 ${3} ${2}';

parsedCommand = uq_Dispatcher_bash_parseCommand(...
    'echo 4 {4} | ls 1 {1:%g} | runthis 3 2 {3:%s} {2:%s}');

assert(strcmp(parsedCommand,refChar))

end


% parseCommand test cases
% 'echo' -> 'echo', if numinputs == 0 
% 'echo $1 $2 ... $n', if numinputs == n
% 'echo {1} | ls {3:%g} | runthis {2:%s} {4:%s}' -> echo $1 | ls $3 |
% runthis $2 $4
% '' -> '', if numinputs == 0
% '' -> '$1 $2 ... $n', if numinputs == n
% 'echo {1} | ls {3} | runthis {2} {4}' -> echo $1 | ls $3 |
% runthis $2 $4

% parseFormat test cases
% 1. 'echo' => [] (empty)
% 2. 'echo {1} | ls {3} | runthis {2} {4}' => [] (empty)
% 3. 'echo {1} | ls {3:%g} | runthis {2:%s} {4:%s}' => {[], '%s', '%g', '%s')

% wrapCommand test cases
% 1. command == 'echo'
%    output:
%    '#!/bin/bash
%    'echo'
% 2. command == 'echo $1 $2 $3'
%    output:
%    '#!/bin/bash
%    'echo $1 $2 $3'
% 3. command == 'echo $1 | ls $3 | runthis $2 $4'
%    output:
%    '#!/bin/bash
%    'echo $1 | ls $3 | runthis $2 $4'
% 4. command == ''
%    output:
%    '#!/bin/bash'
%    ''