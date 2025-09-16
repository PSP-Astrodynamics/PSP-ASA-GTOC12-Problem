function pass = uq_Dispatcher_tests_init_Dispatcher(level)
%UQ_DISPATCHER_TESTS_INIT_DEFAULTOPTION tests the initialization of a
%   Dispatcher object with user-specified configuration options.

%% Verify inputs
if nargin < 1
    level = 'normal';
end

uqlab('-nosplash')

fprintf('Running: | %s | %s...', level, mfilename)

%% Get all local test functions
testFunctions = localfunctions;

%% Execute all test functions
for i = 1:numel(testFunctions)-1  % The last local functions is a helper
    feval(testFunctions{i})
end

%% Return the results
fprintf('PASS\n')

pass = true;

end


%% ------------------------------------------------------------------------
function testName()
% A test for the 'Name' option.

% Create test remote configuration from the template
RemoteConfig = createTestConfig();

% Create test remote machine profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Specify a DISPATCHER object
DispatcherOpts.Profile = testProfile;
DispatcherOpts.CheckRequirements = false;  % Don't check for passwordless SSH
DispatcherOpts.AutoSave = false;

% Verify the default value
try
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the default name
    assert(isequal(myDispatcher.Name,'Dispatcher 1'))
    
    % Specify a custom name
    DispatcherOpts.Name = 'My Dispatcher';
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the custom name
    assert(isequal(myDispatcher.Name,DispatcherOpts.Name))

catch e

    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)

end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testDisplay
% A test for the 'Display' option ('quiet', 'standard', 'verbose').
% The display option is internally converted to an integer ID.

% Create test remote configuration from the template
RemoteConfig = createTestConfig();

% Create test remote machine profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Specify a DISPATCHER object
DispatcherOpts.Profile = testProfile;
DispatcherOpts.CheckRequirements = false;  % Don't check for passwordless SSH
DispatcherOpts.AutoSave = false;

% Verify the display option
try
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the default display option
    assert(isequal(myDispatcher.Internal.Display,1))
    
    % Set 'quiet' option
    DispatcherOpts.Display = 'quiet';
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the 'quiet' display option
    assert(isequal(myDispatcher.Internal.Display,0))

    % Set 'standard' option
    DispatcherOpts.Display = 'standard';
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the 'standard' display option
    assert(isequal(myDispatcher.Internal.Display,1))

    % Set 'verbose' option
    DispatcherOpts.Display = 'verbose';
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the 'verbose' display option
    assert(isequal(myDispatcher.Internal.Display,2))

catch e

    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)

end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testProfile
% A test for reading the profile file.

% Create test remote configuration from the template
RemoteConfig = createTestConfig();

% Create test remote machine profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Specify a DISPATCHER object
DispatcherOpts.Profile = testProfile;
DispatcherOpts.CheckRequirements = false;  % Don't check for passwordless SSH
DispatcherOpts.AutoSave = false;

% Verify the profile file name
[~,testProfileName] = fileparts(testProfile);
try
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    
    % Verify the name of the profile file
    assert(isequal(myDispatcher.Profile,testProfileName))

    % Verify the content of 'RemoteConfig'
    RemoteConfig = uq_Dispatcher_readProfile(DispatcherOpts.Profile);
    assert(isequal(myDispatcher.Internal.RemoteConfig,RemoteConfig))

catch e
    
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)

end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testRemoteLocation
% A test for parsing the remote location (the value is read from profile).

% Create test remote configuration from the template
RemoteConfig = createTestConfig();

% Create test remote machine profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Specify a DISPATCHER object
DispatcherOpts.Profile = testProfile;
DispatcherOpts.CheckRequirements = false;  % Don't check for passwordless SSH
DispatcherOpts.AutoSave = false;

% Verify the profile 
try
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the remote location
    assert(isequal(myDispatcher.RemoteLocation,RemoteConfig.RemoteFolder))
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testLocalStagingLocation
% A test for 'LocalStagingLocation' option.

% Create test remote configuration from the template
RemoteConfig = createTestConfig();

% Create test remote machine profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Specify a DISPATCHER object
DispatcherOpts.Profile = testProfile;
DispatcherOpts.CheckRequirements = false;  % Don't check for passwordless SSH
DispatcherOpts.AutoSave = false;

