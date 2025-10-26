function success = uq_test_sobol_indices_constant(level)
% PASS = UQ_TEST_SOBOL_INDICES_CONSTANT(LEVEL): non-regression test for Sobol'
%     indices on the Ishigami function in the presence of constant inputs. 
%
% See also: UQ_TEST_SOBOL_INDICES,UQ_SOBOL_INDICES,UQ_SENSITIVITY

success = 0;
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |', level,...
    '| uq_test_sobol_indices_constant...\n']);
%% Start the framework:
uqlab('-nosplash');

%% Input
M = 5;
[Input.Marginals(1:M).Type] = deal('Uniform');
[Input.Marginals(1:M).Parameters] = deal([-pi, pi]);
Input.Marginals(2).Type = 'Constant';
Input.Marginals(2).Parameters = 0;
Input.Marginals(4).Type = 'Constant';
Input.Marginals(4).Parameters = 0;

testInput = uq_createInput(Input, '-private');

%% Ishigami model
MOpts.Name = 'Ishigami Example Model';
MOpts.mHandle = @(X) uq_ishigami([X(:,1),X(:,3),X(:,5)])+X(:,2).^3+X(:,4).^2;
MOpts.isVectorized = true;
testModel = uq_createModel(MOpts, '-private');

%% Analytical indices
IA = 7;
IB = 0.1;
D = IA^2/8 + (IB*pi^4)/5 + (IB^2*pi^8)/18 + 1/2;
Sobol.Order(1).Indices = (1/D)*[(IB*pi^4)/5 + (IB^2*pi^8)/50+ 1/2, ...
    0, ...
    IA^2/8, ...
    0, ...
    0];
% The only non-zero index of higher order is S_13:
S13 = (8*IB^2*pi^8)/(225*D);
Sobol.Order(2).Indices = [0, S13, 0];
Sobol.Order(3).Indices = 0;
TotalSobolIndices = Sobol.Order(1).Indices + [S13, 0, 0, 0, S13];

%% Sensitivity
SOpts.Type = 'Sensitivity';
SOpts.Input = testInput;
SOpts.Model = testModel;
SOpts.Method = 'Sobol';
SOpts.Display = 'quiet';
% Sampling options:
SOpts.Sobol.SampleSize = 1e4;

%% START THE TEST:

% Absolute error allowed with respect to the analytical indices:
AllowedError = 0.1;

switch level
    case 'slow'
        SOpts.Sobol.Order = 3;
        SamplingStrat = {'mc', 'lhs', 'sobol', 'halton'};
        
    otherwise
        SOpts.Sobol.Order = 3;
        SamplingStrat = {'mc'};
        
end
% There will be a loop on the different features we want to test:
Estimators = {'t', 's', 'sobol'};


for ii = 1:length(Estimators)
    % Loop on the type of estimator
    SOpts.Sobol.Estimator = Estimators{ii};
    
    for jj = 1:length(SamplingStrat)
        % Loop on the sampling strategy
        SOpts.Sobol.Sampling = SamplingStrat{jj};
        
        % Solve the analysis:
        SOpts.Name = sprintf('testing sobol %d%d', ii, jj);
        myAnalysis = uq_createAnalysis(SOpts);
        Results = myAnalysis.Results;
        
        
        % Now test the results:
        Error = 0;
        for k = 1:length(Results.AllOrders)
            Error = max(Error,...
                max(abs(Results.AllOrders{k} - Sobol.Order(k).Indices')));
        end
        Error = max(Error,...
            max(abs(Results.Total - TotalSobolIndices')));
        
        % Check if the error is greater than threshold:
        if Error > AllowedError
            error('The test failed for the estimator %s and sampling of type %s. \nAbsolute error was: %f',...
                Estimators{ii}, SamplingStrat{jj}, Error);
        end
    end
end

success = 1;
