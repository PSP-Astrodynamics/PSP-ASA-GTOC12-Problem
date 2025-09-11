function pass = uq_UQLink_test_util_addQuotesOnPath(level)
%UQ_UQLINK_TEST_UTIL_ADDQUOTESONPATH tests the utility function to enclose
%   a path in double quotes if the path contains whitespaces.

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
function testNoSpaceNoExecutableWindows()
% Test for a case without any space, without any executable (Windows).
refChar = 'C:\SIMULIA\Abaqus\Commands\';

% Add quotes on the path
outChar = uq_UQLink_util_addQuotesOnPath(refChar,'\');

% Assertion
uq_UQLink_util_assertChar(outChar,refChar)

end


%% ------------------------------------------------------------------------
function testNoSpaceWindows()
% Test for a case without any space in a Windows path (nothing happen).
refChar = 'C:\SIMULIA\Abaqus\Commands\abaqus -job TenBarTruss interactive';

% Add quotes on the path
outChar = uq_UQLink_util_addQuotesOnPath(refChar,'\');

% Assertion
uq_UQLink_util_assertChar(outChar,refChar)

end


%% ------------------------------------------------------------------------
function testNoPathWindows()
% Test for a case without an executable path in a Windows path.
refChar = 'abaqus -job TenBarTruss interactive';

% Add quotes on the path
outChar = uq_UQLink_util_addQuotesOnPath(refChar);

% Assertion
uq_UQLink_util_assertChar(outChar,refChar)

end


%% ------------------------------------------------------------------------
function testWithSpaceWindows()
% Test for a case with a space in a Windows path.
refChar = '"C:\Program Files\SIMULIA\Abaqus\Commands"\abaqus -job TenBarTruss interactive';

% Add quotes on the path
inpChar = 'C:\Program Files\SIMULIA\Abaqus\Commands\abaqus -job TenBarTruss interactive';
outChar = uq_UQLink_util_addQuotesOnPath(inpChar,'\');

% Assertion
uq_UQLink_util_assertChar(outChar,refChar)

end


%% ------------------------------------------------------------------------
function testWithSpaceNoExecutableWindows()
% Test for a case with a space in a Windows path.
refChar = '"C:\Program Files\SIMULIA\Abaqus"\';

% Add quotes on the path
inpChar = '"C:\Program Files\SIMULIA\Abaqus"\';
outChar = uq_UQLink_util_addQuotesOnPath(inpChar,'\');

% Assertion
uq_UQLink_util_assertChar(outChar,refChar)

end


%% ------------------------------------------------------------------------
function testWithSpaceAlreadyQuotedWindows()
% Test for a case with a space in a Windows path but already quoted.
refChar = '"C:\Program Files"\SIMULIA\Abaqus\Commands"\abaqus -job TenBarTruss interactive';

% Add quotes on the path
inpChar = '"C:\Program Files"\SIMULIA\Abaqus\Commands"\abaqus -job TenBarTruss interactive';
outChar = uq_UQLink_util_addQuotesOnPath(inpChar,'\');

% Assertion
uq_UQLink_util_assertChar(outChar,refChar)

end


%% ------------------------------------------------------------------------
function testWithMultipleSpacesWindows()
% Test for a case with multiple spaces in a Windows path.
refChar = '"C:\Program   Files\SIMULIA\Abaqus\Commands"\abaqus -job TenBarTruss interactive';

% Add quotes on the path
inpChar = 'C:\Program   Files\SIMULIA\Abaqus\Commands\abaqus -job TenBarTruss interactive';
outChar = uq_UQLink_util_addQuotesOnPath(inpChar,'\');

% Assertion
uq_UQLink_util_assertChar(outChar,refChar)

end


%% ------------------------------------------------------------------------
function testNestedFolderWithSpaceWindows()
% Test for a case with a nested folders in Windows some have spaces in it. 
refChar = '"C:\Program Files\My Applications\SIMULIA\Abaqus\Commands"\abaqus -job TenBarTruss interactive';

% Add quotes on the path
inpChar = 'C:\Program Files\My Applications\SIMULIA\Abaqus\Commands\abaqus -job TenBarTruss interactive';
outChar = uq_UQLink_util_addQuotesOnPath(inpChar,'\');

% Assertion
uq_UQLink_util_assertChar(outChar,refChar)

end


%% ------------------------------------------------------------------------
function testNestedFoldersWithMultipleSpacesWindows()
% Test for a case with a nested folders in Windows some have multiple
% spaces.
refChar = '"C:\Program  Files\My   Applications\SIMULIA\Abaqus\Commands"\abaqus -job TenBarTruss interactive';

% Add quotes on the path
inpChar = 'C:\Program  Files\My   Applications\SIMULIA\Abaqus\Commands\abaqus -job TenBarTruss interactive';
outChar = uq_UQLink_util_addQuotesOnPath(inpChar,'\');

% Assertion
uq_UQLink_util_assertChar(outChar,refChar)

end


%% ------------------------------------------------------------------------
function testNoSpaceNoExecutableLinux()
% Test for a case without any space, without executable in Linux path.
refChar = '/usr/bin/';

% Add quotes on the path
outChar = uq_UQLink_util_addQuotesOnPath(refChar,'/');

% Assertion
uq_UQLink_util_assertChar(outChar,refChar)

end


%% ------------------------------------------------------------------------
function testNoSpaceLinux()
% Test for a case without any space in Linux path (nothing should happen).
refChar = '/usr/bin/myExecutable -job myInput.inp';

% Add quotes on the path
outChar = uq_UQLink_util_addQuotesOnPath(refChar,'/');

% Assertion
uq_UQLink_util_assertChar(outChar,refChar)

end


%% ------------------------------------------------------------------------
function testNoPathLinux()
% Test for a case without a path in Linux (nothing happens).
refChar = 'myExecutable -job myInput.inp';

% Add quotes on the path
outChar = uq_UQLink_util_addQuotesOnPath(refChar,'/');

% Assertion
uq_UQLink_util_assertChar(outChar,refChar)

end


%% ------------------------------------------------------------------------
function testWithSpacesLinux()
% Test for a case with spaces in Linux path.
refChar = '"/usr/bin/My Apps"/myExecutable -job myInput.inp myOutput.out';

% Add quotes on the path
inpChar = '/usr/bin/My Apps/myExecutable -job myInput.inp myOutput.out';
outChar = uq_UQLink_util_addQuotesOnPath(inpChar,'/');

% Assertion
uq_UQLink_util_assertChar(outChar,refChar)

end


%% ------------------------------------------------------------------------
function testWithSpacesNoExecutableLinux()
% Test for a case with spaces, without executable in Linux.
refChar = '"/usr/bin/My Apps"/';

% Add quotes on the path
inpChar = '/usr/bin/My Apps/';
outChar = uq_UQLink_util_addQuotesOnPath(inpChar,'/');

% Assertion
uq_UQLink_util_assertChar(outChar,refChar)

end


%% ------------------------------------------------------------------------
function testWithMultipleSpacesLinux()
% Test for a case with multiple spaces in Linux path.
refChar = '"/usr/bin/My  Apps"/myExecutable -job myInput.inp myOutput.out';

% Add quotes on the path
inpChar = '/usr/bin/My  Apps/myExecutable -job myInput.inp myOutput.out';
outChar = uq_UQLink_util_addQuotesOnPath(inpChar,'/');

% Assertion
uq_UQLink_util_assertChar(outChar,refChar)

end


%% ------------------------------------------------------------------------
function testNestedFoldersWithSpaceLinux()
% Test for a case with nested folders some with a space in it (Linux).
refChar = '"/usr/My Folder/My Apps"/myExecutable -job myInput.inp myOutput.out';

% Add quotes on the path
inpChar = '/usr/My Folder/My Apps/myExecutable -job myInput.inp myOutput.out';
outChar = uq_UQLink_util_addQuotesOnPath(inpChar,'/');

% Assertion
uq_UQLink_util_assertChar(outChar,refChar)

end


%% ------------------------------------------------------------------------
function testNestedFoldersWithMultipleSpacesLinux()
% Test for a Linux case with nested folders some with multiple spaces in it.
refChar = '"/usr/My  Folder/My   Apps"/myExecutable -job myInput.inp myOutput.out';

% Add quotes on the path
inpChar = '/usr/My  Folder/My   Apps/myExecutable -job myInput.inp myOutput.out';
outChar = uq_UQLink_util_addQuotesOnPath(inpChar,'/');

% Assertion
uq_UQLink_util_assertChar(outChar,refChar)

end


%% ------------------------------------------------------------------------
function testWithSpaceUsingEscapeCharLinux()
% Test for a case with space in the path but using Linux escape character.
refChar = '/usr/bin/My\ Apps/myExecutable -job myInput.inp myOutput.out';

% Add quotes on the path
inpChar = '/usr/bin/My\ Apps/myExecutable -job myInput.inp myOutput.out';
outChar = uq_UQLink_util_addQuotesOnPath(inpChar,'/');

% Assertion
uq_UQLink_util_assertChar(outChar,refChar)

end


%% ------------------------------------------------------------------------
function testWithMultipleSpacesUsingEscapeCharLinux()
% Test for a case with multiples spaces in the path
% but using Linux escape character.
refChar = '/usr/bin/My\ \ Apps/myExecutable -job myInput.inp myOutput.out';

% Add quotes on the path
inpChar = '/usr/bin/My\ \ Apps/myExecutable -job myInput.inp myOutput.out';
outChar = uq_UQLink_util_addQuotesOnPath(inpChar,'/');

% Assertion
uq_UQLink_util_assertChar(outChar,refChar)

end
