function success = uq_test_correlation_constant(level)
% PASS = UQ_TEST_CORRELATION_CONSTANT(LEVEL): non-regression test for
%     correlation-based indices on a high order interaction function
%     in the presence of constant input variables. 
%
% See also: UQ_CORRELATION_INDICES,UQ_SENSITIVITY, UQ_TEST_CORRELATION

success = 0;

%% Start the framework:
uqlab('-nosplash');
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |', level,...
    '| uq_test_correlation_constant...\n']);
%% Input
M = 6;
[IOpts.Marginals([1 3 5 6]).Type] = deal('Uniform');
[IOpts.Marginals([1 3 5 6]).Parameters] = deal([-10 10]);
[IOpts.Marginals([2 4]).Type] = deal('Constant');
[IOpts.Marginals([2 4]).Parameters] = deal(5);

ihandle = uq_createInput(IOpts);

%% Test example, x1 and x2 have higher importance than x3 and x4
% The constants should have no importance
modelopts.Name = 'Test case correlation with constants';
modelopts.mString = '2*X(:, 1) + 3*X(:, 3) + 4*X(:, 5) + 5*X(:, 6) + 7 * X(:,2) + 8 * X(:,4)';
modelopts.isVectorized = true;
TestCaseModel = uq_createModel(modelopts);



%% Sensitivity
Sensopts.Type = 'Sensitivity';
Sensopts.Model = TestCaseModel;
Sensopts.Method = 'Correlation';
Sensopts.Display = 'quiet';
% 100 samples per factor:
Sensopts.Correlation.SampleSize = 1000;
Sensopts.SaveEvaluations = true;
% Run the analysis
mySens = uq_createAnalysis(Sensopts);
Results = mySens.Results;

%% Compare with the theoretical results
% calculate linear and rank correlation of the inputs with the output

lcorr = corr(Results.ExpDesign.X, Results.ExpDesign.Y);
rcorr = corr(Results.ExpDesign.X, Results.ExpDesign.Y, 'type', 'Spearman');

success = isequaln(lcorr([1 3 5 6]), Results.CorrIndices([1 3 5 6])) && isequaln(rcorr([1 3 5 6]), Results.RankCorrIndices([1 3 5 6]));
success = success && isequal(Results.CorrIndices([2 4]), [0 0]' ) && isequal(Results.RankCorrIndices([2 4]),[0 0 ]');