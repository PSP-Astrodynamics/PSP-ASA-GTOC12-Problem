function pass = uq_Kriging_selftest(level)
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
TestNames = {'uq_Kriging_test_Nugget', 'uq_Kriging_test_TrendTypes',...
    'uq_Kriging_test_OptimResult', 'uq_Kriging_test_ExpDesigns',...
    'uq_Kriging_test_CustomKriging', 'uq_Kriging_test_Constant',...
    'uq_Kriging_test_kFold',...
    'uq_Kriging_test_GPROptimResult', 'uq_Kriging_test_GPRCustom',...
    'uq_Kriging_test_GPRTrendTypes', 'uq_Kriging_test_GPRConstant',...
    'uq_Kriging_test_GPRExpDesigns', 'uq_Kriging_test_GPRSigmaNSQ',...
    'uq_Kriging_test_Print', 'uq_Kriging_test_Display', ...
    'uq_Kriging_test_GPRHomoscedastic', ...
    'uq_Kriging_test_Resampling', 'uq_Kriging_test_GPRResampling'};
%'uq_Kriging_test_Resampling_multioutputs'};

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
fprintf('UQ_SELFTEST_UQ_KRIGING RESULTS');
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
    fprintf('SUCCESS: uq_Kriging module %s test was successful.\n',level);
end

end