function pass = uq_Dispatcher_tests_init_Shebang(level)
%UQ_DISPATCHER_TESTS_INIT_Shebang tests the parsing of the options
%   related to the selection of shell interpreter in the remote machine.
%   The options are specified in the profile file and read during the
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
function testDefaultCase()
% A test for the default case.
RemoteConfig.Username = 'jdoubt';
RemoteConfig.Hostname = 'localhost';
RemoteConfig.PrivateKey = 'myPrivateKey';
RemoteConfig.RemoteFolder = '/home/jdoubt/temp';

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Read and verify the option
try
    % Get the default value
    shebangRef = uq_Dispatcher_params_getDefaultOpt('Shebang');
    % Read the profile file
    RemoteConfigRead = uq_Dispatcher_readProfile(testProfile);
    % Verify the default EnvSetup (default: empty)
    assert(isequal(RemoteConfigRead.Shebang,shebangRef))
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testCustomCase()
% A test for a custom case.
RemoteConfig.Username = 'jdoubt';
RemoteConfig.Hostname = 'localhost';
RemoteConfig.PrivateKey = 'myPrivateKey';
RemoteConfig.RemoteFolder = '/home/jdoubt/temp';

% Specify a custom shebang
RemoteConfig.Shebang = '#!/bin/sh';

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

% Read and verify the option
try
    % Read the profile file
    RemoteConfigRead = uq_Dispatcher_readProfile(testProfile);
    % Verify the default EnvSetup (default: empty)
    assert(isequal(RemoteConfigRead.Shebang,RemoteConfig.Shebang))
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end
