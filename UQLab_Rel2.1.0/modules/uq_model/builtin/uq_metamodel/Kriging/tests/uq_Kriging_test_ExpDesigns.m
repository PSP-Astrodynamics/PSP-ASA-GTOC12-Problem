function pass = uq_Kriging_test_ExpDesigns( level )
% pass = UQ_KRIGING_TEST_EXPDESIGNS(LEVEL): non-regression test for the
% various input scaling options in the Kriging module
%
% Summary:
% Make sure that Kriging works with user defined experimental designs
% regardless of scaling choice

%% initialize test
pass = 1;
evalc('uqlab');
if nargin < 1
    level = 'normal'; 
end
fprintf(['\nRunning: |' level '| uq_Kriging_test_ExpDesigns...\n']);

%% parameters
Scaling_choices = [0,1];
fname = 'KrigValTest.mat';
N = 50;
Nval = 500;
eps = 1e-5;
rng(10);

%% Check availability of some optimization methods
%
% Required toolboxes for some optimization methods in the Kriging module
req_toolbox_names = 'Optimization Toolbox';
% Check 
[ret_checks, ret_names] = uq_check_toolboxes();
OPTIM_TOOLBOX_EXISTS = any(...
    strcmpi(req_toolbox_names,ret_names(ret_checks)));

%% Create input
Input.Marginals.Type = 'Uniform' ;
Input.Marginals.Parameters = [-1, 1] ;
testInput = uq_createInput(Input);
% Create Experimental Design
model.Name = 'RungeFull';
model.mFile = 'uq_runge' ;
evalc('uq_createModel(model)');

Xtrain = uq_getSample(N, 'Sobol');
Xval = uq_getSample(Nval, 'Sobol');
RungeFull = uq_selectModel(model.Name);

Ytrain = uq_evalModel(RungeFull,Xtrain);
Yval = uq_evalModel(RungeFull,Xval);

% General kriging options
metaopts.Type = 'Metamodel';
metaopts.MetaType = 'Kriging';
metaopts.Optim.InitialValue = 0.5;
metaopts.Optim.Bounds = [0.01; 3];
if OPTIM_TOOLBOX_EXISTS
    metaopts.Optim.Method = 'bfgs';
    metaopts.Optim.BFGS.nLM = 10;
else
    metaopts.Optim.Method = 'cmaes';  % CMAES is built-in
end
metaopts.Optim.MaxIter = 10;
metaopts.Optim.Tol = 1e-4;
metaopts.Trend.Type = 'polynomial';
metaopts.Trend.Degree = 3;
metaopts.Trend.PolyTypes = 'simple_poly';

% Use ExpDesign of Sampling type 'user'
metaopts.ExpDesign.X = Xtrain;
metaopts.ExpDesign.Y = Ytrain;
modelID = 0;
for ii = 1 : length(Scaling_choices)
    modelID = modelID + 1;
    % 1) An input module has been defined
    metaopts.Name = ['KrigModelTest',num2str(modelID)];
    metaopts.Input = testInput;
    metaopts.Scaling = logical(Scaling_choices(ii)) ;
    [~,KrigModel] = evalc('uq_createModel(metaopts)');
    Ypred = uq_evalModel(KrigModel,Xval);
    predictErr = calcPredErr(Ypred, Yval) ;
    pass = pass & predictErr < eps;
    % 2) No input module has been defined
    modelID = modelID + 1;
    metaopts.Name = ['KrigModelTest',num2str(modelID)];
    metaopts.Input = [];
    [~,KrigModel] = evalc('uq_createModel(metaopts)');
    Ypred = uq_evalModel(KrigModel,Xval);
    predictErr = calcPredErr(Ypred, Yval) ;
    pass = pass & predictErr < eps;
end
% Use ExpDesign of Sampling type 'data'
metaopts.ExpDesign = [];
metaopts.ExpDesign.DataFile = fname;
%create the datafile and define it in ExpDesign
X = Xtrain; Y = Ytrain; 
save(fname,'X','Y')
try
    for ii = 1 : length(Scaling_choices)
        modelID = modelID + 1;
        % 1) An input module has been defined
        metaopts.Name = ['KrigModelTest',num2str(modelID)];
        metaopts.Input = testInput;
        metaopts.Scaling = logical(Scaling_choices(ii)) ;
        [~,KrigModel] = evalc('uq_createModel(metaopts)');
        Ypred = uq_evalModel(KrigModel,Xval);
        predictErr = calcPredErr(Ypred, Yval) ;
        pass = pass & predictErr < eps;
       
        % 2) No input module has been defined
        if logical(Scaling_choices(ii))
            modelID = modelID + 1;
            metaopts.Name = ['KrigModelTest',num2str(modelID)];
            metaopts.Input = [];
            [~,KrigModel] = evalc('uq_createModel(metaopts)');
            Ypred = uq_evalModel(KrigModel,Xval);
            predictErr = calcPredErr(Ypred, Yval) ;
            pass = pass & predictErr < eps;
        end
    end
catch e
    % delete the datafile
    eval(['delete ',fname]);
    rethrow(e);
end
% delete the datafile
eval(['delete ',fname]);




function predictErr = calcPredErr(YY, YYpred)
if size(YY,1) ~= size(YYpred,1)
    YYpred = transpose(YYpred);
end
if iscolumn(YY)
    YY = transpose(YY);
    YYpred = transpose(YYpred);
end
predictErr = (YY - YYpred).^2;
predictErr = mean(predictErr,2);


