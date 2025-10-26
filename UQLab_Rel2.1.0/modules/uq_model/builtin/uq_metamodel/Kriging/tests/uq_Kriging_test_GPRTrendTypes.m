function pass = uq_Kriging_test_GPRTrendTypes(level)
%UQ_KRIGING_TEST_GPRTRENDTYPES tests for supported trend types in GP regression.
%
%   The tests make sure that different options in MetaOpts.Trend of
%   the Kriging module are valid under regression and the results of 
%   Kriging calculation are correct.
%
%   PASS = UQ_KRIGING_TEST_REGRESSION_OPTIMRESULT(LEVEL) tests the
%   available trend types in the Kriging module to create a 
%   regression model.

%   There are five test functions in this test: constant, linear,
%   quadratic, trigonometric, non-linear model. A noisy version of each 
%   is created and used to generate data (500 points) for training
%   the Kriging model.
%   The test parameters are:
%       1) Input scaling (2): false or true.
%       2) Trend types (8): 'simples', 'ordinary', 'linear', 'quadratic',
%          'custom', 'polynomial', 'custom_coeff', 'custom_handle'.
%
%   The test consists of 16 test cases. All will be executed in the
%   'normal' level.
%   For each test case, the steps are as follows:
%       1) Generate test data from the noiseless full computational model.
%       2) Create a Kriging regression model with noisy full computational
%          model.
%       3) Predict test data using the Kriging regression model.
%       3) Compute the absolute relative error between the mean prediction
%          of the Kriging model and the noiseless full computational model.
%
%   Finally, note that the relative error for the Kriging mean prediction
%   depends on the number of data points and replications.
%   The higher the number of data points and many replications,
%   the better the estimation (but it also takes longer to train).

%% Initialize the test
%
uqlab('-nosplash')

if nargin < 1
    level = 'normal';
end
fprintf('\nRunning: |%s| uq_Kriging_test_GPRTrendTypes...\n',level);

%% parameters
nValid = 1e3;

%% Create inputs
%
InputOpts.Name = 'input_1';
InputOpts.Marginals.Type = 'Uniform' ;
InputOpts.Marginals.Parameters = [0 5];

uq_createInput(InputOpts);

InputOpts.Name = 'input_2';
InputOpts.Marginals(2).Type = 'Uniform';
InputOpts.Marginals(2).Parameters = [0 2];

uq_createInput(InputOpts);

%% Create full computation models (noisy)
%
% 1) y = 0 + noise
ModelOpts.Name = 'y_const';
ModelOpts.mString = 'ones(size(X)) + 0.1*randn(size(X,1),1)';
ModelOpts.isVectorized = true;
ModelOpts.Display = 'quite';

uq_createModel(ModelOpts);

% 2) y = x + noise
ModelOpts.Name = 'y_lin';
ModelOpts.mString = '1 + 5*X + 0.5*randn(size(X,1),1)' ;
ModelOpts.isVectorized = true;
ModelOpts.Display = 'quite';

uq_createModel(ModelOpts);

% 3) y = x^2 + noise
ModelOpts.Name = 'y_sq';
ModelOpts.mString = '2 + 3*X.^2 + 1.0*randn(size(X,1),1)' ;
ModelOpts.isVectorized = true;
ModelOpts.Display = 'quite';

uq_createModel(ModelOpts);

% 4) y = cos(x) + noise
ModelOpts.Name = 'y_trig';
ModelOpts.mString = '2 + cos(X) + 0.1*randn(size(X,1),1)' ;
ModelOpts.isVectorized = true;
ModelOpts.Display = 'quite';

uq_createModel(ModelOpts);

% 5) y = 2*x1 + x2 + noise
ModelOpts.Name = 'y_ind';
ModelOpts.mString = '2*X(:,1)+ X(:,2).^2 + 0.5*randn(size(X,1),1)';
ModelOpts.isVectorized = true;
ModelOpts.Display = 'quite';

uq_createModel(ModelOpts);

%% Create full computation models (true)
%
% 1) y = 0
ModelOpts.Name = 'y_const_true';
ModelOpts.mString = 'ones(size(X))';
ModelOpts.isVectorized = true;
ModelOpts.Display = 'quite';

uq_createModel(ModelOpts);

% 2) y = x
ModelOpts.Name = 'y_lin_true';
ModelOpts.mString = '1 + 5*X';
ModelOpts.isVectorized = true;
ModelOpts.Display = 'quite';

uq_createModel(ModelOpts);

% 3) y = x^2
ModelOpts.Name = 'y_sq_true';
ModelOpts.mString = '2 + 3*X.^2';
ModelOpts.isVectorized = true;
ModelOpts.Display = 'quite';

uq_createModel(ModelOpts);

% 4) y = cos(x)
ModelOpts.Name = 'y_trig_true';
ModelOpts.mString = '2 + cos(X)';
ModelOpts.isVectorized = true;
ModelOpts.Display = 'quite';

uq_createModel(ModelOpts);

% 5) y = 2*x1 + x2
ModelOpts.Name = 'y_ind_true';
ModelOpts.mString = '2*X(:,1)+ X(:,2).^2';
ModelOpts.isVectorized = true;
ModelOpts.Display = 'quite';

uq_createModel(ModelOpts);

%% Create test cases
%
scaling = [false true];
KrigModelNames = {'simple', 'ordinary', 'linear', 'quadratic',...
    'custom', 'polynomial', 'custom_coeff', 'custom_handle'};
FullModelNames = {'y_const', 'y_const', 'y_lin', 'y_sq',...
    'y_trig', 'y_sq', 'y_ind', 'y_ind'};
