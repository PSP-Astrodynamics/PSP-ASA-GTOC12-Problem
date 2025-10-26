function pass = uq_Dispatcher_tests_init_UQLab(level)
%UQ_DISPATCHER_TESTS_INIT_UQLABOPTION tests the parsing of UQLab-related
%   options in the remote machine. The options are specified in the profile
%   file and read during the initialization of a DISPATCHER object.

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


%% ------------------------------------------------------------------------
function testDefault()
% A test for the default option.

% Set up a profile file
if ispc
    RemoteConfig.SavedSession = 'mySavedSession';
else
    RemoteConfig.Username = 'myUsername';
    RemoteConfig.Hostname = 'myHostname';
    RemoteConfig.PrivateKey = 'myPrivateKey';
end
RemoteConfig.RemoteFolder = '/tmp';

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Read and verify the option
try
    % Read the profile file
    RemoteConfigRead = uq_Dispatcher_readProfile(testProfile);
    % Verify the 'RemoteUQLabPath' field (default: empty)
    assert(isempty(RemoteConfigRead.RemoteUQLabPath))
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testCustom()
% A test for a custom function.

% Set up a profile file
if ispc
    RemoteConfig.SavedSession = 'mySavedSession';
else
    RemoteConfig.Username = 'myUsername';
    RemoteConfig.Hostname = 'myHostname';
    RemoteConfig.PrivateKey = 'myPrivateKey';
end
RemoteConfig.RemoteFolder = '/tmp';

% Set the custom value
RemoteConfig.RemoteUQLabPath = 'data/uqlab';

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Read and verify the option
try
    % Read the profile file
    RemoteConfigRead = uq_Dispatcher_readProfile(testProfile);
    % Verify the specified 'RemoteUQLabPath'
    assert(...
        isequal(RemoteConfigRead.RemoteUQLabPath,...
            RemoteConfig.RemoteUQLabPath))
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end
