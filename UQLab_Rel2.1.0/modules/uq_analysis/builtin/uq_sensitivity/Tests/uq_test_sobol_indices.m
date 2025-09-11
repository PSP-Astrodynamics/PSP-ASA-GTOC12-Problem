function success = uq_test_sobol_indices(level)
% success = UQ_TEST_SOBOL_INDICES(level) Test routine for Sobol' indices.
%     Evaluates the sensitivity for the Ishigami function, and validate
%     the results against analytical values.
%
% See also: UQ_SENSITIVITY, UQ_SOBOL_INDICES

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
    0];
% The only non-zero index of higher order is S_13:
S13 = (8*IB^2*pi^8)/(225*D);
Sobol.Order(2).Indices = [0, S13, 0];
Sobol.Order(3).Indices = 0;
TotalSobolIndices = Sobol.Order(1).Indices + [S13, 0, S13];

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
        
        % Check if the error is greater than the threshold:
        if Error > AllowedError
            error('The test failed for the estimator %s and sampling of type %s. \nAbsolute error was: %f',...
                Estimators{ii}, SamplingStrat{jj}, Error);
        end
    end
end
uq_display(myAnalysis,1,'hist')
uq_display(myAnalysis,1,'pie')
uq_print(myAnalysis)
close all

success = 1;
