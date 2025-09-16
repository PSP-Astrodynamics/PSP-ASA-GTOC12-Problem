function success = uq_test_perturbation(level)
% PASS = UQ_TEST_PERTURBATION(LEVEL): non-regression test for perturbation
%     method on the toy function: x1 + x2 + 0.1*x3 + 0.1*x4
%
% See also: UQ_PERTURBATION_METHOD,UQ_SENSITIVITY

success = 0;

%% Start the framework:
uqlab('-nosplash');
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |', level,...
    '| uq_test_perturbation...\n']);
%% Input
M = 4;
[IOpts.Marginals(1:M).Type] = deal('Uniform');
[IOpts.Marginals(1:M).Moments] = deal([5, 1]);
ihandle = uq_createInput(IOpts);

%% Test example, x1 and x2 have higher importance than x3 and x4
modelopts.Name = 'Test case perturbation';
modelopts.mString = '2*X(:, 1) + 3*X(:, 2) + 4*X(:, 3) + 5*X(:, 4)';
modelopts.isVectorizes = true;
TestCaseModel = uq_createModel(modelopts);



%% Sensitivity
Sensopts.Type = 'Sensitivity';
Sensopts.Model = TestCaseModel;
Sensopts.Method = 'perturbation';
Sensopts.Display = 'quiet';
% 100 samples per factor:
Sensopts.SaveEvaluations = true;
% Run the analysis
mySens = uq_createAnalysis(Sensopts);
Results = mySens.Results;

%% Compare with the theoretical results
% analytical results for this linear model
Coeffs = [2 3 4 5];
VarY = sum(Coeffs.^2);
Di = (Coeffs.^2/VarY);
success = all(abs(2*(Di - Results.Sensitivity'))<1e-2);



