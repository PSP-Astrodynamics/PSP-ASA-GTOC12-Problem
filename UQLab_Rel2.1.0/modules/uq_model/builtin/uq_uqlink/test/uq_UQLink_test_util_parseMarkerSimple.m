function pass = uq_UQLink_test_util_parseMarkerSimple(level)
%UQ_DISPATCHER_TEST_UTIL_PARSEMARKERSIMPLE
%
%   Summary:
%   
%


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
function testSingleMarker()
% Test for a single marker and a single formatting char.
refChar = '1.00';

% Set up the test
inputChar = '<X0001>';
values = [1.0 2.0 -3.5 4e2 7.2691];
marker{1} = '<';
marker{2} = 'X';
marker{3} = '>';
fmtChar = {'%4.2f'};

outputChar = uq_UQLink_util_parseMarkerSimple(...
    inputChar, values, marker, fmtChar);

assert(strcmp(outputChar,refChar))

end

%% ------------------------------------------------------------------------
function testSingleMarkerDiffCol()
% Test for a single marker with value from different column.
refChar = '7.27';

% Set up the test
inputChar = '<X0005>';
values = [1.0 2.0 -3.5 4e2 7.2691];
marker{1} = '<';
marker{2} = 'X';
marker{3} = '>';
fmtChar = {'%4.2f'};

outputChar = uq_UQLink_util_parseMarkerSimple(...
    inputChar, values, marker, fmtChar);

assert(strcmp(outputChar,refChar))

end

%% ------------------------------------------------------------------------
function testSingleMarkerDiffKey()
% Test for a single marker with different char-key in the marker.
refChar = '4.000000e+02';

% Set up the test
inputChar = '<Z0004>';
values = [1.0 2.0 -3.5 4e2 7.2691];
marker{1} = '<';
marker{2} = 'Z';
marker{3} = '>';
fmtChar = {'%12.6e'};

outputChar = uq_UQLink_util_parseMarkerSimple(...
    inputChar, values, marker, fmtChar);

assert(strcmp(outputChar,refChar))

end

%% ------------------------------------------------------------------------
function testMultipleMarkersSingleFormat()
% Test for multiple markers with a single formatting char.
refChar = '1.0 7.3 -3.5 2.0';

% Set up the test
inputChar = '<X0001> <X0005> <X0003> <X0002>';
values = [1.0 2.0 -3.5 4e-2 7.291];
marker{1} = '<';
marker{2} = 'X';
marker{3} = '>';
fmtChar = {'%4.1f'};

outputChar = uq_UQLink_util_parseMarkerSimple(...
    inputChar, values, marker, fmtChar);

assert(strcmp(outputChar,refChar))

end

function testMultipleMarkersMultipleFormats()
% Test for multiple markers with multiple formatting chars.
refChar = '1.00 7.3 -3.500 4.000e+02';

% Set up the test
inputChar = '<y0001> <y0005> <y0003> <y0004>';
values = [1.0 2.0 -3.5 4e2 7.2691];
marker{1} = '<';
marker{2} = 'y';
marker{3} = '>';
fmtChar = {'%4.2f', '%4.2f', '%4.3f', '%9.3e', '%3.1f'};

outputChar = uq_UQLink_util_parseMarkerSimple(...
    inputChar, values, marker, fmtChar);

assert(strcmp(outputChar,refChar))

end

%% ------------------------------------------------------------------------
function testComplexSingleMarker()
% Test for a more complex case with single marker
refChar = 'GAIN=7.2691';

% Set up the test
inputChar = 'GAIN=<X0005>';
values = [1.0 2.0 -3.5 4e2 7.2691];
marker{1} = '<';
marker{2} = 'X';
marker{3} = '>';
fmtChar = {'%6.4f'};

outputChar = uq_UQLink_util_parseMarkerSimple(...
    inputChar, values, marker, fmtChar);

assert(strcmp(outputChar,refChar))

end

%% ------------------------------------------------------------------------
function testComplexMultipleMarkers()
% Test for a more complex case with multiple markers.
refChar = 'lat 1.000000E+00  2.500000E+00  0.0 0.0 12 12 1.000000E-04';

% Set up the test
inputChar = 'lat <X0001>  <X0002>  0.0 0.0 12 12 <X0003>';
values = [1.0 2.5 1.0e-4 4e2 7.2691];
marker{1} = '<';
marker{2} = 'X';
marker{3} = '>';
fmtChar = {'%1.6E'};

outputChar = uq_UQLink_util_parseMarkerSimple(...
    inputChar, values, marker, fmtChar);

assert(strcmp(outputChar,refChar))

end

%% ------------------------------------------------------------------------
function testExpressionSimple()
% Test for a simple expression marker (nothing should happen)
refChar = 'test <X0005 + 5 * X0006> lat surf';

% Set up the test
values = [1.0 2.0 -3.5 4e2 7.2691];
marker{1} = '<';
marker{2} = 'X';
marker{3} = '>';
fmtChar = {'%12.6e'};

outputChar = uq_UQLink_util_parseMarkerSimple(...
    refChar, values, marker, fmtChar);

assert(strcmp(outputChar,refChar))

end

%% ------------------------------------------------------------------------
function testExpressionComplex()
% Test for a complex expression marker case (nothing should happen)
refChar = 'lat surf <abs(X0003) + mod(X0001,X0002)>';

% Set up the test
values = [1.0 2.0 -3.5 4e2 7.2691];
marker{1} = '<';
marker{2} = 'X';
marker{3} = '>';
fmtChar = {'%12.6e'};

outputChar = uq_UQLink_util_parseMarkerSimple(...
    refChar, values, marker, fmtChar);

assert(strcmp(outputChar,refChar))

end

%% ------------------------------------------------------------------------
function testMixed()
% Test for a mixed case (both expression and simple markers appear)
refChar = 'lat 1.000  2.000  <abs(X0003) + mod(X0001,X0002)> -3.500';

% Set up the test
inputChar = 'lat <X0001>  <X0002>  <abs(X0003) + mod(X0001,X0002)> <X0003>';
values = [1.0 2.0 -3.5 4e2 7.2691];
marker{1} = '<';
marker{2} = 'X';
marker{3} = '>';
fmtChar = {'%6.3f'};

outputChar = uq_UQLink_util_parseMarkerSimple(...
    inputChar, values, marker, fmtChar);

assert(strcmp(outputChar,refChar))

end
