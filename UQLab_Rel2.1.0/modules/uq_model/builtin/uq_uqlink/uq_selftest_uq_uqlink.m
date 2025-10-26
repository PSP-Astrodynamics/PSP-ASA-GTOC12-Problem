function pass = uq_selftest_uq_uqlink(level)
% UQ_SELFTEST_UQ_DEFAULT_MODEL conducts a selftest for the default model
% module

uqlab('-nosplash');

if nargin < 1
    level = 'normal'; 
end   

pass = 0;

%% Test Names are defined here
TestNames = {...
    'uq_UQLink_test_util_initSizes',...
    'uq_UQLink_test_util_checkForPatternInFiles',...
    'uq_UQLink_test_util_parseMarkerSimple',...
    'uq_UQLink_test_util_parseMarkerExpression',...
    'uq_UQLink_test_util_replaceFilenames',...
    'uq_UQLink_test_util_addQuotesOnPath',...
    'uq_UQLink_test_util_execCommand',...
    'uq_UQLink_test_util_parseOutputs',...
    'uq_UQLink_test_util_returnNaN',...
    'uq_UQLink_test_util_reshapeCellwithNaNs',...
    'uq_uqlink_test_possibleCases', ...
    'uq_uqlink_test_RecoverResume', ...
    'uq_uqlink_test_Archiving', ...
    'uq_uqlink_test_CommandLine',...
    'uq_uqlink_test_expression'};

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
fprintf('UQ_SELFTEST_UQ_UQLINK RESULTS');
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
    fprintf(['SUCCESS: uq_default_model module ' level ' test was successful.\n']);
else
    
end