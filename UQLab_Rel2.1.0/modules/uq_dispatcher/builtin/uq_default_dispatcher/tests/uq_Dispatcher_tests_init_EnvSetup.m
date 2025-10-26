function pass = uq_Dispatcher_tests_init_EnvSetup(level)
%UQ_DISPATCHER_TESTS_INIT_ENVSETUP tests the parsing of options related to
%   the remote machine environment setup. The options are specified in the
%   profile file and read during the initialization a DISPATCHER object.

%% Initialize the test
if nargin < 1
    level = 'normal';
end

uqlab('-nosplash')

fprintf('Running: | %s | %s...', level, mfilename)

%% Get all local tests functions
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
% A test for the default setting for the 'EnvSetup' field.

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
    % Verify the default EnvSetup (default: empty)
    assert(isempty(RemoteConfigRead.EnvSetup))
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testCustomChar()
% A test for a custom 'EnvSetup' option specified as a char array.

% Set up a profile file
if ispc
    RemoteConfig.SavedSession = 'mySavedSession';
else
    RemoteConfig.Username = 'myUsername';
    RemoteConfig.Hostname = 'myHostname';
    RemoteConfig.PrivateKey = 'myPrivateKey';
end
RemoteConfig.RemoteFolder = '/tmp';

% Specify a char array for 'EnvSetup'
RemoteConfig.EnvSetup = 'module load open_mpi';

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Read and verify the option
try
    % Read the profile file
    RemoteConfigRead = uq_Dispatcher_readProfile(testProfile);
    % Verify the specified EnvSetup (as a cell array)
    assert(isequal(RemoteConfigRead.EnvSetup,{RemoteConfig.EnvSetup}))
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testCustomCell()
% A test for custom 'EnvSetup' options specified as a cell array.

% Set up a profile file
if ispc
    RemoteConfig.SavedSession = 'mySavedSession';
else
    RemoteConfig.Username = 'myUsername';
    RemoteConfig.Hostname = 'myHostname';
    RemoteConfig.PrivateKey = 'myPrivateKey';
end
RemoteConfig.RemoteFolder = '/tmp';

% Specify a cell array for multiple entries of 'EnvSetup'
RemoteConfig.EnvSetup = {'module load open_mpi'; 'module load matlab'};

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Read and verify the option
try
    % Read the profile file
    RemoteConfigRead = uq_Dispatcher_readProfile(testProfile);
    % Verify the specified EnvSetup
    assert(isequal(RemoteConfigRead.EnvSetup,RemoteConfig.EnvSetup))
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end
