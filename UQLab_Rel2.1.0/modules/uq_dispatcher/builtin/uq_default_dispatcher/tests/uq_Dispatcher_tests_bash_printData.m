function pass = uq_Dispatcher_tests_bash_printData(level)
%UQ_DISPATCHER_TESTS_BASH_PRINTINPUTnon-regression test for the
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

%% ------------------------------------------------------------------------
function testEmptyInput
refChar = '';

formattedInput = uq_Dispatcher_bash_printData('');

assert(strcmp(formattedInput,refChar))

end

%% ------------------------------------------------------------------------
function testScalarInputNoFormatting
refChar = '1000';

formattedInput = uq_Dispatcher_bash_printData(10e2);

assert(strcmp(formattedInput,refChar))

end

%%
function testScalarInputWithFormatting
refChar = '1.00e+02';

formattedInput = uq_Dispatcher_bash_printData(100,'%6.2e');

assert(strcmp(formattedInput,refChar))

end


%%
function testArrayInputNoFormatting
refChar = '3 2 1';

formattedInput = uq_Dispatcher_bash_printData([3 2 1]);

assert(strcmp(formattedInput,refChar))

end

%%
function testArrayInputEmptyFormatting
refChar = '7 8 9 10';

formattedInput = uq_Dispatcher_bash_printData([7; 8; 9; 10],'');

assert(strcmp(formattedInput,refChar))

end

%%
function testArrayInputEmptyCellFormatting
refChar = '7 8 9 10';

formattedInput = uq_Dispatcher_bash_printData([7 8 9 10],{});

assert(strcmp(formattedInput,refChar))

end

%%
function testArrayInputAllEmptyCellFormatting
refChar = '7 8 9 10';

formattedInput = uq_Dispatcher_bash_printData([7 8 9 10],{'';'';'';''});

assert(strcmp(formattedInput,refChar))

end

%%
function testArrayInputWithFormatting
refChar = '7.000 8.00e+00 +9 10';

formattedInput = uq_Dispatcher_bash_printData([7 8 9 10],...
    {'%5.3f', '%7.2e', '%+d', ''});

assert(strcmp(formattedInput,refChar))

end

%%
function testCellInputNoFormatting
refChar = '12 14 -5 150';

formattedInput = uq_Dispatcher_bash_printData({12.0, 14.0, -5.0, 1.5e2});

assert(strcmp(formattedInput,refChar))

end

%%
function testCellInputWithFormatting
refChar = '   12.0000 1.400e+01 150 +15';

formattedInput = uq_Dispatcher_bash_printData({12.0, 14.0, 1.5e2, 15},...
    {'%10.4f'; '%5.3e'; ''; '%+d'});

assert(strcmp(formattedInput,refChar))

end

%%
function testCellInputWithFancyFormatting
refChar = 'foo.txt bar.inp    0015';

formattedInput = uq_Dispatcher_bash_printData({'foo.txt'; 'bar.inp'; 15},...
    {'%s'; '%-10s'; '%04d'});

assert(strcmp(formattedInput,refChar))

end
