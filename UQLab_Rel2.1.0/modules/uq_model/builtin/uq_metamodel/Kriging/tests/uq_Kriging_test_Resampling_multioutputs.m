function pass = uq_Kriging_test_Resampling_multioutputs( level )
% UQ_KRIGING_TEST_TRENDTYPES(LEVEL) Non-regression and validation test
% of the supported trend types of the Kriging module
%
% Summary:
% In the first part all the diffrerent options of Kriging.Trend.Type
% are tested and in the second part it is made sure that regression
% result is correct

%% Initialize test
pass = 1;
uqlab('-nosplash');

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| uq_Kriging_test_Resampling...\n']);

%% parameters
eps = 1e-3;
nvalidation = 500 ;

%% Create inputs
Input.Marginals.Type = 'Uniform' ;
Input.Marginals.Parameters = [0, 5] ;
Input.Name = 'Input1';
uq_createInput(Input);



%% Create the full models
% y = cos(X)
model.Name = 'y_cos';
model.mString = '[cos(X) cos(X)]' ;
model.isVectorized = true;
evalc('uq_createModel(model)');

Nout = 2 ;
% Validation set
Xpred = linspace(0,5,nvalidation)' ;
R = 1000 ; % Replications

% Run the tests for both scaled and unscaled versions:
scaling = [0, 1];
% Run the test for both KL and EOLE (EOLE is default)
DiscScheme = {'EOLE','KL'};

for ii = 1 : length(scaling)
    clear metaopts;
    %% general options
    metaopts.Type = 'Metamodel';
    metaopts.MetaType = 'Kriging';
    metaopts.Input = 'Input1';
    metaopts.ExpDesign.NSamples = 30;
    metaopts.ExpDesign.Sampling = 'LHS' ;
    metaopts.isTrajectory = true ;
    metaopts.GRF.Domain = [0,5]' ;
    metaopts.Scaling = scaling(ii);
    metaopts.Trend.Type = 'simple' ;
    metaopts.FullModel = 'y_cos';

    for jj = 1:length(DiscScheme)
        metaopts.GRF.DiscScheme = DiscScheme{jj} ;
        [~,myKriging] = evalc('uq_createModel(metaopts)');

        %% Calculate Predictions
        rng(1);
        Ytraj1 = uq_evalModel(myKriging,Xpred,R) ;
        [Ymean,Yvar] = uq_evalModel(myKriging,Xpred);

        % Output 1
        for oo = 1:Nout
        YmeanEst = mean(Ytraj1(:,oo,:),3);
        YvarEst = var(Ytraj1(:,oo,:),0,3);

        %% make sure that predictions coincide with full models
        pass = pass & max(abs(Ymean(:,oo)- YmeanEst)) < eps;  % Make sure that the  kriging predictor and the empirical mean are similar
        pass = pass & max(abs(Yvar(:,oo)- YvarEst)) < eps;  % Make sure that the kriging variance and the empirical ones are similar
        end

        % Check the size of the output

        % Check that the two outputs have the same statistics (we are using
        % the exact same function for each)
    end
end
