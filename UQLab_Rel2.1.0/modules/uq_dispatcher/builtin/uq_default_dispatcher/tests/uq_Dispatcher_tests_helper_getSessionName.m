function pass = uq_Dispatcher_tests_helper_getSessionName(level)
%UQ_DISPATCHER_TESTS_HELPER_GETSESSIONNAME tests a helper function to get
%   the session name from a DISPATCHER object.

%% Initialize the test
if nargin < 1
    level = 'normal';
end

uqlab('-nosplash')

fprintf('Running: | %s | %s...', level, mfilename);

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
function testOpenSSHClient()
% A test for getting the session name with the OpenSSH syntax
% from a DISPATCHER object (username@hostname).
sessionNameRef = 'myUsername@myHostname';

% Set up a profile file
RemoteConfig.Username = 'myUsername';
RemoteConfig.Hostname = 'myHostname';
RemoteConfig.PrivateKey = 'myPrivateKey';
RemoteConfig.RemoteFolder = '/tmp';

% Create the test profile file
currentDir = fileparts(mfilename('fullpath'));
testDir = fullfile(currentDir,uq_createUniqueID());
mkdir(testDir)
testProfile = fullfile(testDir,'test_profile_file.m');
uq_Dispatcher_scripts_createProfile(testProfile,RemoteConfig)

% Set up a DISPATCHER object
DispatcherOpts.Profile = testProfile;
DispatcherOpts.CheckRequirements = false;
DispatcherOpts.AutoSave = false;

try
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Get the session name
    sessionName = uq_Dispatcher_helper_getSessionName(myDispatcher);
    % Verify the Session name
    assert(strcmp(sessionName,sessionNameRef),...
        'Expected SessionName to be ''%s'', but get ''%s'' instead.',...
        sessionNameRef, sessionName)
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testPuTTYClient()
% A test for getting the PuTTY saved session from a DISPATCHER object.
clearvars
sessionNameRef = 'mySessionName';

% Set up a profile file
RemoteConfig.SavedSession = sessionNameRef;
RemoteConfig.RemoteFolder = '/tmp';

% Create the test profile file
currentDir = fileparts(mfilename('fullpath'));
testDir = fullfile(currentDir,uq_createUniqueID());
mkdir(testDir)
testProfile = fullfile(testDir,'test_profile_file.m');
uq_Dispatcher_scripts_createProfile(testProfile,RemoteConfig)

% Set up a DISPATCHER object
DispatcherOpts.Profile = testProfile;
DispatcherOpts.CheckRequirements = false;
DispatcherOpts.AutoSave = false;

try
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts);
    % Get the session name
    sessionName = uq_Dispatcher_helper_getSessionName(myDispatcher);
    % Assertion
    assert(strcmp(sessionName,sessionNameRef),...
        'Expected SessionName to be ''%s'', but get ''%s'' instead.',...
        sessionNameRef, sessionName)
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')
end
