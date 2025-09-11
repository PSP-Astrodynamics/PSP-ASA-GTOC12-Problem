function pass = uq_selftest_uq_uqlib( level )
% PASS = UQ_SELFTEST_UQ_UQLIB(LEVEL) run a suite of consistency and
%     non-regression tests on the UQLIB module of UQLab. A number of tests are
%     executed and their results are summarized and printed on screen. If
%     all the tests are passed, PASS = 1, otherwise PASS = 0. The input
%     variable LEVEL (default = 'normal') is currently unused
%

uqlab('-nosplash');
if nargin < 1
    level = 'normal';
end

% Tests to perform:
TestNames = {'uq_test_gradient',...
             'uq_test_optimizers', ...
             'uq_map_tests_uq_empty_dispatcher',...
             'uq_reduce_tests_uq_empty_dispatcher'
    };

Ntests = length(TestNames);
success = false(1, Ntests);
Times = zeros(1, Ntests);
for ii = 1:Ntests
    TestTimer = tic;
    success(ii) = eval([TestNames{ii} '(level);']);
    Times(ii) = toc(TestTimer);
end

% Print out the results table and info:
Result = {'ERROR','OK'};
ResultChar = 60; % Character where the result of test is displayed
MinusLine(1:ResultChar + 7) = deal('-');
fprintf('\n%s\n',MinusLine);
fprintf('UQ_SELFTEST_UQ_UQLIB RESULTS');
fprintf('\n%s\n',MinusLine);
for ii = 1:Ntests
    points(1:max(2,ResultChar-size(TestNames{ii},2))) = deal('.');
    fprintf('%s %s %s @ %g sec.\n',TestNames{ii},points,Result{success(ii)+1},Times(ii));
    clear points
end
fprintf('%s\n',MinusLine);

if all(success)
    pass = 1;
    fprintf('\n');
    fprintf(['SUCCESS: uq_lib module ' level ' test was successful.\n']);
else
    pass = 0;
    fprintf('\n');
    fprintf(['FAIL: uq_lib module ' level ' test failed.\n']);
end
fprintf('Total time: %g',sum(Times));