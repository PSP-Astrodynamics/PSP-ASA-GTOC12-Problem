function success = uq_test_ancova_indices(level)
% success = UQ_TEST_ANCOVA_INDICES(level) Test routine for ANCOVA indices.
%     Evaluates the sensitivity for the Ishigami function, and validate
%     the results against analytical values.
%
% See also: UQ_SENSITIVITY, UQ_ANCOVA_INDICES

success = 0;
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |', level,...
    '| uq_test_ancova_indices...\n']);
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

%% Reference indices

refuncorr = [0.31 0.45 0];
refinter = [-0.003 0 0];
refcorr = [0 0.001 0];
truesum = [0.31 0.45 0];

%% Sensitivity
SOpts.Type = 'Sensitivity';
SOpts.Input = testInput;
SOpts.Model = testModel;
SOpts.Method = 'ANCOVA';
SOpts.Display = 'quiet';

%% START THE TEST:

% Absolute error allowed with respect to the analytical indices:
AllowedError = 0.05;

switch level
    case 'slow'
        SamplingStrat = {'mc', 'lhs', 'sobol', 'halton', 'provided'};
        
    otherwise
        SamplingStrat = {'mc', 'provided'};
        
end

for jj = 1:length(SamplingStrat)
    % Loop on the sampling strategy
    switch SamplingStrat{jj}
        case 'provided'
            SOpts.ANCOVA.Samples.X = uq_getSample(testInput, 200);
        otherwise
            SOpts.ANCOVA.Sampling = SamplingStrat{jj};
    end
    
    % Solve the analysis:
    SOpts.Name = sprintf('testing ancova %d', jj);
    myAnalysis = uq_createAnalysis(SOpts);
    Results = myAnalysis.Results;
    
    
    % Now test the results:
    Error = 0;
    % uncorrelated
    Error = max(Error,...
        max(abs(Results.Uncorrelated - refuncorr')));
    % interactivce
    Error = max(Error,...
        max(abs(Results.Interactive - refinter')));
    % correlative
    Error = max(Error,...
        max(abs(Results.Correlated - refcorr')));
    % firstsum
    Error = max(Error,...
        max(abs(Results.FirstOrder - truesum')));
    
    % Check if the error is greater than the threshold:
    if Error > AllowedError
        error('The test failed for sampling of type %s. \nAbsolute error was: %f',...
            SamplingStrat{jj}, Error);
    end
end
uq_display(myAnalysis,1,'hist')
uq_print(myAnalysis)
close all

success = 1;
