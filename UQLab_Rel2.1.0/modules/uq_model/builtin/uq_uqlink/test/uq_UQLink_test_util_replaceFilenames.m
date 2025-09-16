function pass = uq_UQLink_test_util_replaceFilenames(level)
%UQ_UQLINK_TEST_UTIL_REPLACEFILENAMECHAR tests the utility function to
%   replace a set of filenames with a new one inside a char array.

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
function testNoInputWindows()
% Test for a case without any input passed to the executable (Windows).
refChar = 'C:\Application Data\bin\myBeam';

% Set up the case
inputBasename = {'myInput'};
inputBasenameIndexed = {'myInput000015'};
inputExtension = {'inp'};

% Replace the filename
outChar = uq_UQLink_util_replaceFilenames(...
    refChar, inputBasename, inputBasenameIndexed, inputExtension);

% Assertion
uq_UQLink_util_assertChar(outChar,refChar);

end


%% ------------------------------------------------------------------------
function testSingleInputWindows()
% Test for a case with a single input (Windows).

% Set up the case
exeCmd = 'C:\Application Data\bin\myBeam';
inputExtensions = {'inp'};
inputBasenames = {'inputFile'};
inputBasenamesIndexed = {'inputFile000015'};

refChar = strcat(...
    exeCmd, ' ', inputBasenamesIndexed{1}, '.', inputExtensions{1});
inpChar = strcat(exeCmd, ' ', inputBasenames{1}, '.', inputExtensions{1});

% Replace the filename
outChar = uq_UQLink_util_replaceFilenames(...
    inpChar, inputBasenames, inputBasenamesIndexed, inputExtensions);

% Assertion
uq_UQLink_util_assertChar(outChar,refChar);

end


%% ------------------------------------------------------------------------
function testMultipleInputsWindows()
% Test for a case with multiple inputs (Windows).

% Set up the case
exeCmd = 'C:\Application Data\bin\myBeam';
inputBasenames = {'inputFile1', 'inputFile2', 'inputFile3', 'inputFile4'};
inputBasenamesIndexed = strcat(inputBasenames,'000015');
inputExtensions = {'inp', 'inp', 'dat', 'inp'};

% Create the reference
inputFilenamesIndexed = strcat(...
    inputBasenamesIndexed, '.', inputExtensions);
refChar = [sprintf('%s %s ', exeCmd, inputFilenamesIndexed{1:end-1}) ...
    inputFilenamesIndexed{end}];
inputFilenames = strcat(inputBasenames, '.', inputExtensions);
inpChar = [sprintf('%s %s ', exeCmd, inputFilenames{1:end-1}) ...
    inputFilenames{end}];

% Replace the filename
outChar = uq_UQLink_util_replaceFilenames(...
    inpChar, inputBasenames, inputBasenamesIndexed, inputExtensions);

% Assertion
uq_UQLink_util_assertChar(outChar,refChar);

end


%% ------------------------------------------------------------------------
function testSingleInputNoExtensionWindows()
% Test for a case with a single input file without extension (Windows).

% Set up the case
exeCmd = 'C:\Application Data\bin\myBeam';
inputBasenames = {'inputFile1'};
inputBasenamesIndexed = {'inputFile1000015'};
inputExtensions = {''};

refChar = strcat(exeCmd, ' ', inputBasenamesIndexed{1});
inpChar = strcat(exeCmd, ' ', inputBasenames{1});

% Replace the filename
outChar = uq_UQLink_util_replaceFilenames(...
    inpChar, inputBasenames, inputBasenamesIndexed, inputExtensions);

% Assertion
uq_UQLink_util_assertChar(outChar,refChar);

end


%% ------------------------------------------------------------------------
function testMultipleInputsNoExtensionWindows()
% Test for a case with multiple inputs but whout any extension (Windows).
% ref: 'C:\Application Data\bin\myBeam inputFileA inputFileB inputFileC'

% Set up the case
exeCmd = 'C:\Application Data\bin\myBeam';
inputBasenames = {'inputFile1', 'inputFile2', 'inputFile3', 'inputFile4'};
inputBasenamesIndexed = strcat(inputBasenames,'00012');

% Create the reference
refChar = [sprintf('%s %s ', exeCmd, inputBasenamesIndexed{1:end-1}) ...
    inputBasenamesIndexed{end}];
