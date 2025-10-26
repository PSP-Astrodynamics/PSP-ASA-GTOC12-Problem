function pass = uq_Dispatcher_tests_init_MATLAB(level)
%UQ_DISPATCHER_TESTS_INIT_MATLABOPTION tests the parsing of MATLAB-related
%   options specified in the profile file. The options are specified in the
%   profile file and read read during the initialization of a DISPATCHER
%   object.

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
% A test for the default setting.

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
currentDir = fileparts(mfilename('fullpath'));
testDir = fullfile(currentDir,uq_createUniqueID());
mkdir(testDir)
testProfile = fullfile(testDir,'test_profile_file.m');
uq_Dispatcher_scripts_createProfile(testProfile,RemoteConfig)

% Read and verify the option
try
    % Read the profile file
    RemoteConfigRead = uq_Dispatcher_readProfile(testProfile);
    % Verify the default MATLAB command in the remote (default: empty)
    assert(isempty(RemoteConfigRead.MATLABCommand))
    % Verify the default MATLAB option in the remote (default: '-r')
    assert(isequal(RemoteConfigRead.MATLABOptions,'-r'))
    % Verify the default MATLAB single thread option (default: true)
    assert(RemoteConfigRead.MATLABSingleThread)
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testCustomMATLABCommand()
% A test for a custom setting for the 'MATLABCommand' field.

% Set up a profile file
if ispc
    RemoteConfig.SavedSession = 'mySavedSession';
else
    RemoteConfig.Username = 'myUsername';
    RemoteConfig.Hostname = 'myHostname';
    RemoteConfig.PrivateKey = 'myPrivateKey';
end
RemoteConfig.RemoteFolder = '/tmp';
RemoteConfig.MATLABCommand = '/usr/local/bin/matlab';

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Read and verify the option
try
    % Read the profile file
    RemoteConfigRead = uq_Dispatcher_readProfile(testProfile);
    % Verify the specified MATLAB command
    assert(isequal(RemoteConfigRead.MATLABCommand,...
        RemoteConfig.MATLABCommand))
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testCustomMATLABOptions()
% A test for a custom setting for the 'MATLABOptions' field.

% Set up a profile file
if ispc
    RemoteConfig.SavedSession = 'mySavedSession';
else
    RemoteConfig.Username = 'myUsername';
    RemoteConfig.Hostname = 'myHostname';
    RemoteConfig.PrivateKey = 'myPrivateKey';
end
RemoteConfig.RemoteFolder = '/tmp';
RemoteConfig.MATLABOptions = '-nodisplay -nodesktop -r';

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Read and verify the option
try
    % Read the profile file
    RemoteConfigRead = uq_Dispatcher_readProfile(testProfile);
    % Verify the specified MATLAB option
    assert(isequal(RemoteConfigRead.MATLABOptions,...
        RemoteConfig.MATLABOptions))
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testCustomMATLABSingleThread()
% A test for a custom setting for the 'MATLABSingleThread' field.

% Set up a profile file
if ispc
    RemoteConfig.SavedSession = 'mySavedSession';
else
    RemoteConfig.Username = 'myUsername';
    RemoteConfig.Hostname = 'myHostname';
    RemoteConfig.PrivateKey = 'myPrivateKey';
end
RemoteConfig.RemoteFolder = '/tmp';

% Specification via the 'MATLABSingleThread' field
RemoteConfig.MATLABSingleThread = false;

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Read and verify the option
try
    % Read the profile file
    RemoteConfigRead = uq_Dispatcher_readProfile(testProfile);
    % Verify the specified MATLAB single thread option
    assert(~RemoteConfigRead.MATLABSingleThread)
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

% Inconsistent specification via the option
RemoteConfig.MATLABOptions = '-singleCompThread';
RemoteConfig.MATLABSingleThread = false;

% Create the test profile file
currentDir = fileparts(mfilename('fullpath'));
testDir = fullfile(currentDir,uq_createUniqueID());
mkdir(testDir)
testProfile = fullfile(testDir,'test_profile_file.m');
uq_Dispatcher_scripts_createProfile(testProfile,RemoteConfig)

% Read and verify the option
try
    % Read the profile file
    uq_Dispatcher_readProfile(testProfile);
    rmdir(testDir,'s')
    error('Inconsistent specification should throw an error.')
catch e
    if strcmpi(e.message,'Inconsistent specification should throw an error.')
        fprintf('\n')
        rethrow(e)
    else
        rmdir(testDir,'s')
    end
end

% Specification via the option
RemoteConfig = rmfield(RemoteConfig,'MATLABSingleThread');
RemoteConfig.MATLABOptions = '-nodisplay -singleCompThread';

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Read and verify the option
try
    % Read the profile file
    RemoteConfigRead = uq_Dispatcher_readProfile(testProfile);
    % Verify the specified MATLAB single thread option
    assert(RemoteConfigRead.MATLABSingleThread)
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end
