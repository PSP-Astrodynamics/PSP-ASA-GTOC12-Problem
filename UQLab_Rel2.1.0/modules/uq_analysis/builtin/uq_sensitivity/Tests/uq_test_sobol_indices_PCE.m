function success = uq_test_sobol_indices_PCE(level)
% PASS = UQ_TEST_SOBOL_INDICES_PCE(LEVEL): non-regression test for 
%     PCE-based Sobol' indices for the Ishigami function. 
%
% See also: UQ_TEST_SOBOL_INDICES_PCE_CONSTANT,UQ_SOBOL_INDICES,UQ_SENSITIVITY
success = 0;
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |', level,...
    '| uq_test_sobol_indices...\n']);
%% Start the framework:
uqlab('-nosplash');

%% Input
M = 3;
[Input.Marginals(1:M).Type] = deal('Uniform');
[Input.Marginals(1:M).Parameters] = deal([-pi, pi]);
testInput = uq_createInput(Input, '-private');

%% Ishigami model
MOpts.Name = 'Ishigami Example Model';
MOpts.mFile = 'uq_ishigami';
testModel = uq_createModel(MOpts, '-private');

%% Analytical indices
IA = 7;
IB = 0.1;
D = IA^2/8 + (IB*pi^4)/5 + (IB^2*pi^8)/18 + 1/2;
Sobol.Order(1).Indices = (1/D)*[(IB*pi^4)/5 + (IB^2*pi^8)/50+ 1/2, ...
    IA^2/8, ...
    0]';
% The only non-zero index of higher order is S_13:
S13 = (8*IB^2*pi^8)/(225*D);
Sobol.Order(2).Indices = [0, S13, 0]';
Sobol.Order(3).Indices = 0;
TotalSobolIndices = Sobol.Order(1).Indices + [S13, 0, S13]';

%% PCE model
metaopts.Type = 'Metamodel';
metaopts.MetaType = 'PCE';
metaopts.Degree = 10:20;
metaopts.ExpDesign.Sampling = 'Sobol';
metaopts.ExpDesign.NSamples = 150;
metaopts.FullModel = testModel;
metaopts.Input = testInput;
myPCE = uq_createModel(metaopts);

%% Sensitivity
SOpts.Type = 'Sensitivity';
SOpts.Input = testInput;
SOpts.Model = myPCE;
SOpts.Method = 'Sobol';
SOpts.Display = 'quiet';

%% START THE TEST:

% Absolute error allowed with respect to the analytical indices:
AllowedError = 1e-5;

% Check if the analysis runs for lower orders
for ii = 1:3
    SOpts.Sobol.Order = ii;
    % Solve the analysis:
    myAnalysis = uq_createAnalysis(SOpts,'-private');
end
% We only need the results of the order 3
Results = myAnalysis.Results;

% Now test the results:
Error = 0;
for k = 1:length(Results.AllOrders)
    Error = max(Error,...
        max(abs(Results.AllOrders{k} - Sobol.Order(k).Indices)));
end
Error = max(Error,...
    max(abs(Results.Total - TotalSobolIndices)));

% Check if the error is greater than the threshold:
if Error > AllowedError
    error('The test failed for the estimator %s and sampling of type %s. \nAbsolute error was: %f',...
        Estimators{ii}, SamplingStrat{jj}, Error);
end



success = 1;
