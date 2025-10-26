function pass = uq_Dispatcher_tests_uq_findJob(level)
%
%
%   Summary:
%   

%% Initialize test
if nargin < 1
    level = 'normal';
end

uqlab('-nosplash')

fprintf('Running: | %s | %s...\n', level, mfilename)

pass = false;

%% Get all local test functions
testFunctions = localfunctions;

%% Execute all test functions
for i = 1:numel(testFunctions)
    feval(testFunctions{i})
    pass = true;
end

end


%% ------------------------------------------------------------------------
function testFindByName()
% Test if a Job can be found by its Name

% Create a Job
DispatcherOpts.HPCProfile = 'myCredentialGPUCruncher';
DispatcherOpts.SSHClient.SecureConnectArgs = '-T -o ConnectTimeOut=5';
DispatcherOpts.SSHClient.SecureCopyArgs = '-o ConnectTimeOut=5';
DispatcherOpts.Type = 'uq_default_dispatcher';

myDispatcher = uq_createDispatcher(DispatcherOpts,'-private');

inputs = {{linspace(1,10)}; {linspace(1,100)}; {linspace(1,1000)};...
    {[0 2 3]}; {[1 2 3 4 5 6 7]}; {rand(10,3)}};

try
    % Create a mapping Job
    uq_map(@sum, inputs, myDispatcher, 'AutoSubmit', false)

    % Get the Job by Name
    jobName = myDispatcher.Jobs.Name;

    [Job,jobIdx] = uq_findJob(myDispatcher, 'Name', jobName);

    % Compare Job
    assert(isequal(myDispatcher.Jobs(jobIdx),Job))

    % Clean up remote folder
    uq_deleteJob(myDispatcher,jobIdx)

catch ME
    sshConnect = uq_Dispatcher_helper_createSSHConnect(myDispatcher);
    % Maximum number of trials for attempting an SSH connection
    maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;
    % Delete possible remote folder
    remoteFolder = DispatcherObj.Jobs(jobIdx).RemoteFolder;
    % Safe guard against possible whitespaces in 'remoteFolder'
    remoteFolder = uq_Dispatcher_util_writePath(remoteFolder, 'linux', true);
    cmdName = 'rm';
    cmdArgs = {'-rf',remoteFolder};

    uq_Dispatcher_util_runCLICommand(...
        cmdName, cmdArgs, sshConnect, 'MaxNumTrials', maxNumTrials);
    
    rethrow(ME)
end

end


%% ------------------------------------------------------------------------
function testFindByStatus()
% Test if a Job can be found by its Status

% Create a Job
DispatcherOpts.HPCProfile = 'myCredentialGPUCruncher';
DispatcherOpts.Type = 'uq_default_dispatcher';
DispatcherOpts.SSHClient.SecureConnectArgs = '-T -o ConnectTimeOut=5';
DispatcherOpts.SSHClient.SecureCopyArgs = '-o ConnectTimeOut=5';

myDispatcher = uq_createDispatcher(DispatcherOpts);

inputs = {{linspace(1,10)}; {linspace(1,100)}; {linspace(1,1000)};...
    {[0 2 3]}; {[1 2 3 4 5 6 7]}; {rand(10,3)}};

try
    % Create a Job with mapping task
    uq_map(@sum, inputs, myDispatcher, 'AutoSubmit', false)

    % Get the Job by Name
    jobStatus = myDispatcher.Jobs.Status;

    [Job,jobIdx] = uq_findJob(myDispatcher, 'Status', jobStatus);

    % Compare Job
    assert(isequal(myDispatcher.Jobs(jobIdx),Job))

    % Clean up remote folder
    uq_deleteJob(myDispatcher,jobIdx)

catch ME
    sshConnect = uq_Dispatcher_helper_createSSHConnect(myDispatcher);
    % Maximum number of trials for attempting an SSH connection
    maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;
    % Delete possible remote folder
    jobIdx = 1;
    remoteFolder = DispatcherObj.Jobs(jobIdx).RemoteFolder;
    % Safe guard against possible whitespaces in 'remoteFolder'
    remoteFolder = uq_Dispatcher_util_writePath(remoteFolder, 'linux', true);
    cmdName = 'rm';
    cmdArgs = {'-rf',remoteFolder};

    uq_Dispatcher_util_runCLICommand(...
        cmdName, cmdArgs, sshConnect, 'MaxNumTrials', maxNumTrials);
    
    rethrow(ME)
end

end


%% ------------------------------------------------------------------------
function testFindByTag()
% Test if a Job can be found by its Tag.

% Create a Job
DispatcherOpts.HPCProfile = 'myCredentialGPUCruncher';
DispatcherOpts.Type = 'uq_default_dispatcher';
DispatcherOpts.SSHClient.SecureConnectArgs = '-T -o ConnectTimeOut=5';
DispatcherOpts.SSHClient.SecureCopyArgs = '-o ConnectTimeOut=5';

myDispatcher = uq_createDispatcher(DispatcherOpts);

