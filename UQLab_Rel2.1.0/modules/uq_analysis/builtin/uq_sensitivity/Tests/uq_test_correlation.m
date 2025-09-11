function success = uq_test_correlation(level)
% SUCCESS = UQ_TEST_CORRELATION(LEVEL): non-regression test for
%     correlation-based indices on a toy function x1 + x2 + 0.1*x3 + 0.1*x4.
%
% See also: UQ_CORRELATION_INDICES,UQ_SENSITIVITY

success = 0;

%% Start the framework:
uqlab('-nosplash');
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |', level,...
    '| uq_test_correlation...\n']);
%% Input
M = 4;
[IOpts.Marginals(1:M).Type] = deal('Uniform');
[IOpts.Marginals(1:M).Parameters] = deal([-5, 5]);
ihandle = uq_createInput(IOpts);

%% Test example, x1 and x2 have higher importance than x3 and x4
modelopts.Name = 'Test case correlation';
modelopts.mString = 'X(:, 1) + X(:, 2) + 0.1*(X(:, 3) + X(:, 4))';
TestCaseModel = uq_createModel(modelopts);



%% Sensitivity
Sensopts.Type = 'Sensitivity';
Sensopts.Model = TestCaseModel;
Sensopts.Method = 'Correlation';
Sensopts.Display = 'quiet';
% 100 samples per factor:
Sensopts.Correlation.SampleSize = 100;
Sensopts.SaveEvaluations = true;
% Run the analysis
mySens = uq_createAnalysis(Sensopts);
Results = mySens.Results;

%% Compare with the theoretical results
% calculate linear and rank correlation of the inputs with the output

lcorr = corr(Results.ExpDesign.X, Results.ExpDesign.Y);
rcorr = corr(Results.ExpDesign.X, Results.ExpDesign.Y, 'type', 'Spearman');

success = isequal(lcorr, Results.CorrIndices) && isequal(rcorr, Results.RankCorrIndices);