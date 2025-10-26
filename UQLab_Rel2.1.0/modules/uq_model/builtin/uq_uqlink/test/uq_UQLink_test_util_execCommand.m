function pass = uq_UQLink_test_util_execCommand(level)
%UQ_UQLINK_TEST_UTIL_EXECCOMMAND tests the utility function to execute
%   system commands.

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
function testSimpleCallSuccessful()
% Test for a case in which the call to system command is successful.
if ispc
    success = uq_UQLink_util_execCommand('dir');
else
    success = uq_UQLink_util_execCommand('ls');
end

assert(success)

end


%% ------------------------------------------------------------------------
function testSimpleCallUnsuccessful()
% Test for a case in which the call to system command is unsuccessful.

success = uq_UQLink_util_execCommand(num2str(rand));

assert(~success)

end


%% ------------------------------------------------------------------------
function testCallWithShowEcho()
% Test for a case where command output is shown.
% NOTE: assert only that the function can be called not the actual output.

if ispc
    success = uq_UQLink_util_execCommand('dir',false);
else
    success = uq_UQLink_util_execCommand('ls',false);
end

assert(success)

end


%% ------------------------------------------------------------------------
function testWithWarningMessage()
% Test for a case in which a warning message is shown.

warning('off')
success = uq_UQLink_util_execCommand(num2str(rand),false,'Oh noo!');
warning('on')

assert(~success)

end