InputNames = {'input_1', 'input_1', 'input_1', 'input_1',...
    'input_1', 'input_1', 'input_2', 'input_2'};

ScalingString = {'unscaled', 'scaled'};

combIdx = uq_findAllCombinations(scaling, KrigModelNames);

% For normal level randomly pick n Cases only
if strcmpi(level,'normal')
    nSamples = 50;
    eps = 1.0;
else
    nSamples = 500;
    eps = 1.0;
end

pass = false(size(combIdx,1),1);

%% Display the header for the test iterations
LogicalString = {'false', 'true'};
headerString = {'No.', '# Dim.', 'Model', 'Scaling',...
    'Trend', 'Rel.Err.', 'Success'};
fprintf('\n%5s %7s %7s %7s %13s %10s %7s\n', headerString{:})
FormatString = '%5d %7s %7s %7s %13s %10.3e %7s\n';

%% Run all test cases
%
for i = 1:size(combIdx,1)
    clear MetaOpts
    % General Kriging options
    MetaOpts.Type = 'Metamodel';
    MetaOpts.MetaType = 'Kriging';
    MetaOpts.Input = InputNames{combIdx(i,2)};
    MetaOpts.ExpDesign.NSamples = nSamples;
    MetaOpts.ExpDesign.Sampling = 'LHS';
    MetaOpts.Display = 'quiet';
    
    % Noise estimation
    MetaOpts.Regression.SigmaNSQ = 'auto';
    
    % Scaling option
    MetaOpts.Scaling = scaling(combIdx(i,1));
    
    % Optimization
    MetaOpts.Optim.Method = 'cmaes';
    
    % Create Kriging Model with different trend
    MetaOpts.Name = [KrigModelNames{combIdx(i,2)}, '_',...
        ScalingString{combIdx(i,1)}];
    MetaOpts.Trend.Type = KrigModelNames{combIdx(i,2)};
    MetaOpts.FullModel = FullModelNames{combIdx(i,2)};
    
    switch KrigModelNames{combIdx(i,2)}
        case 'simple'
            rng(51,'twister')
            MetaOpts.Trend.CustomF = 1;
            % Generate validation points
            uq_selectInput('input_1');
            Xtest = uq_getSample(nValid);
            Yfull = uq_evalModel(uq_getModel('y_const_true'),Xtest);
        case 'ordinary'
            rng(100,'twister')
            % Generate validation points
            uq_selectInput('input_1');
            Xtest = uq_getSample(nValid);
            Yfull = uq_evalModel(uq_getModel('y_const_true'),Xtest);
        case 'linear'
            rng(5232,'twister')
            % Generate validation points
            uq_selectInput('input_1');
            Xtest = uq_getSample(nValid);
            Yfull = uq_evalModel(uq_getModel('y_lin_true'),Xtest);
        case 'quadratic'
            rng(8047,'twister')
            % Generate validation points
            uq_selectInput('input_1');
            Xtest = uq_getSample(nValid);
            Yfull = uq_evalModel(uq_getModel('y_sq_true'),Xtest);            
        case 'custom'
            rng(310,'twister')
            MetaOpts.Trend.CustomF = 'cos';
            % Generate validation points
            Xtest = linspace(-1,1,nValid)';
            Yfull = uq_evalModel(uq_getModel('y_trig_true'),Xtest);
        case 'polynomial'
            rng(3815,'twister')
            MetaOpts.Trend.Degree = 3;
            MetaOpts.Trend.PolyTypes = 'simple_poly';
            % Generate validation points
            uq_selectInput('input_1');
            Xtest = uq_getSample(nValid);
            Yfull = uq_evalModel(uq_getModel('y_sq_true'),Xtest);
        case 'custom_coeff'
            rng(786,'twister')
            MetaOpts.Input = 'input_2';
            MetaOpts.Trend.Type = 'polynomial';
            MetaOpts.Trend.PolyTypes = {'simple_poly','simple_poly'} ;
            MetaOpts.Trend.TruncOptions.Custom = [ 0 0; 0 1; 1 0; 0 2;...
                2 0; 0 3; 3 0; 1 1; 1 2; 2 1;];
            % Generate validation points
            uq_selectInput('input_2');
            Xtest = uq_getSample(nValid);
            Yfull = uq_evalModel(uq_getModel('y_ind_true'),Xtest);
        case 'custom_handle'
            rng(5054,'twister')
            MetaOpts.Input = 'input_2';
            MetaOpts.Trend = [];
            MetaOpts.Trend.Handle = @(x,dum) [ones(size(x,1),1),...
                x(:,2), x(:,1),...
                x(:,2).^2, x(:,1).^2,...
                x(:,2).^3, x(:,1).^3,...
                x(:,1).*x(:,2),...
                x(:,1).^2.*x(:,1), x(:,1).*x(:,2).^2] ;
            MetaOpts.FullModel = 'y_ind';
            % Generate validation points
            uq_selectInput('input_2');
            Xtest = uq_getSample(nValid);
            Yfull = uq_evalModel(uq_getModel('y_ind_true'),Xtest);
    end
    
    myKriging = uq_createModel(MetaOpts);
    
    % Generate prediction points using only the Kriging trend
    % because the full model is noise-free.
    Ypred = uq_evalModel(myKriging,Xtest);
    
    % Compute abolute relative error
    err = mean(abs((Ypred - Yfull)./Yfull));
    pass(i) = err < eps;

    % Print results
    fprintf(FormatString,...
        i,...
        InputNames{combIdx(i,2)},...
        FullModelNames{combIdx(i,2)},...
        LogicalString{combIdx(i,1)},...
        KrigModelNames{combIdx(i,2)},...
        err,...
        LogicalString{pass(i)+1})
end

pass = all(pass);

end
