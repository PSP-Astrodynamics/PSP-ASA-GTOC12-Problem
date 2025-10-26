function pass = uq_Kriging_test_Constant( level )
% pass = UQ_KRIGING_TEST_CONSTANT(LEVEL): non-regression test for the
% constants support in the Kriging module
%
% Summary:
% Make sure that various Kriging configurations are working as expected
% when using constants in some of the input components

%% initialize test
if nargin < 1
    level = 'normal';
end
evalc('uqlab');

fprintf(['\nRunning: |' level '| uq_Kriging_test_Constant...\n']);

%% Check if the required toolboxes available?
%
% Required toolboxes for the Kriging module
req_toolbox_names = {'Optimization Toolbox',...
    'Global Optimization Toolbox'};
% Check 
[ret_checks, ret_names] = uq_check_toolboxes();
OPTIM_TOOLBOX_EXISTS = any(strcmpi(req_toolbox_names{1},...
    ret_names(ret_checks)));
GOPTIM_TOOLBOX_EXISTS = any(strcmpi(req_toolbox_names{2},...
    ret_names(ret_checks)));

%% parameters
eps = 1e-14 ;
CorrFamilyHandle.Separable = @(X1,X2,th) max(0, 1 - abs(X1-X2)/th);
CorrFamilyHandle.Ellipsoidal = @(h) max(0, 1 - h);
if strcmpi(level, 'normal')
    Ncomp = 1e3;
    Families = {'matern-5_2',CorrFamilyHandle};
else
    Ncomp = 1e3;
    Families = {'matern-5_2','matern-3_2','gaussian','exponential',CorrFamilyHandle};    
end

Trends(1).Type = 'polynomial';
Trends(1).Degree = 3;
Trends(2).Type = 'custom';
Trends(2).CustomF = @(x) x.^2; 
Trends(3).Handle = @(x) x.^2;
TrendCases = 1:length(Trends);

%% input
[inputopts.Marginals(1:5).Type] = deal('uniform') ;
[inputopts.Marginals(1:5).Parameters] = deal([-pi pi]) ;
inputopts.Marginals(2).Type = 'Constant';
inputopts.Marginals(2).Parameters = 3.2;
inputopts.Marginals(4).Type = 'Constant';
inputopts.Marginals(4).Parameters = 2.3;

% create the input
myInput = uq_createInput( inputopts);

%% model
% Physical model: Ishigami function plus two variables that we have set to constant:
model.mHandle = @(X) uq_ishigami_various_outputs([X(:,1),X(:,3),X(:,5)]) + (X(:,2).^2 + X(:,4));
myModel = uq_createModel(model);

%% first create a typical Kriging metamodel 
if ~strcmpi(level,'normal')
    Isotropy = {true, false};
    CorrTypes = {'Separable','Ellipsoidal'};
    % Get the indices of all possible combinations
    combIdx = uq_findAllCombinations(Isotropy, CorrTypes, Families, TrendCases);
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
        testCases(ii).Trend = Trends(combIdx(ii,4));
    end
else
    testCases.Corr.Type = 'Ellipsoidal' ;
    testCases.Corr.Family = 'matern-5_2' ;
    testCases.Corr.Isotropic = false;
    testCases.Corr.Nugget = 0;
end

pass = true;

if OPTIM_TOOLBOX_EXISTS && GOPTIM_TOOLBOX_EXISTS
    optMethod = 'hga';
else
    optMethod = 'cmaes';
end

for nCase = 1 : length(testCases)
    metaopts.Type =  'Metamodel';
    metaopts.MetaType = 'Kriging';
    metaopts.Input = myInput;
    metaopts.FullModel = myModel;
    metaopts.ExpDesign.NSamples = 200;
    metaopts.Trend.Type = 'polynomial' ;
    metaopts.Trend.Degree = 2 ;
    metaopts.ExpDesign.Sampling = 'LHS' ;
    metaopts.Optim.Method = optMethod;
    metaopts.Optim.Bounds = [0.1 ; 3] ;
    metaopts.Corr.Type = testCases(nCase).Corr.Type;
    metaopts.Corr.Family = testCases(nCase).Corr.Family;
    metaopts.Corr.Isotropic = testCases(nCase).Corr.Isotropic ;
    metaopts.EstimMethod = 'CV';
    metaopts.Scaling = 0;
    try
        evalc('myKriging = uq_createModel(metaopts);');
    catch
        fprintf('Evaluation of Kriging failed for test case %d\n',nCase);
        pass = false;
        break
    end
    % get the number of outputs
    Nout = myKriging.Internal.Runtime.Nout;

    %% next create a custom Kriging metamodel
    metaopts2.Type =  'Metamodel';
    metaopts2.MetaType = 'Kriging';
    metaopts2.ExpDesign.X = myKriging.ExpDesign.X ;
    metaopts2.ExpDesign.Y = myKriging.ExpDesign.Y ;
    metaopts2.Input.nonConst = metaopts.Input.nonConst;
    for ii = 1 : Nout
        metaopts2.Kriging(ii).beta = myKriging.Kriging(ii).beta;
        metaopts2.Kriging(ii).sigmaSQ = myKriging.Kriging(ii).sigmaSQ;
        metaopts2.Kriging(ii).theta = myKriging.Kriging(ii).theta;
        metaopts2.Kriging(ii).Corr.Family = myKriging.Internal.Kriging(ii).GP.Corr.Family;
        metaopts2.Kriging(ii).Corr.Type = myKriging.Internal.Kriging(ii).GP.Corr.Type;
        metaopts2.Kriging(ii).Corr.Isotropic = myKriging.Internal.Kriging(ii).GP.Corr.Isotropic;
        metaopts2.Kriging(ii).Trend = metaopts.Trend;
    end

    evalc('myCustomKriging = uq_createModel(metaopts2);');

    %% compare the results
    X = uq_getSample(Ncomp);
    [myKrig_Y, myKrig_Ys ] = uq_evalModel(myKriging,X);
    [myCustKrig_Y, myCustKrig_Ys ] = uq_evalModel(myCustomKriging,X);

    pass = pass & all(max(abs(myCustKrig_Y - myKrig_Y))<eps ) &  ...
        all(max(abs(myCustKrig_Ys - myKrig_Ys))<eps ) ;
    if ~pass
        return
    end
end