% Verify 'LocalStagingLocation'
try
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the default value
    assert(isempty(myDispatcher.LocalStagingLocation))
    
    % Specify another location
    DispatcherOpts.LocalStagingLocation = 'tmp';
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the custom location
    assert(isequal(myDispatcher.LocalStagingLocation,...
        DispatcherOpts.LocalStagingLocation))

catch e
    
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
    
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testNumProcs
% A test for 'NumProcs' option.

% Create test remote configuration from the template
RemoteConfig = createTestConfig();

% Create test remote machine profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Specify a DISPATCHER object
DispatcherOpts.Profile = testProfile;
DispatcherOpts.CheckRequirements = false;  % Don't verify requirements
DispatcherOpts.AutoSave = false;

% Verify 'NumProcss'
try
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the default 'NumProcs'
    assert(isequal(myDispatcher.NumProcs,1))

    % Specify another 'NumProcs'
    DispatcherOpts.NumProcs = 8;
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the custom 'NumCPUs'
    assert(isequal(myDispatcher.NumProcs,DispatcherOpts.NumProcs))

catch e

    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)

end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testNumCPUs
% A test for 'NumCPUs' option.

% Create test remote configuration from the template
RemoteConfig = createTestConfig();

% Create test remote machine profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Specify a DISPATCHER object
DispatcherOpts.Profile = testProfile;
DispatcherOpts.CheckRequirements = false;  % Don't check for passwordless SSH
DispatcherOpts.AutoSave = false;

% Verify 'NumCPUs'
try
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the default 'NumCPUs'
    assert(isequal(myDispatcher.Internal.NumCPUs,1))

    % Specify another 'NumCPUs'
    DispatcherOpts.NumCPUs = 8;
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the custom 'NumCPUs'
    assert(isequal(myDispatcher.Internal.NumCPUs,DispatcherOpts.NumCPUs))

catch e

    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)

end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testCPUsPerNodeNumNodes
% A test for 'CPUsPerNode' and 'NumNodes' options.

% Create test remote configuration from the template
RemoteConfig = createTestConfig();

% Create test remote machine profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Specify a DISPATCHER object
DispatcherOpts.Profile = testProfile;
DispatcherOpts.CheckRequirements = false;  % Don't check for passwordless SSH
DispatcherOpts.AutoSave = false;

% Verify 'CPUsPerNode' and 'NumNodes'
try
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the default 'CPUsPerNode' and 'NumNodes'
    assert(isequal(myDispatcher.Internal.CPUsPerNode,1))
    assert(isequal(myDispatcher.Internal.NumNodes,1))

    % Specify another 'NumCPUs'
    DispatcherOpts.NumCPUs = 8;
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the custom setting
    assert(isequal(myDispatcher.Internal.CPUsPerNode,...
        DispatcherOpts.NumCPUs))
    assert(isequal(myDispatcher.Internal.NumNodes,1))

    % Specify another 'CPUsPerNode'
    DispatcherOpts.NumCPUs = 5;
    DispatcherOpts.CPUsPerNode = 5;
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the custom setting
    assert(isequal(myDispatcher.Internal.CPUsPerNode,...
        DispatcherOpts.CPUsPerNode))
    assert(isequal(myDispatcher.Internal.NumNodes,1))

    % Specify another 'NumNodes'
    DispatcherOpts.NumCPUs = 20;
    DispatcherOpts.CPUsPerNode = 4;
    DispatcherOpts.NumNodes = 5;
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the custom setting
    assert(isequal(myDispatcher.Internal.CPUsPerNode,...
        DispatcherOpts.CPUsPerNode))
    assert(isequal(myDispatcher.Internal.NumNodes,DispatcherOpts.NumNodes))

catch e

    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)

end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testAddToPath
% A test for 'AddToPath' option.

% Create test remote configuration from the template
RemoteConfig = createTestConfig();

% Create test remote machine profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Specify a DISPATCHER object
DispatcherOpts.Profile = testProfile;
DispatcherOpts.CheckRequirements = false;  % Don't check for passwordless SSH
DispatcherOpts.AutoSave = false;

