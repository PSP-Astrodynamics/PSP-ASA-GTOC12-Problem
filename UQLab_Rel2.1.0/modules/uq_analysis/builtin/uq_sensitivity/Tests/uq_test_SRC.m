function success = uq_test_SRC(level)
% PASS = UQ_TEST_SRC_CONSTANT(LEVEL): non-regression test for SRC
%     coefficients with a simple toy function.
%
% See also: UQ_SRC_INDICES,UQ_SENSITIVITY,UQ_TEST_SRC_CONSTANT


success = 0;

%% Start the framework:
uqlab('-nosplash');
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |', level,...
    '| uq_test_SRC...\n']);
%% Input
M = 4;
[IOpts.Marginals(1:M).Type] = deal('Uniform');
[IOpts.Marginals(1:M).Moments] = deal([5, 1]);
ihandle = uq_createInput(IOpts);

%% Test example, x1 and x2 have higher importance than x3 and x4
modelopts.Name = 'Test case correlation';
modelopts.mString = '2*X(:, 1) + 3*X(:, 2) + 4*X(:, 3) + 5*X(:, 4)';
modelopts.isVectorized = true;
TestCaseModel = uq_createModel(modelopts);



%% Sensitivity
Sensopts.Type = 'Sensitivity';
Sensopts.Model = TestCaseModel;
Sensopts.Method = 'SRC';
Sensopts.Display = 'quiet';
% Sampling
Sensopts.SRC.SampleSize = 2000;
Sensopts.SRC.Sampling = 'Sobol';
Sensopts.SaveEvaluations = true;
% Run the analysis
mySens = uq_createAnalysis(Sensopts);
Results = mySens.Results;

%% Compare with the theoretical results
% analytical results for SRC for the linear model
Coeffs = [2 3 4 5];
VarY = sum(Coeffs.^2);
Di = sqrt(Coeffs.^2/VarY)';
success = all(abs(2*(Di - Results.SRCIndices)./Di)<1e-2);



