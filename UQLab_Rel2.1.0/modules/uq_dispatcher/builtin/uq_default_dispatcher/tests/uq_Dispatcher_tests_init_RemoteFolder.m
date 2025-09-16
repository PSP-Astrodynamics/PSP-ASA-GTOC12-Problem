function pass = uq_Dispatcher_tests_init_RemoteFolder(level)
%UQ_DISPATCHER_TESTS_INIT_REMOTEFOLDER tests the parsing of the options
%   related to the directory in the remote machine. The options are
%   specificed in the profile file and read during the initialization of a
%   DISPATCHER object.

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
% A test for default option.
RemoteConfig.Username = 'jdoubt';
RemoteConfig.Hostname = 'localhost';
RemoteConfig.PrivateKey = 'myPrivateKey';
RemoteConfig.RemoteFolder = 'home/jdoubt/tmp';

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Read and verify the option
try
    % Read the profile file
    RemoteConfigRead = uq_Dispatcher_readProfile(testProfile);
    % Verify the specified 'RemoteFolder'
    assert(isequal(RemoteConfigRead.RemoteFolder,...
        RemoteConfig.RemoteFolder))
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testTrailingSlash()
% A test for a case with a trailing slash.
RemoteConfig.Username = 'jdoubt';
RemoteConfig.Hostname = 'localhost';
RemoteConfig.PrivateKey = 'myPrivateKey';
RemoteConfig.RemoteFolder = 'home/jdoubt/tmp/';

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Read and verify the option
try
    % Read the profile file
    RemoteConfigRead = uq_Dispatcher_readProfile(testProfile);
    % Verify the specified 'RemoteFolder' (remove the trailing slash)
    assert(isequal(RemoteConfigRead.RemoteFolder,...
        RemoteConfig.RemoteFolder(1:end-1)))
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testTildeNotation()
% A test for using a tilde notation as $HOME; this should throw an error.
RemoteConfig.Username = 'jdoubt';
RemoteConfig.Hostname = 'localhost';
RemoteConfig.PrivateKey = 'myPrivateKey';
RemoteConfig.RemoteFolder = '~/tmp';

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Read and verify the option

% This is the expected error message from parsing the profile file
msg = 'Directory in the remote machine must not be specified with tilde.';
try
    % Read the profile file
    uq_Dispatcher_readProfile(testProfile);
    error('Tilde notation is not supported, should throw an error.')
catch e
    rmdir(testDir,'s')
    if ~strcmpi(e.message,msg)
        fprintf('\n')
        rethrow(e)
    end
end

end