inpChar = [sprintf('%s %s ', exeCmd, inputBasenames{1:end-1}) ...
    inputBasenames{end}];

% Replace the basename
outChar = uq_UQLink_util_replaceFilenames(...
    inpChar, inputBasenames, inputBasenamesIndexed);

% Assertion
uq_UQLink_util_assertChar(outChar,refChar);

end


%% ------------------------------------------------------------------------
function testSingleInputWithOutputWindows()
% Test for a case with input and output files (Windows). 
% ref: 'C:\Application Data\bin\myBeam inputFile.inp outFile.out'

% Set up the case
exeCmd = 'C:\Application Data\bin\myBeam';
inputBasenames = {'inputFile'};
inputBasenamesIndexed = {'inputFile000015'};
inputExtensions = {'inp'};

% Create the reference
inputFilenamesIndexed = strcat(...
    exeCmd, ' ', inputBasenamesIndexed, '.', inputExtensions);
refChar = sprintf('%s %s outFile.out', exeCmd, inputFilenamesIndexed{:});
inputFilenames = strcat(...
    exeCmd, ' ', inputBasenames, '.', inputExtensions);
inpChar = sprintf('%s %s outFile.out', exeCmd, inputFilenames{:});

% Replace the filename
outChar = uq_UQLink_util_replaceFilenames(...
    inpChar, inputBasenames, inputBasenamesIndexed, inputExtensions);

% Assertion
uq_UQLink_util_assertChar(outChar,refChar);

end


%% ------------------------------------------------------------------------
function testMultipleInputsWithOutputWindows()
% Test for a case with multiple inputs and an output at the end (Windows).
% ref: 'C:\Application Data\bin\myBeam inputFile1.inp inputFile2.inp inputFile3.inp inputFile4.inp outFile.out'

% Set up the case
exeCmd = 'C:\Application Data\bin\myBeam';
inputBasenames = {'inputFile1', 'inputFile2', 'inputFile3', 'inputFile4'};
inputBasenamesIndexed = strcat(inputBasenames,'01241');
inputExtensions = {'inp', 'inp', 'dat', 'inp'};

% Create the input and reference
inputFilenamesIndexed = strcat(inputBasenamesIndexed, '.', inputExtensions);
refChar = [sprintf('%s %s ', exeCmd, inputFilenamesIndexed{1:end-1}) ...
    inputFilenamesIndexed{end} ' ' 'outFile.out'];
inputFilenames = strcat(inputBasenames, '.', inputExtensions);
inpChar = [sprintf('%s %s ', exeCmd, inputFilenames{1:end-1}) ...
    inputFilenames{end} ' ' 'outFile.out'];

% Replace the filename
outChar = uq_UQLink_util_replaceFilenames(...
    inpChar, inputBasenames, inputBasenamesIndexed, inputExtensions);

% Assertion
uq_UQLink_util_assertChar(outChar,refChar);

end


%% ------------------------------------------------------------------------
function testSingleInputWithOutputNoExtensionWindows()
% Test for a case with a single input and output without ext. (Windows)
% 'C:\Application Data\bin\myBeam -i myFile -o myFile'

% Set up the case
exeCmd = 'C:\Application Data\bin\myBeam';
inputBasenames = {'myFile'};
inputBasenamesIndexed = {'myFile1000015'};

refChar = sprintf('%s -i %s -o outFile.out', exeCmd, inputBasenamesIndexed{:});
inpChar = sprintf('%s -i %s -o outFile.out', exeCmd, inputBasenames{:});

% Replace the filename
outChar = uq_UQLink_util_replaceFilenames(...
    inpChar, inputBasenames, inputBasenamesIndexed);

% Assertion
uq_UQLink_util_assertChar(outChar,refChar);

end


%% ------------------------------------------------------------------------
function testMultipleInputsWithOutputNoExtensionWindows()
% Test for a case with multiple inputs and an output w/o ext. (Windows)
% 'C:\Application Data\bin\myBeam -i inputFileA -i inputFileB -i inputFileC -o outFile'

% Set up the case
exeCmd = 'C:\Application Data\bin\myBeam';
inputBasenames = {'inputFileA', 'inputFileB', 'inputFileC'};
inputBasenamesIndexed = strcat(inputBasenames,'006346');

