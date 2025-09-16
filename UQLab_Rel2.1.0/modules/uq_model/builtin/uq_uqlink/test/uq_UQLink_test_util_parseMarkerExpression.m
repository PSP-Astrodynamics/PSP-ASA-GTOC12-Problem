function pass = uq_UQLink_test_util_parseMarkerExpression(level)
%UQ_UQLINK_TEST_UTIL_PARSEMARKEREXPRESSION Summary of this function goes here
%   Detailed explanation goes here
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
function testSimpleExpression()
% Test for a simple expression with a single variable.
refChar = '20';

% Set up the test
inpChar = '<sqrt(X0004)>';
values = [1.0 2.0 -3.5 4e2 7.2691];
marker{1} = '<';
marker{2} = 'X';
marker{3} = '>';
fmtChar = {'%4.2f'};

outChar = uq_UQLink_util_parseMarkerExpression(inpChar,values,marker,fmtChar);

assert(strcmp(outChar,refChar))

end

%% ------------------------------------------------------------------------
function testSimpleExpressionMultipleVariables()
% Test for a simple expression with multiple variables.
refChar = '-0.6309';

% Set up the test
inpChar = '<X0005 + 5 * X0006>';
values = [1.0 2.0 -3.5 4e2 7.2691 -1.58];
marker{1} = '<';
marker{2} = 'X';
marker{3} = '>';
fmtChar = {'%8.6f'};

outChar = uq_UQLink_util_parseMarkerExpression(inpChar,values,marker,fmtChar);

assert(strcmp(outChar,refChar))

end

%% ------------------------------------------------------------------------
function testComplexExpression()
% Test for a complex expression.
refChar = '7.5';

% Set up the test
inpChar = '<<abs(X0003) + mod(X0001,X0002)>>';
values = [10 6 -3.5 4e2];
marker{1} = '<<';
marker{2} = 'X';
marker{3} = '>>';
fmtChar = {'%2d', '%1d', '%8.6f', '%12.6e'};

outChar = uq_UQLink_util_parseMarkerExpression(inpChar,values,marker,fmtChar);

assert(strcmp(outChar,refChar))

end

%% ------------------------------------------------------------------------
function testMixed()
%%   (mix, change what's needed) % L in m
refChar = 'lat <Y0001>  <Y0002>  7.5 <Y0003>';

% Set up the test
inpChar = 'lat <Y0001>  <Y0002>  <abs(Y0003) + mod(Y0001,Y0002)> <Y0003>';
values = [10 6 -3.5 4e2];
marker{1} = '<';
marker{2} = 'Y';
marker{3} = '>';
fmtChar = {'%2d', '%1d', '%8.6f', '%12.6e'};

outChar = uq_UQLink_util_parseMarkerExpression(inpChar,values,marker,fmtChar);

assert(strcmp(outChar,refChar))

end

%% ------------------------------------------------------------------------
function testMultipleExpressions()
%% Multiple Expression
refChar = '404  4 20 <Z0003>';

% Set up the test
inpChar = '<abs(Z0004) + mod(Z0001,Z0002)>  <mod(Z0001,Z0002)> <sqrt(Z0003)> <Z0003>';
values = [10 6 4e2 -4e2];
marker{1} = '<';
marker{2} = 'Z';
marker{3} = '>';
fmtChar = {'%2d', '%1d', '%12.6e', '%12.6e'};

outChar = uq_UQLink_util_parseMarkerExpression(inpChar,values,marker,fmtChar);

assert(strcmp(outChar,refChar))

end

%% ------------------------------------------------------------------------
function testSimpleMarkerSingle()
% Test for a single simple marker (nothing should happen)
refChar = '<X0001> % p in [Pa]';

% Set up the test
values = [1.0 2.0 -3.5 4e2 7.2691];
marker{1} = '<';
marker{2} = 'X';
marker{3} = '>';
fmtChar = {'%4.2f'};

outChar = uq_UQLink_util_parseMarkerExpression(...
    refChar, values, marker, fmtChar);

assert(strcmp(outChar,refChar))

end

%% ------------------------------------------------------------------------
function testSimpleMarkerMultiple()
% Test for multiple simple markers (nothing should happen).
refChar = '<X0001> <X0002> <X0003> % b in m';

% Set up the test
values = [1 2 3];
marker{1} = '<';
marker{2} = 'X';
marker{3} = '>';
fmtChar = {'%4.2f'};

outChar = uq_UQLink_util_parseMarkerExpression(...
    refChar, values, marker, fmtChar);

assert(strcmp(outChar,refChar))

end
