function pass = uq_GLaM_test_complex_variance(level)
% Summary:
% This piece of code tests if GLaM manages to predict lambdas when the
% most complex polynomial basis is not lambda_1

if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
    
end
switch level
    case 'normal'
        %
    otherwise
        %
end
fprintf(['\nRunning: |' level '| uq_GLaM_test_complex_variance...\n']);


%% 1 - Start a new session
uqlab('-nosplash');
rng(1,'twister')
pass = true;


%% 2 - Define stochastic model
HighlyHeteroskedasticModel = @(X) X(:,1) + (0.1 + 0.3*(X(:,1)).^4).* randn(numel(X(:,1)), 1);
ModelOpts.mHandle = HighlyHeteroskedasticModel;
ModelOpts.isStochastic = true;
myModel = uq_createModel(ModelOpts);

%% 3 - Define inputs
IOpts.Marginals(1).Name = 'X1';
IOpts.Marginals(1).Type = 'Uniform';
IOpts.Marginals(1).Parameters = [0 15];

% Create the latent object
myInput = uq_createInput(IOpts,'-private');


%% 4 - Build GLaM model

try
    % Construct GLaM Model
    MetaOpts.Type = 'Metamodel';
    MetaOpts.MetaType = 'GLaM';
    MetaOpts.Input = myInput;
    MetaOpts.FullModel = myModel;
    % Specify the range for the univariate polynomials
    % degree selection for $\lambda_1-\lambda_4$
    MetaOpts.Lambda(1).Degree = 0:5;
    MetaOpts.Lambda(1).TruncOptions.qNorm=0.2:0.2:1;
    MetaOpts.Lambda(2).Degree = 0:5;
    MetaOpts.Lambda(2).TruncOptions.qNorm=0.2:0.2:1;
    MetaOpts.Lambda(3).Degree = 0:3;
    MetaOpts.Lambda(3).TruncOptions.qNorm=0.2:0.2:1;
    MetaOpts.Lambda(4).Degree = 0:3;
    MetaOpts.Lambda(4).TruncOptions.qNorm = 0.2:0.2:1;
    MetaOpts.Method = 'FullReg';
    MetaOpts.ExpDesign.X = uq_getSample(myInput, 100);
    MetaOpts.ExpDesign.Y = uq_evalModel(MetaOpts.ExpDesign.X);
    
    % Create SPCE model:
    myGLaM = uq_createModel(MetaOpts, '-private');
    
    % Compute lambdas
    lambdas = uq_GLaM_evalLambda(myGLaM, transpose(0:0.1:15));
    
catch
    pass = false;
    
end


if ~pass
    ErrStr = '\nError in uq_GLaM_test_complex_variance\n';
    error(ErrStr)
end


