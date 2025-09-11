function success = uq_test_borgonovo_indices(level)
% success = UQ_TEST_BORGONOVO_INDICES(level) Test routine for Borgonovo
%     indices.
%     Evaluate the sensitivity for the Ishigami function, and validate
%     the results against accurate numerical estimates.
%
% See also: UQ_SENSITIVITY, UQ_BORGONOVO_INDICES

success = 0;
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |', level,...
    '| uq_test_borgonovo_indices...\n']);
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
MOpts.Parameters = [5 0.1];
testModel = uq_createModel(MOpts, '-private');

%% Pre-computed Indices based on a sample of 1e6 points:

% Borgo.Order(1).Indices = [0.3494,0.3950, 0.2840];
% temporarily
Borgo.Order(1).Indices = [0.29,0.35, 0.23];

%% Sensitivity
BOpts.Type = 'Sensitivity';
BOpts.Input = testInput;
BOpts.Model = testModel;
BOpts.Method = 'Borgonovo';
BOpts.Display = 'quiet';
% Sampling options:
BOpts.Borgonovo.SampleSize = 1e4;
BOpts.Borgonovo.NClasses = 15;
%% START THE TEST:

% Absolute error allowed with respect to the analytical indices:
AllowedError = 0.1;

switch level
    case 'slow'
        SOpts.Borgonovo.Order = 1;
        SamplingStrat = {'mc', 'lhs', 'sobol', 'halton'};
        
    otherwise
        SOpts.Sobol.Order = 1;
        SamplingStrat = {'mc'};
        
end
% There will be a loop on the different features we want to test:
Estimators = {'HistBased', 'CDFBased'};


for ii = 1:length(Estimators)
    % Loop on the type of estimator
    BOpts.Borgonovo.Method = Estimators{ii};
    
    for jj = 1:length(SamplingStrat)
        % Loop on the sampling strategy
        BOpts.Borgonovo.Sampling = SamplingStrat{jj};
        
        % Solve the analysis:
        BOpts.Name = sprintf('testing borgonovo %d%d', ii, jj);
        myAnalysis = uq_createAnalysis(BOpts,'-private');
        Results = myAnalysis.Results;
        
        
        % Now test the results:
        Error = max(abs(Results.Delta - Borgo.Order(1).Indices'));
        
        % Check if the error is greater than the threshold:
        if Error > AllowedError
            error('The test failed for the estimator %s and sampling of type %s. \nAbsolute error was: %f',...
                Estimators{ii}, SamplingStrat{jj}, Error);
        end
    end
end
%uq_display(myAnalysis);
success = 1;
