function pass = uq_selftest_uq_rbdo(level)
% PASS = UQ_SELFTEST_UQ_RBDO(LEVEL):
%     Selftest for all methods implemented in RBDO module

uqlab('-nosplash');

if nargin < 1
    level = 'normal'; 
end


%% Perform tests
% Tests to perform:
TestNames = {
    'uq_rbdo_test_AllMethods',...
    'uq_rbdo_test_Reliability',...
    'uq_rbdo_test_Optimization',...
    'uq_rbdo_test_Surrogates',...
    'uq_rbdo_test_print_and_display',...
    'uq_rbdo_test_MultipleOutputs',...
     };

Ntests = length(TestNames);
success = false(1, Ntests);
Times = zeros(1, Ntests);
for ii = 1:Ntests
    TestTimer = tic;
    testFuncHandle = str2func(TestNames{ii});
    try 
        success(ii) = testFuncHandle(level);
        Times(ii) = toc(TestTimer);
    catch me
        success(ii) = false;
        Times(ii) = toc(TestTimer);
    end
        
end


%% Print out the results table and info:
Result = {'ERROR','OK'};

% Character where the result of test is displayed
ResultChar = 60; 

MinusLine(1:ResultChar+7) = deal('-');
fprintf('\n%s\n',MinusLine);
fprintf('UQ_SELFTEST_UQ_RBDO RESULTS');
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
    fprintf(['SUCCESS: uq_rbdo module ' level ' test was successful.\n']);
else
    pass = 0;
    fprintf('\n');
    fprintf(['FAIL: uq_rbdo module ' level ' test failed.\n']);
end
fprintf('Total time: %g',sum(Times));