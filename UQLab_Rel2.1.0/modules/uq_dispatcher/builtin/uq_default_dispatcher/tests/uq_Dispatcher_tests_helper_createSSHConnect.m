function pass = uq_Dispatcher_tests_helper_createSSHConnect(level)
%UQ_DISPATCHER_TESTS_HELPER_CREATESSHCONNECT tests a helper function to
%   create the command to connect to the remote machine via SSH.

%% Initialize test
if nargin < 1
    level = 'normal';
end

uqlab('-nosplash');

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
function testDefaultInputsPuTTY()
% A test for the case with default inputs using a PuTTY saved session.
sshConnectRef = 'plink -ssh -T mySessionName';

% Set up a profile file
RemoteConfig.SavedSession = 'mySessionName';
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
    % Get the command to establish the SSH connection
    sshConnect = uq_Dispatcher_helper_createSSHConnect(myDispatcher);
    % Verify the command to establish the SSH connection
    assert(strcmp(sshConnectRef,sshConnect))
catch e
    rmdir(testDir,'s')
    fprint('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testDefaultInputsOpenSSH()
% A test for the case with default inputs using the OpenSSH syntax for the
% session name.
username = 'myUsername';
hostname = 'myHostname';
privateKey = 'myPrivateKey';
if ispc
    sshConnectRef = sprintf('plink -ssh -T -i %s %s@%s',...
        privateKey, username, hostname);
else
    sshConnectRef = sprintf('ssh -T -i %s %s@%s',...
        privateKey, username, hostname);
end

% Set up a profile file
RemoteConfig.Username = username;
RemoteConfig.Hostname = hostname;
RemoteConfig.PrivateKey = privateKey;
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
    % Get the command to establish the SSH connection
    sshConnect = uq_Dispatcher_helper_createSSHConnect(myDispatcher);
    % Verify the command to establish the SSH connection
    assert(strcmp(sshConnectRef,sshConnect))
catch e
    delete(testProfile)
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testOpenSSHOptionsChar()
% A test for specifying additional options using a char array to make the
% command to establish an SSH connection with the OpenSSH syntax.
sshOpt = '-T -x -p 26';
username = 'myUsername';
hostname = 'myHostname';
if ispc
    % A test for private key location with spaces
    privateKey = '..\my Directory\myPrivateKey'; % Fictitious key
    % Safe guard against possible whitespaces in 'privateKey'
    quotedPrivateKey = uq_Dispatcher_util_writePath(privateKey, 'pc');
    sshConnectRef = sprintf('plink %s -i %s %s@%s',...
        sshOpt, quotedPrivateKey, username, hostname);
else
    % A test for private key location with spaces
    privateKey = '/home/user/key location/myPrivateKey';
    % Safe guard against possible whitespaces in 'privateKey'
    quotedPrivateKey = uq_Dispatcher_util_writePath(privateKey, 'linux');
    sshConnectRef = sprintf('ssh %s -i %s %s@%s',...
        sshOpt, quotedPrivateKey, username, hostname);
end

% Set up a profile file
RemoteConfig.Username = username;
RemoteConfig.Hostname = hostname;
RemoteConfig.PrivateKey = privateKey;
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
DispatcherOpts.SSHClient.SecureConnectArgs = sshOpt;

try
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Get the command to establish the SSH connection
    sshConnect = uq_Dispatcher_helper_createSSHConnect(myDispatcher);
    % Verify the command to establish the SSH connection
    assert(strcmp(sshConnectRef,sshConnect))
catch e
    delete(testProfile)
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testPuTTYOptionsChar()
% A test for specifying additional options using a char array to make the
% command to establish an SSH connection with PuTTY saved session.
sshOpt = '-T -x -p 26';
savedSession = 'mySavedSession';
sshConnectRef = sprintf('plink %s %s', sshOpt, savedSession);

% Set up a profile file
RemoteConfig.SavedSession = savedSession;
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
DispatcherOpts.SSHClient.SecureConnectArgs = sshOpt;

try
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Get the command to establish the SSH connection
    sshConnect = uq_Dispatcher_helper_createSSHConnect(myDispatcher);
    % Verify the command to establish the SSH connection
    assert(strcmp(sshConnectRef,sshConnect))
catch e
    delete(testProfile)
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testOpenSSHOptionsCell()
% A test for specifying additional options using a cell array to make the
% command to establish an SSH connection with the OpenSSH syntax.
sshOpts = {'-T', '-x', '-p 26'};
username = 'myUsername';
hostname = 'myHostname';
if ispc
    % A test for private key location with spaces
    privateKey = 'C:\path outside\path inside\myPrivateKey';
    % Safe guard against possible whitespaces in 'privateKey'
    quotedPrivateKey = uq_Dispatcher_util_writePath(privateKey, 'pc');
    sshConnectRef = sprintf('plink %s -i %s %s@%s',...
        strjoin(sshOpts), quotedPrivateKey, username, hostname);
else
    % A test for private key location with spaces
    privateKey = '/home/user/key location/myPrivateKey';
    % Safe guard against possible whitespaces in 'privateKey'
    quotedPrivateKey = uq_Dispatcher_util_writePath(privateKey, 'linux');
    sshConnectRef = sprintf('ssh %s -i %s %s@%s',...
        strjoin(sshOpts), quotedPrivateKey, username, hostname);
end

% Set up a profile file
RemoteConfig.Username = username;
RemoteConfig.Hostname = hostname;
RemoteConfig.PrivateKey = privateKey;
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
DispatcherOpts.SSHClient.SecureConnectArgs = sshOpts;

try
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Get the command to establish the SSH connection
    sshConnect = uq_Dispatcher_helper_createSSHConnect(myDispatcher);
    % Verify the command to establish the SSH connection
    assert(strcmp(sshConnectRef,sshConnect))
catch e
    delete(testProfile)
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testPuTTYOptionsCell()
% A test for specifying additional options using a cell array to make the
% command to establish an SSH connection with a PuTTY saved session.
sshOpts = {'-T', '-x', '-p 26'};
savedSession = 'mySavedSession';
sshConnectRef = sprintf('plink %s %s', strjoin(sshOpts), savedSession);

% Set up a profile file
RemoteConfig.SavedSession = savedSession;
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
DispatcherOpts.SSHClient.SecureConnectArgs = sshOpts;

try
    % Create a DISPATCHER object
    myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');
    % Get the command to establish the SSH connection
    sshConnect = uq_Dispatcher_helper_createSSHConnect(myDispatcher);
    % Verify the command to establish the SSH connection
    assert(strcmp(sshConnectRef,sshConnect))
catch e
    delete(testProfile)
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end
