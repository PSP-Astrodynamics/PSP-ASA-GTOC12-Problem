function pass = uq_Dispatcher_tests_init_PrevCommands(level)
%UQ_DISPATCHER_TESTS_INIT_PREVCOMMANDS tests the parsing of options related
%   to commands to be executed in each of the computing nodes. The options
%   are specified in the profile file and read during the initialization of
%   a DISPATCHER object.

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
% A test for the default 'PrevCommands' option.

% Set up a profile file
if ispc
    RemoteConfig.SavedSession = 'mySavedSession';
else
    RemoteConfig.Username = 'myUsername';
    RemoteConfig.Hostname = 'myHostname';
    RemoteConfig.PrivateKey = 'myPrivateKey';
end
RemoteConfig.RemoteFolder = 'home/jdoubt/tmp';

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Read and verify the option
try
    % Read the profile file
    RemoteConfigRead = uq_Dispatcher_readProfile(testProfile);
    % Verify the default 'PrevCommands' (default: empty)
    assert(isempty(RemoteConfigRead.PrevCommands))
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testCustomChar()
% A test for a custom 'PrevCommands' option specified as a char array.

% Set up a profile file
if ispc
    RemoteConfig.SavedSession = 'mySavedSession';
else
    RemoteConfig.Username = 'myUsername';
    RemoteConfig.Hostname = 'myHostname';
    RemoteConfig.PrivateKey = 'myPrivateKey';
end
RemoteConfig.RemoteFolder = 'home/jdoubt/tmp';

% Specify a custom 'PrevCommands'
RemoteConfig.PrevCommands = 'module load matlab/7.14';

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Read and verify the option
try
    % Read the profile file
    RemoteConfigRead = uq_Dispatcher_readProfile(testProfile);
    % Verify the specified 'PrevCommands' (it becomes a cell array)
    assert(isequal(RemoteConfigRead.PrevCommands,...
        {RemoteConfig.PrevCommands}))
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testCustomCell()
% A test for custom 'PrevCommands' options specified as a cell array.

% Set up a profile file
if ispc
    RemoteConfig.SavedSession = 'mySavedSession';
else
    RemoteConfig.Username = 'myUsername';
    RemoteConfig.Hostname = 'myHostname';
    RemoteConfig.PrivateKey = 'myPrivateKey';
end
RemoteConfig.RemoteFolder = 'home/jdoubt/tmp';

% Specify a custom 'PrevCommands'
RemoteConfig.PrevCommands = {...
    'module load matlab/7.14'; 'module load mpi'};

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Read and verify the option
try
    % Read the profile file
    RemoteConfigRead = uq_Dispatcher_readProfile(testProfile);
    % Verify the specified 'PrevCommands' (it becomes a cell array)
    assert(isequal(RemoteConfigRead.PrevCommands,RemoteConfig.PrevCommands))
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end