% Verify 'AddToPath'
try
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the default 'AddToPath' property
    assert(isempty(myDispatcher.AddToPath))

    % Specify a custom 'AddToPath' option (char array)
    DispatcherOpts.AddToPath = 'codes/';
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the specified value (it becomes a cell array)
    assert(isequal(myDispatcher.AddToPath,{DispatcherOpts.AddToPath}))

    % Specify a custom 'AddToPath' option (cell array)
    DispatcherOpts.AddToPath = {'codes/','library'};
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the specified value
    assert(isequal(myDispatcher.AddToPath,DispatcherOpts.AddToPath))

catch e

    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)

end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testAddTreeToPath
% A test for 'AddTreeToPath' option.

% Create test remote configuration from the template
RemoteConfig = createTestConfig();

% Create test remote machine profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Specify a DISPATCHER object
DispatcherOpts.Profile = testProfile;
DispatcherOpts.CheckRequirements = false;  % Don't check for passwordless SSH
DispatcherOpts.AutoSave = false;

% Verify the default value
try
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the default 'AddToPath' property
    assert(isempty(myDispatcher.AddTreeToPath))

    % Specify a custom 'AddTreeToPath' option (char array)
    DispatcherOpts.AddTreeToPath = 'codes/';
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the specified value (it becomes a cell array)
    assert(isequal(myDispatcher.AddTreeToPath,...
        {DispatcherOpts.AddTreeToPath}))

    % Specify a custom 'AddTreeToPath' option (cell array)
    DispatcherOpts.AddTreeToPath = {'codes/','library'};
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the specified value
    assert(isequal(myDispatcher.AddTreeToPath,...
        DispatcherOpts.AddTreeToPath))
    
catch e
    
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)

end
rmdir(testDir,'s')
    
end


%% ------------------------------------------------------------------------
function testExecMode
% A test for 'ExecMode' option.

% Create test remote configuration from the template
RemoteConfig = createTestConfig();

% Create test remote machine profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Get the default value
execModeRef = uq_Dispatcher_params_getDefaultOpt('execmode');

% Specify a DISPATCHER object
DispatcherOpts.Profile = testProfile;
DispatcherOpts.CheckRequirements = false;  % Don't check for passwordless SSH
DispatcherOpts.AutoSave = false;

% Verify 'ExecMode'
try
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the default value
    assert(isequal(myDispatcher.ExecMode,execModeRef))
    
    % Set a custom value
    DispatcherOpts.ExecMode = 'async';
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the custom value
    assert(isequal(myDispatcher.ExecMode,DispatcherOpts.ExecMode))
    
catch e
    
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)

end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testSSHClient
% A test for 'SSHClient' option

% Create test remote configuration from the template
RemoteConfig = createTestConfig();

% Create test remote machine profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Get default reference value
if ispc
    SSHClientRef = uq_Dispatcher_params_getDefaultOpt('putty');
else
    SSHClientRef = uq_Dispatcher_params_getDefaultOpt('openssh');
end

% Specify a DISPATCHER object
DispatcherOpts.Profile = testProfile;
DispatcherOpts.CheckRequirements = false;  % Don't check for passwordless SSH
DispatcherOpts.AutoSave = false;

% Verify 'SSHClient'
try
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the default value
    assert(isequal(myDispatcher.Internal.SSHClient,SSHClientRef))
    
    % Set a custom value
    DispatcherOpts.SSHClient = SSHClientRef;
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the custom value
    assert(isequal(myDispatcher.Internal.SSHClient,SSHClientRef))

catch e
    
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)

end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testFetchStreams
% A test for 'FetchStreams' option.

% Create test remote configuration from the template
RemoteConfig = createTestConfig();

% Create test remote machine profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Get the default value
fetchStreamsRef = uq_Dispatcher_params_getDefaultOpt('fetchStreams');

% Specify a DISPATCHER object
DispatcherOpts.Profile = testProfile;
DispatcherOpts.CheckRequirements = false;  % Don't check for passwordless SSH
DispatcherOpts.AutoSave = false;

% Verify 'FetchStreams'
try
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the default value
    assert(isequal(myDispatcher.Internal.FetchStreams,...
        fetchStreamsRef))
    
    % Set a custom value
    DispatcherOpts.FetchStreams = true;
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the custom value
    assert(isequal(myDispatcher.Internal.FetchStreams,...
        DispatcherOpts.FetchStreams))

