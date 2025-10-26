function [pass,errMsg] = uq_Dispatcher_tests_uq_deleteJob(level)

if nargin < 1
    level = 'normal';
end

uqlab('-nosplash');

fprintf('\nRunning: | %s | %s...\n', level, mfilename)

%% Setup

% Dispatcher unit
DispatcherOpts.Profile = 'myCredentialEuler';
DispatcherOpts.Type = 'uq_default_dispatcher';
DispatcherOpts.TotalCPUs = 1;
DispatcherOpts.Display = 'verbose';

myDispatcher = uq_createDispatcher(DispatcherOpts);

%%
errMsg = '';

testFile = 'uq_deleteJob';

%% Testing: Function File Exists
try
    if ~exist(testFile,'file')
        error('%s does not exist in PATH!',testFile)
    end
catch e
    pass = false;
    errMsg = e.message;
    return
end

%% Testing: Calling the Function without Arguments
% Should throw an error
try
    uq_deleteJob()
    pass = false;
    errMsg = sprintf(...
        '%s: Two inputs are required - Dispatcher unit and Job index!',...
        testFile);
    return
catch

end

%% Testing: Calling the Function without 'jobIdx' passed
% should throw an error
try
    uq_deleteJob(myDispatcher)
    pass = false;
    errMsg = sprintf(...
        '%s: Job index must always be specified!',...
        testFile);
    return
catch

end

%% Testing: Calling the Function with an Empty Jobs
% should throw an error
try
    uq_deleteJob(myDispatcher,1)
    pass = false;
    errMsg = sprintf(...
        '%s: Jobs of a Dispatcher unit must not be empty!',...
        testFile);
    return
catch

end

%% Testing: Calling the Function with an Index larger than Jobs length
% should throw an error

% Create a Job
[~,jobIdx] = uq_createJob(myDispatcher);

% Testing
try
    uq_deleteJob(myDispatcher,5)
    pass = false;
    errMsg = sprintf('%s: Index exceeds Jobs array bounds!',testFile);
    return
catch
    uq_deleteJob(myDispatcher,jobIdx);
end

%% Testing: Delete a 'pending' job

% Create a Job
[Job,jobIdx] = uq_createJob(myDispatcher);

% Create an SSH connection command
sshConnect = uq_Dispatcher_helper_createSSHConnect(myDispatcher);

% Maximum number of trials for attempting an SSH connection
maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;

% Test deleting 'pending' job
try
    deletedJob = uq_deleteJob(myDispatcher,jobIdx);
    % Check if the return Job is what's deleted
    if ~isequaln(Job,deletedJob)
        error('Return value of %s is inconsistent!',testFile)
    end
    % Check if the 'Jobs' property is empty
    if ~isempty(myDispatcher.Jobs)
        error('Number of post-deletion Jobs property is inconsistent!')
    end
    % Check if folder has been deleted
    remoteFolder = Job.RemoteFolder;
    if uq_Dispatcher_util_checkDir(remoteFolder,sshConnect,maxNumTrials)
        error('Remote folder of a deleted Job still exists!')
    end
catch e    
    pass = false;
    errMsg = e.message;
    return
end

%% Testing: Delete a 'completed' Job

% Create a Job
[~,jobIdx] = uq_createJob(myDispatcher);

% Submit a Job
uq_submitJob(myDispatcher,jobIdx);

% Wait for the Job
uq_waitJob(myDispatcher,jobIdx);
Job = myDispatcher.Jobs(jobIdx);

% Test deleting 'completed' job
try
    deletedJob = uq_deleteJob(myDispatcher,jobIdx);
    % Check if the return Job is what's deleted
    if ~isequaln(Job,deletedJob)
        error('Return value of %s is inconsistent!',testFile)
    end
    % Check if the 'Jobs' property is empty
    if ~isempty(myDispatcher.Jobs)
        error('Number of post-deletion Jobs property is inconsistent!')
    end
    % Check if folder has been deleted
    remoteFolder = Job.RemoteFolder;
    if uq_Dispatcher_util_checkDir(remoteFolder,sshConnect,maxNumTrials)
        error('Remote folder of a deleted Job still exists!')
    end
catch e    
    pass = false;
    errMsg = e.message;
    return
end

%% Testing: Delete a 'canceled' Job

% Create a Job
[~,jobIdx] = uq_createJob(myDispatcher);

% Submit a Job
uq_submitJob(myDispatcher,jobIdx);

% Wait for the Job
uq_cancelJob(myDispatcher,jobIdx);
Job = myDispatcher.Jobs(jobIdx);

% Test deleting 'completed' job
try
    deletedJob = uq_deleteJob(myDispatcher,jobIdx);
    % Check if the return Job is what's deleted
    if ~isequaln(Job,deletedJob)
        error('Return value of %s is inconsistent!',testFile)
    end
    % Check if the 'Jobs' property is empty
    if ~isempty(myDispatcher.Jobs)
        error('Number of post-deletion Jobs property is inconsistent!')
    end
    % Check if folder has been deleted
    remoteFolder = Job.RemoteFolder;
    if uq_Dispatcher_util_checkDir(remoteFolder,sshConnect,maxNumTrials)
        error('Remote folder of a deleted Job still exists!')
    end
catch e    
    pass = false;
    errMsg = e.message;
    return
end

%% Testing: Delete a 'submitted' Job
% Should throw an error (NOTE: we cannot make sure whether upon submission
% a Job will be in 'submitted' or 'running' state, how to definitely create
% a Job that will stay 'submitted' or 'running').

% Create a Job
[~,jobIdx] = uq_createJob(myDispatcher);

% Submit a Job
uq_submitJob(myDispatcher,jobIdx);

% Test deleting 'submitted' job
try
    uq_deleteJob(myDispatcher,jobIdx);
    
    pass = false;
    errMsg = sprintf(...
        '%s: ''running'' Job cannot be cleaned up!',...
        testFile);
    return
    
catch
    uq_waitJob(myDispatcher,jobIdx);
    uq_deleteJob(myDispatcher,jobIdx);
end

%% Testing: Delete a 'running' Job
% Should throw an error

% Create a Job
[~,jobIdx] = uq_createJob(myDispatcher);

% Submit a Job
uq_submitJob(myDispatcher,jobIdx);

% Test deleting 'running' job
try
    uq_deleteJob(myDispatcher,jobIdx);
    
    pass = false;
    errMsg = sprintf(...
        '%s: ''running'' Job cannot be cleaned up!',...
        testFile);
    return
    
catch
    uq_waitJob(myDispatcher,jobIdx);
    uq_deleteJob(myDispatcher,jobIdx);
end

%%
pass = true;

end
