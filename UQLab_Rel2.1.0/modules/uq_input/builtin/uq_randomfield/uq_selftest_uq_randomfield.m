function pass = uq_selftest_uq_randomfield( level )
% UQ_SELFTEST_UQ_DEFAULT_INPUT Validation tests of the uq_default_input
% module. Returns 1 if all tests are passed, otherwise 0.

%% Initialize
if nargin < 1
    level = 'normal';
end
pass = 0;

%% Parameters
% The names of the tests that will take place
TestNames = {...
    'uq_randomfield_test_discschemes_1d', ...
    'uq_randomfield_test_lognormal', ...
    'uq_randomfield_test_conditional_2d', ...
    'uq_randomfield_test_10d',...
    'uq_randomfield_test_nonregulargrid',...
    'uq_randomfield_test_cov_convergence',...
    'uq_randomfield_test_translationRF',...
    'uq_randomfield_test_newmesh'};
% Character where the result of test is displayed
ResultChar = 60; 

%% Run tests
success = zeros(length(TestNames),1);
Times = zeros(length(TestNames),1);
TestTimer = tic;
Tprev = 0;
for iTest = 1 : length(TestNames)
    % fix the value of the random number seed before initiating each test
    rng(10);
    % obtain the function handle of current test from its name
    testFuncHandle = str2func(TestNames{iTest});
    % run test
    success(iTest) = testFuncHandle(level);
    % calculate the time required from the current test to execute
    Times(iTest) = toc(TestTimer) - Tprev ;
    Tprev = Tprev + Times(iTest);
end

%% Print out the results table and runtime information
Result = {'ERROR','OK'};
MinusLine(1:ResultChar+7) = deal('-');
fprintf('\n%s\n',MinusLine);
fprintf('UQ_SELFTEST_UQ_DEFAULT_INPUT RESULTS');
fprintf('\n%s\n',MinusLine);
for ii = 1:length(success)
    points(1:max(2,ResultChar-size(TestNames{ii},2))) = deal('.');
    fprintf('%s %s %s @ %g sec.\n',TestNames{ii},points,Result{success(ii)+1},Times(ii));
    clear points
end
fprintf('%s\n',MinusLine);
if all(success)
    pass = 1;
    fprintf('\n');
    fprintf(['SUCCESS: uq_default_input module ' level ' test was successful.\n']);
else
    pass = 0;
    fprintf('\n');
    fprintf(['FAIL: uq_default_input module ' level ' test failed.\n']);
end
fprintf('Total time: %g',sum(Times));
