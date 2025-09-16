function pass = uq_Kriging_test_GPRHomoscedastic(level)
%UQ_KRIGING_TEST_GPRHOMOSCEDASTIC(LEVEL) tests for the homoscedastic noise
% option in GP Regression
%
%  Summary:
%  The test makes sure that calculating for the covaraiance and Kriging
%  variance whether using the covariance matrix (Eq. 1.17  in the manual)
%  or the  modified correlation matrix + tau (Eq. 1.26) are leading to the
%  same results

%% Initialize the test
uqlab('-nosplash')
if nargin < 1
    level = 'normal';
end
fprintf('\nRunning: |%s| uq_Kriging_test_GPRHomoscedastic...\n',level)

% Test parameters
Scaling_choices = [0,1];    % Scaling options
thresh = 1e-3;              % Numerical threshold for float comparions
N = 10;                     % Number of sample points
noise = 2 ;                 %  noise level
x = linspace(0,15,50)';    % testing points
pass = true ;

%% Experimental design

% Full computational model
ModelOpts.mString = 'X.*sin(X)';
ModelOpts.isVectorized = true;
myModel = uq_createModel(ModelOpts,'-private');

% Probabilistic input model
InputOpts.Marginals.Type = 'Uniform';
InputOpts.Marginals.Parameters = [0 15];
myInput = uq_createInput(InputOpts,'-private');

% Create experimental design
X = uq_getSample(myInput,N,'LHS');
Y = uq_evalModel(myModel,X) + noise*randn(N,1);

%% Build a Kriging model
metaopts.Type =  'Metamodel';
metaopts.MetaType = 'Kriging';
metaopts.Input = myInput;
metaopts.FullModel = myModel;
metaopts.ExpDesign.X = X;
metaopts.ExpDesign.Y = Y;

for ii = 1 : length(Scaling_choices)

    metaopts.Scaling = Scaling_choices(ii) ;

    %Homoscedastic case:
    % Pass the noise parameter as a single scalar - Eq. 1.26 should be used
    metaopts.Regression.SigmaNSQ = noise.^2;
    rng(100,'twister')
    [~,KrigModel] = evalc('uq_createModel(metaopts)');
    [Y1,V1] = uq_evalModel(KrigModel,x);
    [Y1,V11,C1] = uq_evalModel(KrigModel,x);

    % Heteroscedastic case:
    % pass the noise parameter as a vector - Eq. 1.17 should be used
    metaopts.Regression.SigmaNSQ = noise.^2*ones(N,1);
    rng(100,'twister');
    [~,KrigModel] = evalc('uq_createModel(metaopts)');
    [Y2,V2] = uq_evalModel(KrigModel,x);
    [Y2,V22,C2] = uq_evalModel(KrigModel,x);

    %% Tests

    % Make sure now that the covariance in both cases are the same
    pass = pass & all(max(abs(C1-C2))<thresh);

    % Make sure that the variances are the same
    pass = pass & all(max(abs(V1-V2))<thresh);

    % Additional check
    % Make sure now that the the variances computed using two or three
    % arguments are the same (in case of 3 arguments, the variance is actually
    % obtained as the diagonal of the covariance, i.e., V11 = diag(C1)
    pass = pass & max(abs(V1-V11))<thresh ;
    pass = pass & max(abs(V2-V22))<thresh;
end

end
