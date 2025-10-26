function success = uq_test_sobol_indices_LRA(level)
% success = UQ_TEST_SOBOL_INDICES_LRA(level) Test routine for LRA based 
% sobol indices.
% Evaluates the sensitivity for a function, and validates
% the results against the correct values.

success = 0;
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |', level,...
    '| uq_test_sobol_indices_LRA...\n']);
%% Start the framework:
uqlab('-nosplash');

%% Input
M = 3;
[Input.Marginals(1:M).Type] = deal('Uniform');
[Input.Marginals(1:M).Parameters] = deal([-pi, pi]);
testInput = uq_createInput(Input, '-private');

%% Ishigami model
MOpts.Name = 'Sobol indices test model';
MOpts.mHandle = @(X) X(:,1) + 2.*X(:,2) + 3.*X(:,3).*X(:,2) + 2 .* X(:,1).*X(:,2).*X(:,3);
testModel = uq_createModel(MOpts, '-private');

o1 = [ 0.01283668 ; 0.05134673 ; 0];
o2 = [0; 0; 0.380079];
o3 = 0.5557376;

%% Analytical indices
Sobol.Order(1).Indices = o1;
% The only non-zero index of higher order is S_13:
Sobol.Order(2).Indices = o2;
Sobol.Order(3).Indices = o3;
TotalSobolIndices = [.5685743; 0.9871633; .9358166];

%% PCE model
metaopts.Type = 'Metamodel';
metaopts.MetaType = 'LRA';
metaopts.Rank = 1:10;
metaopts.Degree = 4;
metaopts.ExpDesign.Sampling = 'LHS';
metaopts.ExpDesign.NSamples = 1500;
metaopts.FullModel = testModel;
metaopts.Input = testInput;
myLRA = uq_createModel(metaopts);

%% Sensitivity
SOpts.Type = 'Sensitivity';
SOpts.Input = testInput;
SOpts.Model = myLRA;
SOpts.Method = 'Sobol';
SOpts.Display = 'quiet';

%% START THE TEST:

% Absolute error allowed with respect to the analytical indices:
AllowedError = 1e-3;

switch level
    case 'slow'
        SOpts.Sobol.Order = 3;
    otherwise
        SOpts.Sobol.Order = 3;
end


% Solve the analysis:
myAnalysis = uq_createAnalysis(SOpts);
Results = myAnalysis.Results;


% Now test the results:
Error = 0;
for k = 1:length(Results.AllOrders)
    Error = max(Error,...
        max(abs(Results.AllOrders{k} - Sobol.Order(k).Indices)));
end

Error = max(Error, max(abs(Results.Total - TotalSobolIndices)));

% Check if the error is greater than threshold:
if Error > AllowedError
    error('The LRA based Sobol indices test failed.');
end

success = 1;