% Create input and reference char
inputBasenamesFlag = strcat('-i ', {' '}, inputBasenames);
inpChar = [sprintf('%s %s ', exeCmd, inputBasenamesFlag{:})...
    '-o outFile'];

inputBasenamesIndexedFlag = strcat('-i ', {' '}, inputBasenamesIndexed);
refChar = [sprintf('%s %s ', exeCmd, inputBasenamesIndexedFlag{:}) ...
    '-o outFile'];

% Replace the basename
outChar = uq_UQLink_util_replaceFilenames(...
    inpChar, inputBasenames, inputBasenamesIndexed);

% Assertion
uq_UQLink_util_assertChar(outChar,refChar);

end


%% ------------------------------------------------------------------------
function testNoInputLinux()
% Test for a case without any input passed to the executable (Linux).
refChar = '/codes/bin/myBeam';

% Replace the filename
inputBasenames = {'myInput'};
inputBasenamesIndexed = {'myInput000015'};
inputExtensions = {'inp'};

outChar = uq_UQLink_util_replaceFilenames(...
    refChar, inputBasenames, inputBasenamesIndexed, inputExtensions);

% Assertion
uq_UQLink_util_assertChar(outChar,refChar);

end


%% ------------------------------------------------------------------------
function testSingleInputLinux()
% Test for a case with a single input (Linux).

% Set up the case
exeCmd = '/codes/bin/myBeam';
inputExtensions = {'inp'};
inputBasenames = {'inputFile'};
inputBasenamesIndexed = {'inputFile000015'};

% Create input and reference char
inpChar = strcat(exeCmd, ' ', inputBasenames{1}, '.', inputExtensions{1});
refChar = strcat(...
    exeCmd, ' ', inputBasenamesIndexed{1}, '.', inputExtensions{1});

% Replace the filename
outChar = uq_UQLink_util_replaceFilenames(...
    inpChar, inputBasenames, inputBasenamesIndexed, inputExtensions);

% Assertion
uq_UQLink_util_assertChar(outChar,refChar);

end


%% ------------------------------------------------------------------------
function testMultipleInputsLinux()
% Test for a case with multiple inputs (Linux).
% '/codes/bin/myBeam inputFile1.inp inputFile2.inp inputFile3.inp inputFile4.inp'

% Set up the case
exeCmd = '/codes/bin/myBeam';
inputBasenames = {'inputFile1', 'inputFile2', 'inputFile3', 'inputFile4'};
inputBasenamesIndexed = strcat(inputBasenames,'000015');
inputExtensions = {'inp', 'inp', 'dat', 'inp'};

% Create input and reference chars
inputFilenamesExt = strcat(inputBasenames, '.', inputExtensions);
inpChar = [sprintf('%s %s ', exeCmd, inputFilenamesExt{1:end-1}) ...
    inputFilenamesExt{end}];

inputFilenamesIndexed = strcat(inputBasenamesIndexed, '.', inputExtensions);
refChar = [sprintf('%s %s ', exeCmd, inputFilenamesIndexed{1:end-1}) ...
    inputFilenamesIndexed{end}];

% Replace the filenames
outChar = uq_UQLink_util_replaceFilenames(...
    inpChar, inputBasenames, inputBasenamesIndexed, inputExtensions);

% Assertion
uq_UQLink_util_assertChar(outChar,refChar);

end


%% ------------------------------------------------------------------------
function testSingleInputNoExtensionLinux()
% Test for a case with a single input file without extension (Linux).

% Set up the case
exeCmd = '/codes/bin/myBeam';
inputBasenames = {'inputFile'};
inputBasenamesIndexed = {'inputFile000015'};
inputExtensions = {''};

refChar = strcat(exeCmd, ' ', inputBasenamesIndexed{1});
inpChar = strcat(exeCmd, ' ', inputBasenames{1});

% Replace the filenames
outChar = uq_UQLink_util_replaceFilenames(...
    inpChar, inputBasenames, inputBasenamesIndexed, inputExtensions);

% Assertion
uq_UQLink_util_assertChar(outChar,refChar);

end


%% ------------------------------------------------------------------------
function testMultipleInputsNoExtensionLinux()
% Test for a case with multiple inputs but whout any extension (Linux).
% '/codes/bin/myBeam inputFileA inputFileB inputFileC'

