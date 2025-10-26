function pass = uq_Dispatcher_tests_init_Scheduler(level)
%UQ_DISPATCHER_TESTS_INIT_SCHEDULEROPTION tests the initialization of a
%   Dispatcher object with user-specified job scheduler options in the
%   remote machine profile file.

%% Initialize test
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
function testDefault
% A test for the default (unspecified) job scheduler.
defScheduler = 'none';
SchedulerRef = uq_Dispatcher_params_getScheduler(defScheduler);

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

try
    RemoteConfig = uq_Dispatcher_readProfile(testProfile);

    assert(isequal(RemoteConfig.Scheduler,defScheduler))
    assert(isequal(RemoteConfig.SchedulerVars,SchedulerRef))
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testSLURM
% A test for the 'slurm' job scheduler.
scheduler = 'slurm';
SchedulerRef = uq_Dispatcher_params_getScheduler(scheduler);

% Set up a profile file
if ispc
    RemoteConfig.SavedSession = 'mySavedSession';
else
    RemoteConfig.Username = 'myUsername';
    RemoteConfig.Hostname = 'myHostname';
    RemoteConfig.PrivateKey = 'myPrivateKey';
end
RemoteConfig.RemoteFolder = '/tmp';

% Slurm as the scheduler
RemoteConfig.Scheduler = 'slurm';

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

try
    % Read the profile file
    RemoteConfig = uq_Dispatcher_readProfile(testProfile);
    % Verify the scheduler name
    assert(isequal(RemoteConfig.Scheduler,'slurm'))
    % Verify the scheduler-specific variables
    assert(isequal(RemoteConfig.SchedulerVars,SchedulerRef))
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

% Modify one of the default setting
SchedulerRef.SubmitOutputPattern = '[1-9]+';
RemoteConfig.SchedulerVars.SubmitOutputPattern = sprintf('%s',...
    SchedulerRef.SubmitOutputPattern);

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

try
    % Read the profile file
    RemoteConfig = uq_Dispatcher_readProfile(testProfile);
    % Verify the scheduler name
    assert(isequal(RemoteConfig.Scheduler,'slurm'))
    % Verify the scheduler-specific variables
    assert(isequal(RemoteConfig.SchedulerVars,SchedulerRef))
catch e
    rmdir(testDir,'s')
    fprintf('\n')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testLSF
% A test for the 'lsf' job scheduler.
scheduler = 'lsf';
SchedulerRef = uq_Dispatcher_params_getScheduler(scheduler);

% Set up a profile file
if ispc
    RemoteConfig.SavedSession = 'mySavedSession';
else
    RemoteConfig.Username = 'myUsername';
    RemoteConfig.Hostname = 'myHostname';
    RemoteConfig.PrivateKey = 'myPrivateKey';
end
RemoteConfig.RemoteFolder = '/tmp';

% LSF as the scheduler
RemoteConfig.Scheduler = 'lsf';

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

try
    % Read the profile file
    RemoteConfig = uq_Dispatcher_readProfile(testProfile);
    % Verify the scheduler name
    assert(isequal(RemoteConfig.Scheduler,scheduler))
    % Verify the scheduler-specific variables
    assert(isequal(RemoteConfig.SchedulerVars,SchedulerRef))
catch e
    fprintf('\n')
    rmdir(testDir,'s')
    rethrow(e)
end
rmdir(testDir,'s')

% Modify one of the default settings
SchedulerRef.JobNameOption = '--job-name=%s';
RemoteConfig.SchedulerVars.JobNameOption = sprintf('%s',...
    SchedulerRef.JobNameOption);

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

try
    % Read the profile file
    RemoteConfig = uq_Dispatcher_readProfile(testProfile);
    % Verify the scheduler name
    assert(isequal(RemoteConfig.Scheduler,scheduler))
    % Verify the scheduler-specific variables
    assert(isequal(RemoteConfig.SchedulerVars,SchedulerRef))
catch e
    fprintf('\n')
    rmdir(testDir,'s')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testPBS
% A test for the 'pbs' job scheduler.
scheduler = 'pbs';
SchedulerRef = uq_Dispatcher_params_getScheduler(scheduler);

% Set up a profile file
if ispc
    RemoteConfig.SavedSession = 'mySavedSession';
else
    RemoteConfig.Username = 'myUsername';
    RemoteConfig.Hostname = 'myHostname';
    RemoteConfig.PrivateKey = 'myPrivateKey';
end
RemoteConfig.RemoteFolder = '/tmp';

% LSF as the scheduler
RemoteConfig.Scheduler = sprintf('%s',scheduler);

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

try
    % Read the profile file
    RemoteConfig = uq_Dispatcher_readProfile(testProfile);
    % Verify the scheduler name
    assert(isequal(RemoteConfig.Scheduler,scheduler))
    % Verify the scheduler-specific variables
    assert(isequal(RemoteConfig.SchedulerVars,SchedulerRef))
