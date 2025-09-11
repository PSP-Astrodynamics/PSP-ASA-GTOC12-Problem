function pass = uq_selftest_uq_default_dispatcher(level)
% UQ_SELFTEST_UQ_DEFAULT_DISPATCHER conducts a selftest for the default
%   Dispatcher module.

%%
uqlab('-nosplash');

if nargin < 1
    level = 'normal'; 
end   

pass = 0;

%% Test Names are defined here
TestNames = {...
    'uq_Dispatcher_tests_util_computeDuration',...
    'uq_Dispatcher_tests_bash_parseCommand',...
    'uq_Dispatcher_tests_bash_parseFormat',...
    'uq_Dispatcher_tests_bash_printData',...
    'uq_Dispatcher_tests_bash_setPATH',...
    'uq_Dispatcher_tests_helper_createSSHConnect',...
    'uq_Dispatcher_tests_helper_getSessionName'};

%% Recursively execute each test defined in TestNames
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
    Times(iTest) = toc(TestTimer) - Tprev ;
    Tprev = Tprev + Times(iTest);
end


%% Print out the results table and info:
Result = {'ERROR','OK'};

% Character where the result of test is displayed
ResultChar = 72;

MinusLine(1:ResultChar+7) = deal('-');
fprintf('\n%s\n',MinusLine);
fprintf('UQ_SELFTEST_UQ_DEFAULT_DISPATCHER RESULTS');
fprintf('\n%s\n',MinusLine);
for ii = 1:length(success)
    res = sprintf('%s @ %10.5f sec', Result{success(ii)+1},Times(ii));
    points(1:max(2,ResultChar-numel(res)-size(TestNames{ii},2))) = deal('.');
    fprintf('%s %s %-s\n',TestNames{ii},points,res);
    clear points
end
fprintf('%s\n',MinusLine);

%% Did all tests pass?  If not final pass = 0
if all(success)
    pass = 1;
    fprintf('\n');
    fprintf(['SUCCESS: uq_default_dispatcher module ' level ' test was successful.\n']);
else
    
end

end

function pass = uq_selftest_old(level)
%%

uqlab('-nosplash');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
% This test requires that there are "test*.m" profiles available on the
% HPC_Credentials folder, all of them are then used:
root_folder = uq_rootPath;
CredentialsPath = fullfile(root_folder, 'HPC_Credentials');
DirProfiles = dir(CredentialsPath);
[AllProfiles{1:length(DirProfiles)}] = deal(DirProfiles.name);
TestProfiles = {};
for file = 3:length(AllProfiles)
    Filename = AllProfiles{file};
    if strcmpi(Filename(1:4), 'test') && strcmpi(Filename(end - 1:end), '.m')
        % Then the file has the name test*.m, it is a valid test profile:
        fprintf('\nAdding profile "%s" to the testing routine..."', Filename);
        TestProfiles = [TestProfiles, Filename];
    end
end

if isempty(TestProfiles)
    fprintf('\nWarning: Credentials file with the format "test*.m" not found.\nThe test will not be executed.');
    pass = 1;
    return;
end

% Tests we want to run:
TestNames = {'uq_test_simple_dispatcher'};

NProfiles = length(TestProfiles);
NTests = length(TestNames);

for PR = 1:NProfiles
    TestTimer = tic;
    success(PR) = uq_test_simple_dispatcher(level, TestProfiles{PR}(1:end-2));
    Times(PR) = toc(TestTimer);
end

% Print out the results table and info:
Result = {'ERROR','OK'};
ResultChar = 60; % Character where the result of test is displayed
MinusLine(1:ResultChar+7) = deal('-');
fprintf('\n%s\n',MinusLine);
fprintf('UQ_SELFTEST_UQ_DEFAULT_DISPATCHER RESULTS');
fprintf('\n%s\n',MinusLine);
TestResult = 0;
for ii = 1:NProfiles
    for jj = 1:NTests
        TestResult = TestResult + 1;
        points(1:max(2,ResultChar - size(TestNames{jj},2) - size(TestProfiles{ii},2))) = deal('.');
        fprintf('%s (%s) %s %s @ %g sec.\n', ...
            TestNames{jj}, ...
            TestProfiles{ii}, ...
            points,...
            Result{success(TestResult)+1}, ...
            Times(TestResult));
        clear points
    end
end
fprintf('%s\n',MinusLine);

if all(success)
    pass = 1;
    fprintf('\n');
    fprintf(['SUCCESS: uq_default_dispatcher module ' level ' test was successful.\n']);
else
    pass = 0;
    fprintf('\n');
    fprintf(['FAIL: uq_default_dispatcher module ' level ' test failed.\n']);
end
fprintf('Total time: %g',sum(Times));

end