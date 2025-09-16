function pass = uq_UQLink_test_util_checkForPatternInFiles(level)
%UQ_UQLINK_TEST_UTIL_CHECKFORPATTERNINFILES tests the utility function to
%   check for a pattern in a set of files.

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


%% Test for a case in which pattern is found
function testFoundSingleFile()

% Set up
pattern = 'find this';
testDir = fileparts(mfilename('fullpath'));
fullname = fullfile(testDir,uq_createUniqueID); 
fid = fopen(fullname,'w');
fprintf(fid,pattern);
fclose(fid);

% Find the pattern
patternFound = uq_UQLink_util_checkForPatternInFiles(fullname,pattern);

% Assertion
assert(patternFound)

% Cleanup
delete(fullname)

end


%% Test for a case in which pattern is not found
function testNotFoundSingleFile()

% Set up
pattern1 = 'find this';
pattern2 = 'find that';
testDir = fileparts(mfilename('fullpath'));
fullname = fullfile(testDir,uq_createUniqueID); 
fid = fopen(fullname,'w');
fprintf(fid,pattern1);
fclose(fid);

% Find the pattern
patternFound = uq_UQLink_util_checkForPatternInFiles(fullname,pattern2);

% Assertion
assert(~patternFound)

% Cleanup
delete(fullname)

end


%% Test for a case in which pattern is found, multiple files
function testFoundMultipleFiles()

% Set up
patterns = {'find this', 'find that', 'find those'};
testDir = fileparts(mfilename('fullpath'));
% Make sure to use UUID filename
fullnames{1} = fullfile(testDir,uq_createUniqueID('uuid'));
fullnames{2} = fullfile(testDir,uq_createUniqueID('uuid'));
fullnames{3} = fullfile(testDir,uq_createUniqueID('uuid'));
for i = 1:3
    fid = fopen(fullnames{i},'w');
    fprintf(fid,patterns{i});
    fclose(fid);
end

% Find the pattern
patternFound = uq_UQLink_util_checkForPatternInFiles(fullnames,patterns{2});

% Assertion
assert(patternFound)

% Cleanup
cellfun(@(x) delete(x), fullnames)

end


%% Test for a case in which pattern is not found, multiple files
function testNotFoundMultipleFiles()

% Set up
patterns = {'find this', 'find that', 'find those'};
testDir = fileparts(mfilename('fullpath'));
% Make sure to use UUID filename
fullnames{1} = fullfile(testDir,uq_createUniqueID('uuid'));
fullnames{2} = fullfile(testDir,uq_createUniqueID('uuid'));
fullnames{3} = fullfile(testDir,uq_createUniqueID('uuid'));
for i = 1:3
    fid = fopen(fullnames{i},'w');
    fprintf(fid,patterns{i});
    fclose(fid);
end

% Find the pattern
patternFound = uq_UQLink_util_checkForPatternInFiles(fullnames,'find sth');

% Assertion
assert(~patternFound)

% Cleanup
cellfun(@(x) delete(x), fullnames)

end


%% Test for a case in which multiple patterns is found
function testFoundMultiplePatterns()

% Set up
patterns = {'find this', 'find that', 'find those'};
testDir = fileparts(mfilename('fullpath'));
% Make sure to use UUID filename
fullname = fullfile(testDir,uq_createUniqueID('uuid'));
fid = fopen(fullname,'w');
for i = 1:3
    fprintf(fid,patterns{i});
end
fclose(fid);

% Find the pattern
patternFound = uq_UQLink_util_checkForPatternInFiles(fullname,patterns);

% Assertion
assert(patternFound)

% Cleanup
delete(fullname)

end


%% Test for a case in which none of multiple patterns is not found
function testNotFoundMultiplePatterns()

% Set up
patterns = {'find this', 'find that', 'find those'};
testDir = fileparts(mfilename('fullpath'));
% Make sure to use UUID filename
fullnames{1} = fullfile(testDir,uq_createUniqueID('uuid'));
fullnames{2} = fullfile(testDir,uq_createUniqueID('uuid'));
fullnames{3} = fullfile(testDir,uq_createUniqueID('uuid'));
for i = 1:3
    fid = fopen(fullnames{i},'w');
    fprintf(fid,patterns{i});
    fclose(fid);
end

% Find the pattern
patternFound = uq_UQLink_util_checkForPatternInFiles(fullnames,...
    {'find sth', 'find sth else', 'found nothing'});

% Assertion
assert(~patternFound)

% Cleanup
cellfun(@(x) delete(x), fullnames)

end

