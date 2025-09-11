function success = uq_test_perturbation_constant(level)
% SUCCESS = UQ_TEST_PERTURBATION_CONSTANT(LEVEL): non-regression test for 
%     the perturbation method on a function with 4th order interactions in 
%     the presence of constant inputs.
%
% See also: UQ_PERTURBATION_METHOD,UQ_SENSITIVITY

success = 0;

%% Start the framework:
uqlab('-nosplash');
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |', level,...
    '| uq_test_perturbation_constant...\n']);
%% Input
M = 6;
[IOpts.Marginals([1 3 5 6]).Type] = deal('Uniform');
[IOpts.Marginals([1 3 5 6]).Parameters] = deal([-10 10]);
[IOpts.Marginals([2 4]).Type] = deal('Constant');
[IOpts.Marginals([2 4]).Parameters] = deal(5);

ihandle = uq_createInput(IOpts);

%% Test example, x1 and x2 have higher importance than x3 and x4
% The constants should have no importance
modelopts.Name = 'Test case perturbation with constants';
modelopts.mString = '2*X(:, 1) + 3*X(:, 3) + 4*X(:, 5) + 5*X(:, 6) + 7 * X(:,2) + 8 * X(:,4)';
modelopts.isVectorized = true;
TestCaseModel = uq_createModel(modelopts);



%% Sensitivity
Sensopts.Type = 'Sensitivity';
Sensopts.Model = TestCaseModel;
Sensopts.Method = 'perturbation';
Sensopts.Display = 'quiet';
Sensopts.SaveEvaluations = true;
% Run the analysis
mySens = uq_createAnalysis(Sensopts);
Results = mySens.Results;

%% Compare with the theoretical results
% analytical results for this linear model
Coeffs = [2 0 3 0 4 5];
VarY = sum(Coeffs.^2);
Di = (Coeffs.^2/VarY);
success = all(abs(2*(Di - Results.Sensitivity'))<1e-2);