catch e
    fprintf('\n')
    rmdir(testDir,'s')
    rethrow(e)
end
rmdir(testDir,'s')

% Modify one of the default settings
SchedulerRef.Pragma = '#BSUB';
RemoteConfig.SchedulerVars.Pragma = sprintf('%s',...
    SchedulerRef.Pragma);

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

try
    % Read the profile file
    RemoteConfig = uq_Dispatcher_readProfile(testProfile);
    % Verify the scheduler name
    assert(isequal(RemoteConfig.Scheduler,scheduler))
    % Verify the scheduler-specific variables
    assert(isequal(RemoteConfig.SchedulerVars,SchedulerRef))
catch e
    fprintf('\n')
    rmdir(testDir,'s')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testTORQUE
% A test for the 'torque' job scheduler.
scheduler = 'torque';
SchedulerRef = uq_Dispatcher_params_getScheduler(scheduler);

% Set up a profile file
if ispc
    RemoteConfig.SavedSession = 'mySavedSession';
else
    RemoteConfig.Username = 'myUsername';
    RemoteConfig.Hostname = 'myHostname';
    RemoteConfig.PrivateKey = 'myPrivateKey';
end
RemoteConfig.RemoteFolder = '/tmp';

% TORQUE as the scheduler
RemoteConfig.Scheduler = sprintf('%s',scheduler);

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

try
    % Read the profile file
    RemoteConfig = uq_Dispatcher_readProfile(testProfile);
    % Verify the scheduler name
    assert(isequal(RemoteConfig.Scheduler,scheduler))
    % Verify the scheduler-specific variables
    assert(isequal(RemoteConfig.SchedulerVars,SchedulerRef))
catch e
    fprintf('\n')
    rmdir(testDir,'s')
    rethrow(e)
end
rmdir(testDir,'s')

% Modify one of the default settings
SchedulerRef.CPUsOption = '-n %d';
RemoteConfig.SchedulerVars.CPUsOption = sprintf('%s',...
    SchedulerRef.CPUsOption);

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

try
    % Read the profile file
    RemoteConfig = uq_Dispatcher_readProfile(testProfile);
    % Verify the scheduler name
    assert(isequal(RemoteConfig.Scheduler,scheduler))
    % Verify the scheduler-specific variables
    assert(isequal(RemoteConfig.SchedulerVars,SchedulerRef))
catch e
    fprintf('\n')
    rmdir(testDir,'s')
    rethrow(e)
end
rmdir(testDir,'s')

end


%% ------------------------------------------------------------------------
function testCustom
% A test for a 'custom' job scheduler (everything must be specified).
scheduler = 'custom';
SchedulerRef = uq_Dispatcher_params_getScheduler(scheduler);

% Set up a profile file
if ispc
    RemoteConfig.SavedSession = 'mySavedSession';
else
    RemoteConfig.Username = 'myUsername';
    RemoteConfig.Hostname = 'myHostname';
    RemoteConfig.PrivateKey = 'myPrivateKey';
end
RemoteConfig.RemoteFolder = '/tmp';

% Specify custom scheduler
RemoteConfig.Scheduler = sprintf('%s', scheduler);
RemoteConfig.SchedulerVars.JobNameOption = '';
RemoteConfig.SchedulerVars.NodeNo = '0';
RemoteConfig.SchedulerVars.WorkingDirectory = '';
RemoteConfig.SchedulerVars.HostFile = '';
RemoteConfig.SchedulerVars.Pragma = '';
RemoteConfig.SchedulerVars.StdOutFileOption = '';
RemoteConfig.SchedulerVars.StdErrFileOption = '';
RemoteConfig.SchedulerVars.WallTimeOption = '';
RemoteConfig.SchedulerVars.NodesOption = '';
RemoteConfig.SchedulerVars.CPUsOption = '';
RemoteConfig.SchedulerVars.NodesCPUsOption = '';
RemoteConfig.SchedulerVars.SubmitCommand = '';
RemoteConfig.SchedulerVars.CancelCommand = '';
RemoteConfig.SchedulerVars.SubmitOutputPattern = '';
RemoteConfig.SchedulerVars.CustomSettings = {};

% Create the test profile file
[testProfile,testDir] = ...
    uq_Dispatcher_tests_helper_createTestProfileFile(RemoteConfig);

try
    % Read the profile file
    RemoteConfig = uq_Dispatcher_readProfile(testProfile);
    % Verify the scheduler name
    assert(isequal(RemoteConfig.Scheduler,scheduler))
    % Verify the scheduler-specific variables
    assert(isequal(RemoteConfig.SchedulerVars,SchedulerRef))
catch e
    fprintf('\n')
    rmdir(testDir,'s')
    rethrow(e)
end
rmdir(testDir,'s')

end