% Set up the case
exeCmd = '/codes/bin/myBeam';
inputBasenames = {'inputFile1', 'inputFile2', 'inputFile3', 'inputFile4'};
inputBasenamesIndexed = strcat(inputBasenames,'000015');

% Create input and reference chars
inpChar = [sprintf('%s %s ', exeCmd, inputBasenames{1:end-1}) ...
    inputBasenames{end}];
refChar = [sprintf('%s %s ', exeCmd, inputBasenamesIndexed{1:end-1}) ...
    inputBasenamesIndexed{end}];

% Replace the basenames
outChar = uq_UQLink_util_replaceFilenames(...
    inpChar, inputBasenames, inputBasenamesIndexed);

% Assertion
uq_UQLink_util_assertChar(outChar,refChar);

end


%% ------------------------------------------------------------------------
function testSingleInputWithOutputLinux()
% Test for a case with input and output files (Linux). 
% '/codes/bin/myBeam inputFile.inp outFile.out'

% Set up the case
exeCmd = '/codes/bin/myBeam';
inputBasenames = {'inputFile'};
inputBasenamesIndexed = {'inputFile000015'};
inputExtensions = {'inp'};

% Create input and reference chars
inputFilenamesIndexed = strcat(...
    exeCmd, ' ', inputBasenames, '.', inputExtensions);
inpChar = sprintf('%s %s outFile.out', exeCmd, inputFilenamesIndexed{:});
inputFilenamesIndexed = strcat(...
    exeCmd, ' ', inputBasenamesIndexed, '.', inputExtensions);
refChar = sprintf('%s %s outFile.out', exeCmd, inputFilenamesIndexed{:});

% Replace the filename
outChar = uq_UQLink_util_replaceFilenames(...
    inpChar, inputBasenames, inputBasenamesIndexed, inputExtensions);

% Assertion
uq_UQLink_util_assertChar(outChar,refChar);

end


%% ------------------------------------------------------------------------
function testNoInputWithOutputLinux()
% Test for a case without any inputs (Linux).
% '/codes/bin/myBeam outFile.out'

% Set up the case
exeCmd = '/codes/bin/myBeam';
inputBasenames = {'inputFile'};
inputBasenamesIndexed = {'inputFile000015'};
inputExtensions = {'inp'};

% Create input and reference chars
inputFilenames = strcat(...
    exeCmd, ' ', inputBasenames, '.', inputExtensions);
inpChar = sprintf('%s outFile.out', exeCmd, inputFilenames{:});
inputFilenamesIndexed = strcat(...
    exeCmd, ' ', inputBasenamesIndexed, '.', inputExtensions);
refChar = sprintf('%s outFile.out', exeCmd, inputFilenamesIndexed{:});

% Replace the filenames
outChar = uq_UQLink_util_replaceFilenames(...
    inpChar, inputBasenames, inputBasenamesIndexed, inputExtensions);

% Assertion
uq_UQLink_util_assertChar(outChar,refChar);

end


%% ------------------------------------------------------------------------
function testMultipleInputsWithOutputLinux()
% Test for a case with multiple inputs and without output (Linux).

% Set up the case
exeCmd = '/codes/bin/myBeam';
inputBasenames = {'inputFile1', 'inputFile2', 'inputFile3', 'inputFile4'};
inputBasenamesIndexed = strcat(inputBasenames,'000015');
inputExtensions = {'inp', 'inp', 'dat', 'inp'};

% Create input and reference chars
inputFilenames = strcat(inputBasenames, '.', inputExtensions);
inpChar = [sprintf('%s %s ', exeCmd, inputFilenames{1:end-1}) ...
    inputFilenames{end} ' ' 'outFile.out'];
inputFilenamesIndexed = strcat(inputBasenamesIndexed, '.', inputExtensions);
refChar = [sprintf('%s %s ', exeCmd, inputFilenamesIndexed{1:end-1}) ...
    inputFilenamesIndexed{end} ' ' 'outFile.out'];

% Replace the filenames
outChar = uq_UQLink_util_replaceFilenames(...
    inpChar, inputBasenames, inputBasenamesIndexed, inputExtensions);

% Assertion
uq_UQLink_util_assertChar(outChar,refChar);

end


