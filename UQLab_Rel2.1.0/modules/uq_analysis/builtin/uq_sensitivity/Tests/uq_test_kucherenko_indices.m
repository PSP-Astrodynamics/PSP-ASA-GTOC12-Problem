function success = uq_test_kucherenko_indices(level)
% success = UQ_TEST_KUCHERENKO_INDICES(level) Test routine for Kucherenko indices.
%     Evaluates the sensitivity for a portfolio function, and validate
%     the results against analytical values. (Values from Kucherenko 2012)
%
% See also: UQ_SENSITIVITY, UQ_KUCHERENKO_INDICES

success = 1;
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |', level,...
    '| uq_test_kucherenko_indices...\n']);
%% Start the framework:
uqlab('-nosplash');

%% Input
M = 4;
[Input.Marginals(1:M).Type] = deal('Gaussian');
Input.Marginals(1).Parameters = [0 4];
Input.Marginals(2).Parameters = [0 2];
Input.Marginals(3).Parameters = [250 200];
Input.Marginals(4).Parameters = [400 300];

Input.Copula.Type = 'Gaussian';
Input.Copula.Parameters = [ 1   0.3 0   0;...
                            0.3 1   0   0;...
                            0   0   1  -0.3;...
                            0   0  -0.3 1];

testInput = uq_createInput(Input, '-private');

%% Ishigami model
MOpts.mHandle = @(X) X(:,1).*X(:,3) + X(:,2).*X(:,4);
MOpts.isVectorized = true;
testModel = uq_createModel(MOpts, '-private');

%% Reference indices
reffirst = [0.507 0.399 0 0];
reftotal = [0.492 0.3 0.192 0.108];

%% Sensitivity
% Initialization
SOpts.Type = 'Sensitivity';
SOpts.Input = testInput;
SOpts.Model = testModel;
SOpts.Method = 'Kucherenko';
SOpts.Display = 'quiet';

%% START THE TEST:

% Absolute error allowed with respect to the analytical indices:
AllowedError = 0.05;

% Sampling methods
switch level
    case 'slow'
        SamplingStrat = {'mc', 'lhs', 'sobol', 'halton'};
        
    otherwise
        SamplingStrat = {'mc'};
        
end

% Sample size
SOpts.Kucherenko.SampleSize = 5e4;

% Estimators we want to test
Estimators = {'standard', 'modified', 'samplebased'};

for ii = 1:length(Estimators)
    % Loop on the type of estimator
    SOpts.Kucherenko.Estimator = Estimators{ii};
    
    for jj = 1:length(SamplingStrat)
        % Loop on the sampling strategy
        SOpts.Kucherenko.Sampling = SamplingStrat{jj};
        
        % Solve the analysis:
        SOpts.Name = sprintf('testing kucherenko %d%d', ii, jj);
        myAnalysis = uq_createAnalysis(SOpts);
        Results = myAnalysis.Results;
        
        
        % Now test the results:
        Error = 0;
        % uncorrelated
        Error = max(Error,...
            max(abs(Results.FirstOrder - reffirst')));
        % interactivce
        Error = max(Error,...
            max(abs(Results.Total - reftotal')));
        
        % Check if the error is greater than the threshold:
        if Error > AllowedError
            fprintf('The test failed for sampling of type %s and Estimator type %s \nAbsolute error was: %f.\n',...
                SamplingStrat{jj}, Estimators{ii}, Error);
            success = 0 ;
        end
    end
end
end