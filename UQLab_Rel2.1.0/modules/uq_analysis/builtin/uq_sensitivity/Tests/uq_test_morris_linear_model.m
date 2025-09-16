function success = uq_test_morris_linear_model(level)
% PASS = UQ_TEST_MORRIS_LINEAR_MODEL(LEVEL): non-regression test for the
%     Morris' method on a linear model. The expected indices are
%     analytical.
%
% See also: UQ_MORRIS_INDICES, UQ_SENSITIVITY
uqlab('-nosplash');

success = 1;

% Allow some numerical error:
Threshold = 1e-10;

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |', level,...
    '| uq_test_morris_linear_model...\n']);

switch level
    case 'slow'
        % Since the perturbation steps cannot exceed the grid levels, these
        % two variables vary together:
        GRID_LEVELS = [2, 10, 10, 100, 100, round(rand*1000) + 100];
        P_STEPS = [1, 1, 5, 1, 50, round(rand*GRID_LEVELS(end) - 5) + 1];
                
    otherwise
        GRID_LEVELS = [round(rand*8) + 2, ...
            round(rand*50) + 2];
        P_STEPS = [round(rand*GRID_LEVELS(1) - 1) + 1, ...
            round(rand*GRID_LEVELS(2) - 1) + 1];
end


% Create a uniform input and a linear model (therefore the estimates of
% the partial derivatives must be exact)

%% INPUT
M = 2;
[Marginals(1:M).Type] = deal('uniform');
Marginals(1).Parameters = [20,21] ;
Marginals(2).Parameters = [0, 1];

IOpts.Marginals=Marginals;uq_createInput(IOpts);

%% MODEL
modelopts.mString = '2*X(:, 1) + 5*X(:, 2)';
modelopts.isVectorized = true;
myModel = uq_createModel(modelopts);

%% ANALYSIS BASIC OPTIONS
analysisopts.Type = 'Sensitivity';
analysisopts.Method = 'morris';
analysisopts.Display = 'nothing';
Factors(1).Boundaries = [20, 21];
Factors(2).Boundaries = [0, 1];
analysisopts.Factors = Factors;


%% TEST

for grid = 1:length(GRID_LEVELS)
    % Define the grid and the factor samples:
    analysisopts.Morris.GridLevels = GRID_LEVELS(grid);
    analysisopts.Morris.PerturbationSteps = P_STEPS(grid);
    analysisopts.Morris.FactorSamples = round(rand*(GRID_LEVELS(grid)-1)^2) + 1;
    

    % Create and run the analysis
    myAnalysis = uq_createAnalysis(analysisopts);
    
    % Test!
    Mu = myAnalysis.Results(end).Mu;
    Sigma = myAnalysis.Results(end).Std;
    if (sum(abs(Mu - [2, 5]')) > Threshold) || (sum(abs(Sigma)) > Threshold)
        fprintf('\n uq_test_morris_linear_model failed for:\n');
        fprintf('Grid levels: %d\n', GRID_LEVELS(grid));
        fprintf('Pert. steps: %d\n', P_STEPS(grid));
        fprintf('Factor samples: %d\n', analysisopts.Morris.FactorSamples);
        success = 0;
        break
    end
    
end
