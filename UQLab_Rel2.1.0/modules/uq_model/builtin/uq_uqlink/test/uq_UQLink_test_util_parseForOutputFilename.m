function pass = uq_UQLink_test_util_parseForOutputFilename(level)
%UQ_UQLINK_TEST_UTIL_PARSEFOROUTPUTFILENAME 

%% Initialize test
if nargin < 1
    level = 'normal';
end

uqlab('-nosplash')

fprintf('\nRunning: | %s | %s...\n', level, mfilename);

%% Get all local test functions
testFunctions = localfunctions;

%% Execute all test functions
for i = 1:numel(testFunctions)
    feval(testFunctions{i})
end

pass = true;

end

%% ------------------------------------------------------------------------
function testNoOutput()
% Test for a case without outputfilename
refChar = 'input=myInput.inp; data=myData.lib';

% Set up case
outputFilename = {'output'};
runIdx = 15;
runIdxDigitFormat = strcat('%0', num2str(6), 'u');

% Parse output filename
[outChar,outNotFound] = uq_UQLink_util_parseForOutputFilename(...
    refChar, outputFilename, runIdx, runIdxDigitFormat);

% Assertion
assert(strcmp(outChar,refChar))
assert(outNotFound)

end


%% ------------------------------------------------------------------------
function testSimpleCase()
% Test for a simple case.
refChar = 'output000015.out';

% Set up case
inpChar = 'output.out';
outputFilename = {'output'};
runIdx = 15;
runIdxDigitFormat = strcat('%0', num2str(6), 'u');

% Parse output filename
[outChar,outNotFound] = uq_UQLink_util_parseForOutputFilename(...
    inpChar, outputFilename, runIdx, runIdxDigitFormat);

% Assertion
assert(strcmp(outChar,refChar))
assert(~outNotFound)

end


%% ------------------------------------------------------------------------
function testComplexCase1()
% Test for a more complex case.
refChar = 'outputFile = outputfilename101.dat';

% Set up case
inpChar = 'outputFile = outputfilename.dat';
outputFilename = {'outputfilename'};
runIdx = 101;
runIdxDigitFormat = strcat('%0', num2str(3), 'u');

% Parse output filename
[outChar,outNotFound] = uq_UQLink_util_parseForOutputFilename(...
    inpChar, outputFilename, runIdx, runIdxDigitFormat);

% Assertion
assert(strcmp(outChar,refChar))
assert(~outNotFound)

end


%% ------------------------------------------------------------------------
function testComplexCase2()
% Test for a more complex case.
refChar = 'data = ''myData.lib''; output = ''myOutput3215''';

% Set up case
inpChar = 'data = ''myData.lib''; output = ''myOutput''';
outputFilename = {'myOutput'};
runIdx = 3215;
runIdxDigitFormat = strcat('%0', num2str(4), 'u');

% Parse output filename
[outChar,outNotFound] = uq_UQLink_util_parseForOutputFilename(...
    inpChar, outputFilename, runIdx, runIdxDigitFormat);

% Assertion
assert(strcmp(outChar,refChar))
assert(~outNotFound)

end
