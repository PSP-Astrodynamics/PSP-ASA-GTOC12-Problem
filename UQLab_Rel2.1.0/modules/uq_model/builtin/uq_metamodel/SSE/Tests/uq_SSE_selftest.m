function [pass] = uq_SSE_selftest(level)
% UQ_SELFTEST_UQ_SSE performs functionality and consistency
%   tests for the SSE module of UQLab. A number of tests are
%   executed and their results are summarized and printed on screen.
%
% See also: UQ_SSE_CALCULATE
% start uqlab
uqlab('-nosplash');

% default level
if nargin < 1
    level = 'normal';
end

% tests to perform
TestNames = {...
    'uq_sse_test_surrogateSequentialED',...
    'uq_sse_test_surrogateSequentialED_multiOutput',...
    'uq_sse_test_surrogateFlatten',...
    'uq_sse_test_surrogateGivenED',...
    'uq_sse_test_surrogateGivenED_multiOutput',...
    'uq_sse_test_partitioning',...
    'uq_sse_test_enrichment',...
    'uq_sse_test_refineScore',...
    'uq_sse_test_display2D',...
    'uq_sse_test_display1D',...
    'uq_sse_test_dependence'};

% run the tests
Ntests = length(TestNames);
success = false(1, Ntests);
Times = zeros(1, Ntests);
for ii = 1:Ntests
    TestTimer = tic;
    testHandle = str2func(TestNames{ii});
    success(ii) = testHandle(level);
    Times(ii) = toc(TestTimer);
end

%% Print out the results table and info:
Result = {'ERROR','OK'};

% Character where the result of test is displayed
ResultChar = 70; 

MinusLine(1:ResultChar+7) = deal('-');
fprintf('\n%s\n',MinusLine);
fprintf('UQ_SELFTEST_UQ_SSE RESULTS');
fprintf('\n%s\n',MinusLine);
for ii = 1:length(success)
    points(1:max(2,ResultChar-size(TestNames{ii},2)-12)) = deal('.');
    fprintf('%s %s %s @ %g sec.\n',TestNames{ii},points,Result{success(ii)+1},Times(ii));
    clear points
end
fprintf('%s\n',MinusLine);



% successful or not
if all(success)
    pass = 1;
    fprintf('\n');
    fprintf(['SUCCESS: uq_SSE module ' level ' test was successful.\n']);
else
    pass = 0;
    fprintf('\n');
    fprintf(['FAIL: uq_SSE module ' level ' test failed.\n']);
end
fprintf('Total time: %g',sum(Times));

end