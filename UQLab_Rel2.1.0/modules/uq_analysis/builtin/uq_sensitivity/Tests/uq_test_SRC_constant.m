function success = uq_test_SRC_constant(level)
% PASS = UQ_TEST_SRC_CONSTANT(LEVEL): non-regression test for SRC
%     coefficients in the presence of constants in the input
%
% See also: UQ_SRC_INDICES,UQ_SENSITIVITY,UQ_TEST_SRC

success = 0;

%% Start the framework:
uqlab('-nosplash');
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |', level,...
    '| uq_test_SRC_constant...\n']);
%% Input
M = 6;
[IOpts.Marginals([1 3 5 6]).Type] = deal('Uniform');
[IOpts.Marginals([1 3 5 6]).Parameters] = deal([-10 10]);
[IOpts.Marginals([2 4]).Type] = deal('Constant');
[IOpts.Marginals([2 4]).Parameters] = deal(0);

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
Sensopts.Method = 'SRC';
Sensopts.Display = 'quiet';
% 100 samples per factor:
Sensopts.SRC.SampleSize = 2000;
Sensopts.SRC.Sampling = 'Sobol';
Sensopts.SaveEvaluations = true;
% Run the analysis
mySens = uq_createAnalysis(Sensopts);
Results = mySens.Results;

%% Compare with the theoretical results
% analytical results for SRC for the linear model
Coeffs = [2 3 4  5 ];
VarY = sum(Coeffs.^2);
Di = sqrt(Coeffs.^2/VarY)';
success = all(abs(2*(Di - Results.SRCIndices([1 3 5 6]))./Di)<1e-2);



