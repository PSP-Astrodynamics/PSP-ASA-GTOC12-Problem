function pass = uq_Dispatcher_tests_init_Authentication(level)
%UQ_DISPATCHER_TESTS_INIT_AUTHENTICATION tests the parsing of the options
%   related to the authentication specification for the SSH connection. The
%   options are specified in the profile file and read during the
%   initialization of a DISPATCHER object.

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
function testPuTTYSavedSession()
% A test for using PuTTY saved session.
RemoteConfig.SavedSession = 'mySavedSession';
RemoteConfig.RemoteFolder = 'home/jdoubt/tmp';

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Read and verify the option
try
    % Read the profile file
    RemoteConfigRead = uq_Dispatcher_readProfile(testProfile);
    % Verify the specified 'SavedSession'
    assert(isequal(RemoteConfigRead.SavedSession,...
        RemoteConfig.SavedSession))
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testUsernameHostname()
% A test for using username@hostname without private key.
RemoteConfig.Username = 'jdoubt';
RemoteConfig.Hostname = 'localhost';
RemoteConfig.RemoteFolder = 'home/jdoubt/tmp';

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Read and verify the option
if ispc
    % In a Windows PC this should throw an error
    try
        % Read the profile file
        msg = 'In Windows PC, a private key must be specified.';
        uq_Dispatcher_readProfile(testProfile);
        error(msg)
    catch e
        rmdir(testDir,'s')
        if strcmpi(e.message,msg)
            fprintf('\n')
            rethrow(e)
        end
    end
else
    try
        % Read the profile file
        RemoteConfigRead = uq_Dispatcher_readProfile(testProfile);
        % Verify the specified 'Username' and 'Hostname'
        assert(isequal(RemoteConfigRead.Username,...
            RemoteConfig.Username))
        assert(isequal(RemoteConfigRead.Hostname,...
            RemoteConfig.Hostname))
    catch e
        rmdir(testDir,'s')
        fprintf('\n')
        rethrow(e)
    end
    rmdir(testDir,'s')
end

end


%% ------------------------------------------------------------------------
function testUsernameHostnamePrivateKey()
% A test for using username@hostname with private key.
RemoteConfig.Username = 'jdoubt';
RemoteConfig.Hostname = 'localhost';
RemoteConfig.PrivateKey = ['C:\temp dir\', uq_createUniqueID('uuid')];
RemoteConfig.RemoteFolder = 'home/jdoubt/tmp';

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

try
    % Read the profile file
    RemoteConfigRead = uq_Dispatcher_readProfile(testProfile);
    % Verify the specified 'Username', 'Hostname', and 'PrivateKey'
    assert(isequal(RemoteConfigRead.Username,...
        RemoteConfig.Username))
    assert(isequal(RemoteConfigRead.Hostname,...
        RemoteConfig.Hostname))
    assert(isequal(RemoteConfigRead.PrivateKey,...
        RemoteConfig.PrivateKey))
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testIncompleteInfo()
% A test for incomplete information, it should throw an error.

% Username only
RemoteConfig.Username = 'jdoubt';
RemoteConfig.RemoteFolder = 'home/jdoubt/tmp';

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

try
    % Read the profile file
    msg = 'No Hostname is specified, should throw an error.';
    uq_Dispatcher_readProfile(testProfile);
    rmdir(testDir,'s')
    error(msg)
catch e
    rmdir(testDir,'s')
    if strcmpi(e.message,msg)
        fprintf('\n')
        rethrow(e)
    end
end

clearvars('RemoteConfig')
% Hostname only
RemoteConfig.Hostname = 'localhost';
RemoteConfig.RemoteFolder = 'home/jdoubt/tmp';

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

try
    % Read the profile file
    msg = 'No Username is specified, should throw an error.';
    uq_Dispatcher_readProfile(testProfile);
    error(msg)
catch e
    rmdir(testDir,'s')
    if strcmpi(e.message,msg)
        fprintf('\n')
        rethrow(e)
    end
end

end


%% ------------------------------------------------------------------------
function testInconsistentInfo()
% A test for using inconsistent information, i.e., both saved session and
% username@hostname are specified. This should throw an error.
RemoteConfig.Username = 'jdoubt';
RemoteConfig.Hostname = 'localhost';
RemoteConfig.SavedSession = 'mySavedSession';
RemoteConfig.RemoteFolder = 'home/jdoubt/tmp';

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

try
    % Read the profile file
    msg = 'Inconsistent options specified, should throw an error.';
    uq_Dispatcher_readProfile(testProfile);
    error(msg)
catch e
    rmdir(testDir,'s')
    if strcmpi(e.message,msg)
        fprintf('\n')
        rethrow(e)
    end
end

end
