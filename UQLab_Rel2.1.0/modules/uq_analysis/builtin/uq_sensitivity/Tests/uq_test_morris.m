function success = uq_test_morris(level)
% SUCCESS = UQ_TEST_MORRIS(LEVEL): non-regression test for the Morris method
%     on the toy function x1 + x2 + 0.1*x3 + 0.1*x4
%
% See also: UQ_MORRIS_INDICES,UQ_TEST_MORRIS_HIGH_ORDER_INTERACTIONS

success = 0;

%% Start the framework:
uqlab('-nosplash');
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |', level,...
    '| uq_test_morris...\n']);
%% Input
M = 4;
[IOpts.Marginals(1:M).Type] = deal('Uniform');
[IOpts.Marginals(1:M).Parameters] = deal([-5, 5]);
ihandle = uq_createInput(IOpts);

%% Test example, x1 and x2 have higher importance than x3 and x4
modelopts.Name = 'Test case morris';
modelopts.mString = 'X(:, 1) + X(:, 2) + 0.1*(X(:, 3) + X(:, 4))';
modelopts.isVectorized = true;
TestCaseModel = uq_createModel(modelopts);

% We also create the ishigami model, in order to check if the analysis is
% able to use a model that is not currently selected:
model2opts.Name = 'False model';
model2opts.mFile = 'uq_ishigami';
Model2 = uq_createModel(model2opts);


%% Sensitivity
Sensopts.Type = 'Sensitivity';
Sensopts.Model = TestCaseModel;
Sensopts.Method = 'Morris';
Sensopts.Display = 'quiet';
% 100 samples per factor:
Sensopts.Morris.FactorSamples = 100;

% Boundaries of the factors:
[Factors(1:M).Boundaries] = deal([-5, 5]);
Sensopts.Factors = Factors;

%% Test:
% General error that is allowed in the comparisons:
AllowedError = 1e-7;

% Features to be tested:
GridLevels = {2, 3, 5};
PerturbationSteps = {1, 2, 10};


for ii = 1:length(GridLevels)
    Sensopts.Morris.GridLevels = GridLevels{ii};
    
    for jj = 1:length(PerturbationSteps)
        Sensopts.Morris.PerturbationSteps = PerturbationSteps{jj};
        
        % Run the analysis
        Sensopts.Name = sprintf('testing morris %d%d', ii, jj);
        anhandle = uq_createAnalysis(Sensopts);
        Results = anhandle.Results(end);
        
        % Test the results:
        Error = 0;
        
        % Check that, more or less, mu1 == mu2 and mu3 = mu4
        Error = max(Error, abs(Results.MuStar(1) - Results.MuStar(2)));
        Error = max(Error, abs(Results.MuStar(3) - Results.MuStar(4)));
        
        % Check that all the standard deviations are close to 0
        % Error = max(Error, max(abs(Results.Std)));
        
        if Error > AllowedError
            error('\nThe test failed for GridLevels = %d PerturbationSteps = %d. \nAbsolute error was: %f',...
                GridLevels{ii}, PerturbationSteps{jj}, Error);
        end
    end
end

try uq_evalModel(ones(1, 3));
    success = 1;
catch
    error('The original model was not restored to be the selected model');
end
