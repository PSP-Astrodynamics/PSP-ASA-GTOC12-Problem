function pass = uq_Kriging_test_CustomKriging( level )
% pass = UQ_KRIGING_TEST_CUSTOMKRIGING(LEVEL): non-regression test for the
% custom Kriging (predictor-only) functionality in the Kriging module
%
% Summary:
% Make sure that a user defined Kriging metamodel is working as expected

%% initialize test
pass = 1;
if nargin < 1
    level = 'normal';
end
evalc('uqlab');

fprintf(['\nRunning: |' level '| uq_Kriging_test_CustomKriging...\n']);
%% parameters
eps = 1e-14 ;
rng(100,'twister');
CorrFamilyHandle.Separable = @(X1,X2,th) max(0, 1 - abs(X1-X2)/th);
CorrFamilyHandle.Ellipsoidal = @(h) max(0, 1 - h);
if strcmpi(level, 'normal')
    Families = {'matern-5_2',CorrFamilyHandle};    
else
    Families = {'matern-5_2','matern-3_2','gaussian','exponential',CorrFamilyHandle};    
end

%% input
[inputopts.Marginals(1:3).Type] = deal('uniform') ;
[inputopts.Marginals(1:3).Parameters] = deal([-pi pi]) ;
% create the input
myInput = uq_createInput( inputopts);

%% model
% Physical model: Ishigami function
model.mFile = 'uq_ishigami_various_outputs' ;
myModel = uq_createModel(model);

%% first create a typical Kriging metamodel 
if ~strcmpi(level,'normal')
    Isotropy = {true, false};
    CorrTypes = {'Separable','Ellipsoidal'};
    % Get the indices of all possible combinations
    combIdx = uq_findAllCombinations(Isotropy, CorrTypes, Families);
    for ii  = 1 : length(combIdx)
        % produce one different test-case for each combination
        testCases(ii).Corr.Isotropic = Isotropy{combIdx(ii,1)};
        testCases(ii).Corr.Type = CorrTypes{combIdx(ii,2)};
        if isstruct(Families{combIdx(ii,3)})
            testCases(ii).Corr.Family = ...
                Families{combIdx(ii,3)}.(testCases(ii).Corr.Type);
        else
            testCases(ii).Corr.Family = Families{combIdx(ii,3)} ;
        end
    end
else
    testCases.Corr.Type = 'Ellipsoidal' ;
    testCases.Corr.Family = 'matern-5_2' ;
    testCases.Corr.Isotropic = false;
    testCases.Corr.Nugget = 0;
end

for nCase = 1:length(testCases)
    metaopts.Type =  'Metamodel';
    metaopts.MetaType = 'Kriging';
    metaopts.Input = myInput;
    metaopts.FullModel = myModel;
    metaopts.ExpDesign.NSamples = 200;
    metaopts.Trend.Type = 'polynomial' ;
    metaopts.Trend.Degree = 2 ;
    metaopts.ExpDesign.Sampling = 'LHS' ;
    metaopts.Optim.Method = 'cmaes';
    metaopts.Optim.Bounds = [0.1 ; 3] ;
    metaopts.Corr.Type = testCases(nCase).Corr.Type;
    metaopts.Corr.Family = testCases(nCase).Corr.Family;
    metaopts.Corr.Isotropic = testCases(nCase).Corr.Isotropic ;
    metaopts.EstimMethod = 'CV';
    metaopts.Scaling = 0;
   
    evalc('myKriging = uq_createModel(metaopts);');
  
    % get the number of outputs
    Nout = myKriging.Internal.Runtime.Nout;
    
    %% next create a custom Kriging metamodel
    metaopts2.Type =  'Metamodel';
    metaopts2.MetaType = 'Kriging';
   
    metaopts2.ExpDesign.X = myKriging.ExpDesign.X ;
    metaopts2.ExpDesign.Y = myKriging.ExpDesign.Y ;
    metaopts2.Input.nonConst = metaopts.Input.nonConst;
    for ii = 1 : Nout
        metaopts2.Kriging(ii).Trend = metaopts.Trend;
        metaopts2.Kriging(ii).beta = myKriging.Kriging(ii).beta;
        metaopts2.Kriging(ii).sigmaSQ = myKriging.Kriging(ii).sigmaSQ;
        metaopts2.Kriging(ii).theta = myKriging.Kriging(ii).theta;
        metaopts2.Kriging(ii).Corr.Family = myKriging.Internal.Kriging(ii).GP.Corr.Family;
        metaopts2.Kriging(ii).Corr.Type = myKriging.Internal.Kriging(ii).GP.Corr.Type;
        metaopts2.Kriging(ii).Corr.Isotropic = myKriging.Internal.Kriging(ii).GP.Corr.Isotropic;
    end
    
    evalc('myCustomKriging = uq_createModel(metaopts2);');
    
    %% compare the results
    X = uq_getSample(1e4);
    [myKrig_Y, myKrig_Ys] = uq_evalModel(myKriging,X);
    [myCustKrig_Y, myCustKrig_Ys] = uq_evalModel(myCustomKriging,X);
    pass = pass & all(max(abs(myCustKrig_Y - myKrig_Y))<eps ) & ...
        all(max(abs(myCustKrig_Ys - myKrig_Ys))<eps);
    
    % Covariance matrix comparison, use smaller test sets
    X = uq_getSample(1e2);
    [~,~,myKrig_YCov] = uq_evalModel(myKriging,X);
    [~,~, myCustKrig_YCov] = uq_evalModel(myCustomKriging,X);
    pass = all(all(max(abs(myCustKrig_YCov - myKrig_YCov))<eps));
end

end
