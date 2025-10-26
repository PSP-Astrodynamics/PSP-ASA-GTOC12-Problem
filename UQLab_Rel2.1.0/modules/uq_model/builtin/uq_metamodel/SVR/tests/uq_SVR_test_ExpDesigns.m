function pass = uq_SVR_test_ExpDesigns( level )
% Make sure that Kriging works with user defined experimental designs
% regardless of scaling choice
Scaling_choices = [0,1];
fname = 'SVRValTest.mat';
N = 20;
Nval = 500;
eps = 5e-1; % Large error threshold. The idea is just to make sure that the code runs without error 
rng(10,'twister');
% Initialize test:
pass = 1;
evalc('uqlab');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_SVR_test_ExpDesigns...\n']);


% Xtrain  = [ -1   -0.7143   -0.4286   -0.1429    0.1429    0.4286    0.7143 1];
% Ytrain = [0.0385    0.0727    0.1788    0.6622    0.6622    0.1788    0.0727  0.0385];

%% Create input
Input.Marginals.Type = 'Uniform' ;
Input.Marginals.Parameters = [-1, 1] ;
Input.Name = 'Input1';
uq_createInput(Input);
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
metaopts.MetaType = 'SVR';
metaopts.Optim.Method = 'CMAES' ;
metaopts.Optim.CMAES.nPop = 30;
metaopts.Optim.MaxIter = 3;
metaopts.Optim.Bounds.C = [1e3 1e5]';
metaopts.Optim.Bounds.epsilon = [1e-5 , 0.01]' ;
metaopts.Optim.Bounds.theta = [0.1; 2] ;

% Use ExpDesign of Sampling type 'user'
metaopts.ExpDesign.Sampling = 'user';
metaopts.ExpDesign.X = Xtrain;
metaopts.ExpDesign.Y = Ytrain;
modelID = 0;
for ii = 1 : length(Scaling_choices)
    modelID = modelID + 1;
    % 1) An input module has been defined
    metaopts.Name = ['SVRModelTest',num2str(modelID)];
    metaopts.Input = 'Input1';
    metaopts.Scaling = logical(Scaling_choices(ii)) ;
    [~,SVRModel] = evalc('uq_createModel(metaopts)');
    Ypred = uq_evalModel(SVRModel,Xval);
    predictErr = calcPredErr(Ypred, Yval) ;
    pass = pass & predictErr < eps;
%     fprintf('\n pErr = %d \n',predictErr);
    % 2) No input module has been defined
    modelID = modelID + 1;
    metaopts.Name = ['SVRModelTest',num2str(modelID)];
    metaopts.Input = [];
    [~,SVRModel] = evalc('uq_createModel(metaopts)');
    Ypred = uq_evalModel(SVRModel,Xval);
    predictErr = calcPredErr(Ypred, Yval) ;
    pass = pass & predictErr < eps;
%     fprintf('\n pErr = %d \n',predictErr);
end
% Use ExpDesign of Sampling type 'data'
metaopts.ExpDesign = [];
metaopts.ExpDesign.Sampling = 'data';
metaopts.ExpDesign.DataFile = fname;
%create the datafile and define it in ExpDesign
X = Xtrain; Y = Ytrain; 
save(fname,'X','Y')
try
    for ii = 1 : length(Scaling_choices)
        modelID = modelID + 1;
        % 1) An input module has been defined
        metaopts.Name = ['SVRModelTest',num2str(modelID)];
        metaopts.Input = 'Input1';
        metaopts.Scaling = logical(Scaling_choices(ii)) ;
        [~,SVRModel] = evalc('uq_createModel(metaopts)');
        Ypred = uq_evalModel(SVRModel,Xval);
        predictErr = calcPredErr(Ypred, Yval) ;
        pass = pass & predictErr < eps;
        %     fprintf('\n pErr = %d \n',predictErr);
        
        % 2) No input module has been defined
        modelID = modelID + 1;
        metaopts.Name = ['SVRModelTest',num2str(modelID)];
        metaopts.Input = [];
        [~,SVRModel] = evalc('uq_createModel(metaopts)');
        Ypred = uq_evalModel(SVRModel,Xval);
        predictErr = calcPredErr(Ypred, Yval) ;
        pass = pass & predictErr < eps;
        %     fprintf('\n pErr = %d \n',predictErr);
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


