function pass = uq_LRA_selftest(level)
uqlab('-nosplash');

if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end   

pass = 0;

%% Test Names are defined here
TestNames = {'uq_LRA_test_multiple_outputs', ...
    'uq_LRA_test_CustomLRA',...
    'uq_LRA_test_LRA2PCE',...
    'uq_LRA_test_constants'
    } ;

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
ResultChar = 60; % Character where the result of test is displayed
MinusLine(1:ResultChar+7) = deal('-');
fprintf('\n%s\n',MinusLine);
fprintf('UQ_SELFTEST_UQ_LRA RESULTS');
fprintf('\n%s\n',MinusLine);
for ii = 1:length(success)
    points(1:max(2,ResultChar-size(TestNames{ii},2))) = deal('.');
    fprintf('%s %s %s @ %g sec.\n',TestNames{ii},points,Result{success(ii)+1},Times(ii));
    clear points
end
fprintf('%s\n',MinusLine);

%% Were all tests passed?  If not final pass = 0
if all(success)
    pass = 1;
    fprintf('\n');
    fprintf(['SUCCESS: uq_LRA module ' level ' test was successful.\n']);
else
    
end