inputs = {{linspace(1,10)}; {linspace(1,100)}; {linspace(1,1000)};...
    {[0 2 3]}; {[1 2 3 4 5 6 7]}; {rand(10,3)}};

try
    % Create a Job with mapping task
    uq_map(@sum, inputs, myDispatcher, 'AutoSubmit', false)

    % Get the Job by Name
    jobTag = myDispatcher.Jobs.Tag;

    [Job,jobIdx] = uq_findJob(myDispatcher, 'Tag', jobTag);

    % Compare Job
    assert(isequal(myDispatcher.Jobs(jobIdx),Job))

    % Clean up remote folder
    uq_deleteJob(myDispatcher,jobIdx)

catch ME
    sshConnect = uq_Dispatcher_helper_createSSHConnect(myDispatcher);
    % Maximum number of trials for attempting an SSH connection
    maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;
    % Delete possible remote folder
    jobIdx = 1;
    remoteFolder = DispatcherObj.Jobs(jobIdx).RemoteFolder;
    % Safe guard against possible whitespaces in 'remoteFolder'
    remoteFolder = uq_Dispatcher_util_writePath(remoteFolder, 'linux', true);
    cmdName = 'rm';
    cmdArgs = {'-rf',remoteFolder};

    uq_Dispatcher_util_runCLICommand(...
        cmdName, cmdArgs, sshConnect, 'MaxNumTrials', maxNumTrials);
    
    rethrow(ME)
end

end


%% ------------------------------------------------------------------------
function testFindByJobIDEmpty()
% Test if a Job can be found by its JobID.

% Create a Job
DispatcherOpts.HPCProfile = 'myCredentialGPUCruncher';
DispatcherOpts.Type = 'uq_default_dispatcher';
DispatcherOpts.SSHClient.SecureConnectArgs = '-T -o ConnectTimeOut=5';
DispatcherOpts.SSHClient.SecureCopyArgs = '-o ConnectTimeOut=5';

myDispatcher = uq_createDispatcher(DispatcherOpts);

inputs = {{linspace(1,10)}; {linspace(1,100)}; {linspace(1,1000)};...
    {[0 2 3]}; {[1 2 3 4 5 6 7]}; {rand(10,3)}};

try
    % Create a Job with mapping task
    uq_map(@sum, inputs, myDispatcher, 'AutoSubmit', false)

    % Get the Job by Name (Job is never submitted, so jobID is empty)
    jobID = myDispatcher.Jobs.JobID;

    [Job,jobIdx] = uq_findJob(myDispatcher, 'JobID', jobID);

    % Compare Job
    assert(isequal(myDispatcher.Jobs(jobIdx),Job))

    % Clean up remote folder
    uq_deleteJob(myDispatcher,jobIdx)

catch ME
    sshConnect = uq_Dispatcher_helper_createSSHConnect(myDispatcher);
    % Maximum number of trials for attempting an SSH connection
    maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;
    % Delete possible remote folder
    jobIdx = 1;
    remoteFolder = DispatcherObj.Jobs(jobIdx).RemoteFolder;
    % Safe guard against possible whitespaces in 'remoteFolder'
    remoteFolder = uq_Dispatcher_util_writePath(remoteFolder, 'linux', true);
    cmdName = 'rm';
    cmdArgs = {'-rf',remoteFolder};

    uq_Dispatcher_util_runCLICommand(...
        cmdName, cmdArgs, sshConnect, 'MaxNumTrials', maxNumTrials);
    
    rethrow(ME)
end

end

%% ------------------------------------------------------------------------
function testFindByJobID()
% Test if a Job can be found by its JobID.

% Create a Job
DispatcherOpts.HPCProfile = 'myCredentialGPUCruncher';
DispatcherOpts.Type = 'uq_default_dispatcher';
DispatcherOpts.SSHClient.SecureConnectArgs = '-T -o ConnectTimeOut=5';
DispatcherOpts.SSHClient.SecureCopyArgs = '-o ConnectTimeOut=5';

myDispatcher = uq_createDispatcher(DispatcherOpts);

inputs = {{linspace(1,10)}; {linspace(1,100)}; {linspace(1,1000)};...
    {[0 2 3]}; {[1 2 3 4 5 6 7]}; {rand(10,3)}};

try
    % Create a Job with mapping task (and submit)
    uq_map(@sum, inputs, myDispatcher)

    % Get the Job by Name
    jobID = myDispatcher.Jobs.JobID;

    [Job,jobIdx] = uq_findJob(myDispatcher, 'JobID', jobID);

    % Compare Job
    assert(isequal(myDispatcher.Jobs(jobIdx),Job))

    % Clean up remote folder
    uq_deleteJob(myDispatcher,jobIdx)

