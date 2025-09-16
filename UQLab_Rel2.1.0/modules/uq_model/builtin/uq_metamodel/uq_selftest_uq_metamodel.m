function pass = uq_selftest_uq_metamodel( level )
% PASS = UQ_SELFTEST_UQ_METAMODEL(LEVEL) run a suite of consistency and
%     non-regression tests on the METAMODEl module of UQLab. If all the tests
%     are passed, PASS = 1, otherwise PASS = 0. The input variable LEVEL
%     (default = 'normal') is currently unused
%
% See also: UQ_PCE_SELFTEST, UQ_KRIGING_SELFTEST

%% STARTUP THE FRAMEWORK AND PARSE OPTIONS
uqlab('-nosplash');

if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end

%% RUN THE KRIGING SELFTESTS
TestTimer = tic;
success(1) = uq_Kriging_selftest(level);
Times(1) = toc(TestTimer);

%% RUN THE PCE SELFTESTS
TestTimer = tic;
success(2) = uq_PCE_selftest(level);
Times(2) = toc(TestTimer);

%% RUN THE LRA SELFTESTS
TestTimer = tic;
success(3) = uq_LRA_selftest(level);
Times(3) = toc(TestTimer);

%% RUN THE PCK SELFTESTS
TestTimer = tic;
success(4) = uq_PCK_selftest(level);
Times(4) = toc(TestTimer);

%% RUN THE SVR SELFTESTS
TestTimer = tic;
success(5) = uq_SVR_selftest(level);
Times(5) = toc(TestTimer);

%% RUN THE SVC SELFTESTS
TestTimer = tic;
success(6) = uq_SVC_selftest(level);
Times(6) = toc(TestTimer);

%% RUN THE SSE SELFTESTS
TestTimer = tic;
success(7) = uq_SSE_selftest(level);
Times(7) = toc(TestTimer);

%% RUN THE GLAM SELFTESTS
TestTimer = tic;
success(8) = uq_GLaM_selftest(level);
Times(8) = toc(TestTimer);

%% RUN THE SPCE SELFTESTS
TestTimer = tic;
success(9) = uq_SPCE_selftest(level);
Times(9) = toc(TestTimer);

%% PRINT OUT THE RESULTS TABLE ANY ADDITIONAL INFO:
TestNames = {'uq_Kriging_selftest', 'uq_PCE_selftest','uq_PCK_selftest','uq_LRA_selftest','uq_SVR_selftest','uq_SVC_selftest','uq_SSE_selftest','uq_GLaM_selftest','uq_SPCE_selftest',};
Result = {'ERROR','OK'};
% try to align the test results
ResultChar = 60; 
MinusLine(1:ResultChar+7) = deal('-');
fprintf('\n%s\n',MinusLine);
fprintf('METAMODEL MODULE TEST RESULTS');
fprintf('\n%s\n',MinusLine);
% loop over the test results
for ii = 1:length(success)
    points(1:max(2,ResultChar-size(TestNames{ii},2))) = deal('.');
    fprintf('%s %s %s @ %g sec.\n',TestNames{ii},points,Result{success(ii)+1},Times(ii));
    clear points
end
fprintf('%s\n',MinusLine);

if all(success)
    pass = 1;
    fprintf('\n');
    fprintf(['SUCCESS: uq_metamodel module ' level ' test was successful.\n']);
else
    pass = 0;
    fprintf('\n');
    fprintf(['FAIL: uq_metamodel module ' level ' test failed.\n']);
end
fprintf('Total time: %g',sum(Times));
