function success = uq_test_sobol_high_order_interactions(level)
% SUCCESS = UQ_TEST_SOBOL_HIGH_ORDER_INTERACTIONS(LEVEL): non-regression
%     test for several sensitivity analysis methods available on a model
%     that contains only fourth order interactions.
%
% See also: UQ_HIGH_ORDER_INTERACTIONS

%% INITIALIZE THE FRAMEWORK:
% Set the random seed
rng(pi);
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |', level,...
    '| uq_test_sobol_high_order_interactions...\n']);
success = 1;

% Allowed deviation from true results:
Th = 0.15;

%% Decide what features should be tested:
Estimators = {'t', 's', 'sobol'};
switch level
    case 'slow'
        SamplingStrategies = {'mc', 'lhs', 'sobol', 'halton'};
    otherwise
        SamplingStrategies = {'mc'};
end

%% Set up UQLab:
% INPUT
M = 8;
[Input.Marginals(1:M).Type] = deal('Uniform');
[Input.Marginals(1:M).Parameters] = deal([-10, 10]);
testInput = uq_createInput(Input, '-private');

% MODEL
Modelopts.mFile = 'uq_high_order_interactions';
testModel = uq_createModel(Modelopts, '-private');

% ANALYSIS BASIS
Sensopts.Type = 'Sensitivity';
Sensopts.Model = testModel;
Sensopts.Input = testInput;
Sensopts.Method = 'Sobol';
Sensopts.Sobol.Order = 4;
Sensopts.Display = 'nothing';
Sensopts.Sobol.SampleSize = 5e3;

%% Loop of tests:
for ii = 1:length(SamplingStrategies)
    % Choose sampling strategy
    Sensopts.Sobol.Sampling = SamplingStrategies{ii};

    for jj = 1:length(Estimators)
        % Choose an estimator:
        Sensopts.Sobol.Estimator = Estimators{jj};
        
        % Create the analysis and run it:
        anhandle = uq_createAnalysis(Sensopts);
        res = anhandle.Results;
        
        % Validate the results:
        OK = false(1, 5);
        OK(1) = max(abs(res.AllOrders{1})) <= Th;
        OK(2) = max(abs(res.AllOrders{2})) <= Th;
        OK(3) = max(abs(res.AllOrders{3})) <= Th;
        OK(4) = (max(abs(res.AllOrders{4}([1, end]) - 0.5)) <= Th) && ...
            (max(abs(res.AllOrders{4}(2:(end - 1)))) <= Th);
        
        % Total Sobol' indices should be all 0.5:
        OK(5) = max(abs(res.Total - 0.5)) <= Th;
        
        if ~all(OK)
            error('uq_test_sobol_high_order_interactions failed for estimator %s, sampling %s',...
                Estimators{jj}, SamplingStrategies{ii});
        end
    end
end

