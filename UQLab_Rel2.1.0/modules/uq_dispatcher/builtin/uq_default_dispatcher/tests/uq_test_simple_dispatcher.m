function success = uq_test_simple_dispatcher(level, TestProfile)
% success = UQ_TEST_DISPATCHER(level) creates a simple model and uses the
% "test" profile to run it in parallel (2 CPUs) and checks if the returned
% results are correct (right dimension, etc.).
% If the test is successful, success = 1, otherwise, success = 0.
success = 1;

%% Test arguments:
if nargin < 2
    TestProfile = 'test';
end
if nargin < 1
    level = 'normal';
end

%% Start UQLab:
uqlab('-nosplash');

%% Create a simple model:
ModelOpts.mString = 'X(:, 1) - X(:, 2)';
ModelOpts.isVectorized = true;
mhandle = uq_createModel(ModelOpts);

%% Create a dispatcher with the test profile:

DispatcherOpts.Name = 'Test Dispatcher';
DispatcherOpts.Type = 'uq_default_dispatcher';
DispatcherOpts.Profile = TestProfile;
DispatcherOpts.KeepFiles = 'remotely';
DispatcherOpts.TotalCPUs = 2;
DispatcherOpts.Timeout = 20*60; % 20 min timeout.
DispatcherOpts.CheckInterval = 1;
DispatcherOpts.JobSettings.OutputFile = 'DispatcherTest.out';
DispatcherOpts.JobSettings.ErrorFile = 'DispatcherTest.err';
DispatcherOpts.JobSettings.WallTime = '20';

% Creation of the module
% (To be replaced by uq_createDispatcher...)
% dhandle = UQ.dispatcher.add_module(DispatcherOpts.Name, DispatcherOpts.Type, DispatcherOpts);
% UQ_workflow.set_workflow({'dispatcher'}, {DispatcherOpts.Name});
% uq_retrieveSession;
myDispatcher = uq_createDispatcher(DispatcherOpts);

%% Test:

% 1) Simple test, higher num. of points than CPUs:

% Create a matrix such that:
% A' = [ 1, 2, 3, 4, 5 ]
%     [ 1, 1, 1, 1, 1 ]
%
% So, Y = M(A) = [0, 1, ..., 4]
%
A = ones(5, 2);
A(:, 1) = 1:5;

Y = uq_evalModel(mhandle, A, 'HPC');

if length(Y) ~= 5 || ~all(Y == (0:4)')
    success = 0;
end

% 2) Higher num. of CUPs than points:
B = [1 , 2];

Y = uq_evalModel(mhandle, B, 'HPC');

if length(Y) ~= 1 || Y ~= -1
    success = 0;
end