%% ------------------------------------------------------------------------
function testSingleInputWithOutputNoExtensionLinux()
% Test for a case with a single input and output without ext. (Linux)
% '/codes/bin/myBeam -i inputFile -o outFile'

% Set up the case
exeCmd = '/codes/bin/myBeam';
inputBasenames = {'inputFile1'};
inputBasenamesIndexed = {'inputFile1000015'};

refChar = sprintf('%s -i %s -o outFile.out', exeCmd, inputBasenamesIndexed{:});
inpChar = sprintf('%s -i %s -o outFile.out', exeCmd, inputBasenames{:});

% Replace the basenames
outChar = uq_UQLink_util_replaceFilenames(...
    inpChar, inputBasenames, inputBasenamesIndexed);

% Assertion
uq_UQLink_util_assertChar(outChar,refChar);

end


%% ------------------------------------------------------------------------
function testMultipleInputsWithOutputNoExtensionLinux()
% Test for a case with multiple inputs and an output w/o extension (Linux).
% '/codes/bin/myBeam -i inputFileA -i inputFileB -i inputFileC outFile'

% Set up the case
exeCmd = '/codes/bin/myBeam';
inputBasenames = {'inputFileA', 'inputFileB', 'inputFileC'};
inputBasenamesIndexed = strcat(inputBasenames,'000015');

% Create input and reference chars
inputFilenamesIndexedFlag = strcat('-i ', {' '}, inputBasenamesIndexed);
refChar = [sprintf('%s %s ', exeCmd, inputFilenamesIndexedFlag{:}) ...
    '-o outFile'];
inputFilenamesFlag = strcat('-i ', {' '}, inputBasenames);
inpChar = [sprintf('%s %s ', exeCmd, inputFilenamesFlag{:})...
    '-o outFile'];

% Replace the basenames
outChar = uq_UQLink_util_replaceFilenames(...
    inpChar, inputBasenames, inputBasenamesIndexed);

% Assertion
uq_UQLink_util_assertChar(outChar,refChar);

end


%% ------------------------------------------------------------------------
function testCharInTemplate()
% Test for a case without output filename in a typical template file.
refChar = 'input=myInput.inp; data=myData.lib';

% Set up case
oldBasename = {'output'};
newBasename = {'output000015'};

% Replace the basename
outChar1 = uq_UQLink_util_replaceFilenames(...
    refChar, oldBasename, newBasename);

% Replace the filename (i.e., w/ extension)
outChar2 = uq_UQLink_util_replaceFilenames(...
    refChar, oldBasename, newBasename, '.out');

% Assertions
assert(strcmp(outChar1,refChar))
assert(strcmp(outChar2,refChar))

end


%% ------------------------------------------------------------------------
function testCharInTemplateSimpleCase()
% Test for a simple case of a line in a typical template file.
refChar = 'output000015.out';

% Set up case
inpChar = 'output.out';
oldBasename = {'output'};
newBasename = {'output000015'};
extension = {'out'};

% Replace filename
outChar = uq_UQLink_util_replaceFilenames(...
    inpChar, oldBasename, newBasename, extension);

% Assertion
uq_UQLink_util_assertChar(outChar,refChar)

end


%% ------------------------------------------------------------------------
function testCharInTemplateComplexCase1()
% Test for a more complex case of a line in a typical template file.
refChar = 'outputFile = outputfilename101.dat';

% Set up case
inpChar = 'outputFile = outputfilename.dat';
oldBasename = {'outputfilename'};
newBasename = {'outputfilename101'};

% Replace basename
outChar = uq_UQLink_util_replaceFilenames(...
    inpChar, oldBasename, newBasename);

% Assertion
uq_UQLink_util_assertChar(outChar,refChar)

end


%% ------------------------------------------------------------------------
function testComplexCase2()
% Test for a more complex case of a line in a typical template file.
refChar = 'data = ''myData.lib''; output = ''myOutput3215''';

% Set up case
inpChar = 'data = ''myData.lib''; output = ''myOutput''';
oldBasename = {'myOutput'};
newBasename = {'myOutput3215'};

% Parse output filename
outChar = uq_UQLink_util_replaceFilenames(...
    inpChar, oldBasename, newBasename);

% Assertion
uq_UQLink_util_assertChar(outChar,refChar)

end
