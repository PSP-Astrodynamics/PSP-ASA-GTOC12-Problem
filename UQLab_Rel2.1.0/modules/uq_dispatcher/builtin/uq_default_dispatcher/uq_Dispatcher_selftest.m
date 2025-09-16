function pass = uq_Dispatcher_selftest(level)
% UQ_KRIGING_SELFTEST carries out a suite non-regression and consistency checks for the Kriging module of UQLab.
%
%   PASS = UQ_KRIGING_SELFTEST tests the UQLab Kriging module using 
%   a suite of non-regression and consistency checks with the default level
%   ('normal').
%
%   See also uq_selftest_uq_metamodel

%% Initialize the test
%
uqlab('-nosplash')

if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end

pass = false;

%% Define the test names
%
TestNames = {...
    'uq_Dispatcher_tests_uq_getStatusChar',...
    'uq_Dispatcher_tests_util_computeDuration',...
    'uq_Dispatcher_tests_util_flattenCell',...
    'uq_Dispatcher_tests_util_isAsync',...
    'uq_Dispatcher_tests_bash_parseCommand',...
    'uq_Dispatcher_tests_bash_parseFormat',...
    'uq_Dispatcher_tests_bash_printData',...
    'uq_Dispatcher_tests_bash_setPATH',...
    'uq_Dispatcher_tests_helper_getSessionName',...
    'uq_Dispatcher_tests_helper_createSSHConnect',...
    'uq_Dispatcher_tests_init_Dispatcher',...
    'uq_Dispatcher_tests_init_Authentication',...
    'uq_Dispatcher_tests_init_RemoteFolder',...
    'uq_Dispatcher_tests_init_MATLAB',...
    'uq_Dispatcher_tests_init_UQLab',...
    'uq_Dispatcher_tests_init_EnvSetup',...
    'uq_Dispatcher_tests_init_PrevCommands',...
    'uq_Dispatcher_tests_init_MPI',...
    'uq_Dispatcher_tests_init_Scheduler',...
    'uq_Dispatcher_tests_init_Shebang'};

%% Recursively execute each test defined in TestNames
%
success = zeros(length(TestNames),1);
Times = zeros(length(TestNames),1);
TestTimer = tic;
Tprev = 0;
for iTest = 1 : length(TestNames)
    % obtain the function handle of current test from its name
    testFuncHandle = str2func(TestNames{iTest});
    % run test
    success(iTest) = testFuncHandle(level);
    % calculate the time required from the current test to execute
    Times(iTest) = toc(TestTimer) - Tprev;
    Tprev = Tprev + Times(iTest);
end

%% Print out the results table and info
%
Result = {'ERROR','OK'};
ResultChar = 60; % Character where the result of test is displayed
MinusLine(1:ResultChar+7) = deal('-');

fprintf('\n%s\n',MinusLine);
fprintf('UQ_SELFTEST_UQ_DISPATCHER RESULTS');
fprintf('\n%s\n',MinusLine);
for ii = 1:length(success)
    points(1:max(2,ResultChar-size(TestNames{ii},2))) = deal('.');
    fprintf('%s %s %s @ %g sec.\n',...
        TestNames{ii}, points, Result{success(ii)+1}, Times(ii));
    clear points
end
fprintf('%s\n',MinusLine);

%% Print the result of all tests.
%
if all(success)
    pass = true;
    fprintf('\n');
    fprintf('SUCCESS: uq_default_dispatcher module %s test was successful.\n',level);
end

if ~strcmpi(level,'normal')
    uq_Example_Dispatcher_01_BasicUsage
    uq_Example_Dispatcher_02_AdvancedUsage
    uq_Example_Dispatcher_03_UQLink
    uq_Example_Dispatcher_04_Map
end

end