catch e
    
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)

end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testJobWallTime
% A test for 'JobWallTime' option.

% Create test remote configuration from the template
RemoteConfig = createTestConfig();

% Create test remote machine profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Get the default value
jobWallTimeRef = uq_Dispatcher_params_getDefaultOpt('jobwalltime');

% Specify a DISPATCHER object
DispatcherOpts.Profile = testProfile;
DispatcherOpts.CheckRequirements = false;  % Don't check for passwordless SSH
DispatcherOpts.AutoSave = false;

% Verify 'JobWallTime'
try
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the default value
    assert(isequal(myDispatcher.JobWallTime,jobWallTimeRef))
    
    % Set a custom value
    DispatcherOpts.JobWallTime = 120;
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the custom value
    assert(isequal(myDispatcher.JobWallTime,DispatcherOpts.JobWallTime))

catch e
    
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)

end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testSyncTimeOut
% A test for 'SyncTimeOut' option.

% Create test remote configuration from the template
RemoteConfig = createTestConfig();

% Create test remote machine profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Get the default value
syncTimeoutRef = uq_Dispatcher_params_getDefaultOpt('synctimeout');

% Specify a DISPATCHER object
DispatcherOpts.Profile = testProfile;
DispatcherOpts.CheckRequirements = false;  % Don't check for passwordless SSH
DispatcherOpts.AutoSave = false;

% Verify 'SyncTimeout'
try
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the default value
    assert(isequal(myDispatcher.SyncTimeout,syncTimeoutRef))
    
    % Set a custom value
    DispatcherOpts.SyncTimeout = 120;
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the custom value
    assert(isequal(myDispatcher.SyncTimeout,DispatcherOpts.SyncTimeout))

catch e
    
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)

end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testCheckInterval
% A test for 'CheckInterval' option.

% Create test remote configuration from the template
RemoteConfig = createTestConfig();

% Create test remote machine profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Get the default value
checkIntervalRef = uq_Dispatcher_params_getDefaultOpt('checkinterval');

% Specify a DISPATCHER object
DispatcherOpts.Profile = testProfile;
DispatcherOpts.CheckRequirements = false;  % Don't check for passwordless SSH
DispatcherOpts.AutoSave = false;

% Verify 'CheckInterval'
try
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the default value
    assert(isequal(myDispatcher.Internal.CheckInterval,checkIntervalRef))
    
    % Set a custom value
    DispatcherOpts.CheckInterval = 10;
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the custom value
    assert(isequal(myDispatcher.Internal.CheckInterval,...
        DispatcherOpts.CheckInterval))

catch e
    
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)

end
rmdir(testDir,'s')
end


%% ------------------------------------------------------------------------
function testAutoSave
% A test for 'AutoSave' option.

% Create test remote configuration from the template
RemoteConfig = createTestConfig();

% Create test remote machine profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Get the default value
autoSaveRef = uq_Dispatcher_params_getDefaultOpt('autosave');

% Specify a DISPATCHER object
DispatcherOpts.Name = uq_createUniqueID('uuid');
DispatcherOpts.Profile = testProfile;
DispatcherOpts.CheckRequirements = false;  % Don't check for passwordless SSH

% Verify 'CheckInterval'
try
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the default value
    assert(isequal(myDispatcher.Internal.AutoSave,autoSaveRef))
    % Cleanup
    delete(myDispatcher.Internal.AutoSaveFile)
    
    % Set a custom value
    DispatcherOpts.AutoSave = false;
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Verify the custom value
    assert(~myDispatcher.Internal.AutoSave)

catch e
    delete(myDispatcher.Internal.AutoSaveFile)
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)

end
rmdir(testDir,'s')
end


%% ------------------------------------------------------------------------
function RemoteConfig = createTestConfig()
% A local helper function to create a struct with the common RemoteConfig.

RemoteConfig.Username = 'jdoubt';
RemoteConfig.Hostname = 'localhost';
RemoteConfig.PrivateKey = 'myPrivateKey';
RemoteConfig.RemoteFolder = '/home/jdoubt/temp';

end