catch ME
    sshConnect = uq_Dispatcher_helper_createSSHConnect(myDispatcher);
    % Maximum number of trials for attempting an SSH connection
    maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;
    % Delete possible remote folder
    jobIdx = 1;
    remoteFolder = DispatcherObj.Jobs(jobIdx).RemoteFolder;
    % Safe guard against possible whitespaces in 'remoteFolder'
    remoteFolder = uq_Dispatcher_util_writePath(remoteFolder, 'linux', true);
    cmdName = 'rm';
    cmdArgs = {'-rf',remoteFolder};

    uq_Dispatcher_util_runCLICommand(...
        cmdName, cmdArgs, sshConnect, 'MaxNumTrials', maxNumTrials);
    
    rethrow(ME)
end

end


%% ------------------------------------------------------------------------
function testFindMultipleJobs()
% Test if multiple Jobs can be found by its Status

% Create a Job
DispatcherOpts.HPCProfile = 'myCredentialGPUCruncher';
DispatcherOpts.Type = 'uq_default_dispatcher';
DispatcherOpts.SSHClient.SecureConnectArgs = '-T -o ConnectTimeOut=5';
DispatcherOpts.SSHClient.SecureCopyArgs = '-o ConnectTimeOut=5';

myDispatcher = uq_createDispatcher(DispatcherOpts);

inputs = {{linspace(1,10)}; {linspace(1,100)}; {linspace(1,1000)};...
    {[0 2 3]}; {[1 2 3 4 5 6 7]}; {rand(10,3)}};

try
    % Create two mapping Jobs
    uq_map(@sum, inputs, myDispatcher, 'AutoSubmit', false)
    uq_map(@sum, inputs, myDispatcher, 'AutoSubmit', false)

    % Get the Job by Name
    jobNames = {myDispatcher.Jobs(1).Name};
    jobNames{end+1} = myDispatcher.Jobs(2).Name;

    [Jobs,jobIdc] = uq_findJob(myDispatcher, 'Name', jobNames);

    % Compare Job
    assert(isequal(myDispatcher.Jobs(jobIdc),Jobs))

    % Delete Jobs
    uq_deleteJob(myDispatcher,1)
    uq_deleteJob(myDispatcher,1)
    
catch ME
    % Delete possible remote folder
    sshConnect = uq_Dispatcher_helper_createSSHConnect(myDispatcher);
    % Maximum number of trials for attempting an SSH connection
    maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;
    for i = 1:2
        remoteFolder = DispatcherObj.Jobs(i).RemoteFolder;
        % Safe guard against possible whitespaces in 'remoteFolder'
        remoteFolder = uq_Dispatcher_util_writePath(...
            remoteFolder, 'linux', true);

        cmdName = 'rm';
        cmdArgs = {'-rf',remoteFolder};

        uq_Dispatcher_util_runCLICommand(...
            cmdName, cmdArgs, sshConnect, 'MaxNumTrials', maxNumTrials);
    end
    rethrow(ME)
end

end

%% ------------------------------------------------------------------------
function testFindNothing()
% Test if no Jobs can be found if with multiple queries that are too
% specific.

% Create a Job
DispatcherOpts.HPCProfile = 'myCredentialGPUCruncher';
DispatcherOpts.Type = 'uq_default_dispatcher';
DispatcherOpts.SSHClient.SecureConnectArgs = '-T -o ConnectTimeOut=5';
DispatcherOpts.SSHClient.SecureCopyArgs = '-o ConnectTimeOut=5';

myDispatcher = uq_createDispatcher(DispatcherOpts);

inputs = {{linspace(1,10)}; {linspace(1,100)}; {linspace(1,1000)};...
    {[0 2 3]}; {[1 2 3 4 5 6 7]}; {rand(10,3)}};

try
    % Create two mapping Jobs
    uq_map(@sum, inputs, myDispatcher, 'AutoSubmit', false)
    uq_map(@sum, inputs, myDispatcher, 'AutoSubmit', false)

    % Get the Job by Name
    jobName = myDispatcher.Jobs(1).Name;
    jobTag = myDispatcher.Jobs(2).Tag;

    Jobs = uq_findJob(myDispatcher, 'Name', jobName, 'Tag', jobTag);

    % Compare Job
    assert(isempty(Jobs))

    % Delete Jobs
    uq_deleteJob(myDispatcher,1)
    uq_deleteJob(myDispatcher,1)
    
catch ME
    % Delete possible remote folder
    sshConnect = uq_Dispatcher_helper_createSSHConnect(myDispatcher);
    % Maximum number of trials for attempting an SSH connection
    maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;
    for i = 1:2
        remoteFolder = DispatcherObj.Jobs(i).RemoteFolder;
        % Safe guard against possible whitespaces in 'remoteFolder'
        remoteFolder = uq_Dispatcher_util_writePath(...
            remoteFolder, 'linux', true);
        cmdName = 'rm';
        cmdArgs = {'-rf',remoteFolder};

        uq_Dispatcher_util_runCLICommand(...
            cmdName, cmdArgs, sshConnect, 'MaxNumTrials', maxNumTrials);
    end
    
    rethrow(ME)
end

end
