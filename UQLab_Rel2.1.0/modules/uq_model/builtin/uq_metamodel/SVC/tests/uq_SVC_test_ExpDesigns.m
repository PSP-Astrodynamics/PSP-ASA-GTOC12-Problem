function pass = uq_SVC_test_ExpDesigns( level )
% Make sure that Kriging works with user defined experimental designs
% regardless of scaling choice
Scaling_choices = [0,1];
fname = 'SVCValTest.mat';
N = 50;
Nval = 500;
eps = 5e-1; % Large error threshold. The idea is just to make sure that the code runs without any error
rng(10,'twister');
%%% SECTION TITLE
% DESCRIPTIVE TEXT
% Initialize test:
pass = 1;
evalc('uqlab');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_SVC_test_ExpDesigns...\n']);


% Xtrain  = [ -1   -0.7143   -0.4286   -0.1429    0.1429    0.4286    0.7143 1];
% Ytrain = [0.0385    0.0727    0.1788    0.6622    0.6622    0.1788    0.0727  0.0385];

%% Create input
Input.Marginals(1).Type = 'Uniform' ;
Input.Marginals(1).Parameters = [-1, 1] ;
Input.Marginals(2).Type = 'Uniform' ;
Input.Marginals(2).Parameters = [-1, 1] ;
Input.Name = 'Input1';
uq_createInput(Input);
% Create Experimental Design
model.Name = 'Bisector';
model.mFile = 'uq_bisector' ;
evalc('uq_createModel(model)');

Xtrain = uq_getSample(N, 'Sobol');
Xval = uq_getSample(Nval, 'Sobol');
BisectorFull = uq_selectModel(model.Name);

Ytrain = uq_evalModel(BisectorFull,Xtrain);
Yval = uq_evalModel(BisectorFull,Xval);

% General kriging options
metaopts.Type = 'Metamodel';
metaopts.MetaType = 'SVC';
metaopts.Optim.Method = 'CE' ;
% metaopts.Optim.CE.nPop = 100;
metaopts.Optim.MaxIter = 3;
metaopts.Optim.Bounds.C = 2.^[0;3] ;
metaopts.Bounds.theta = 2.^[-3; 3] ;

% Use ExpDesign of Sampling type 'user'
metaopts.ExpDesign.Sampling = 'user';
metaopts.ExpDesign.X = Xtrain;
metaopts.ExpDesign.Y = Ytrain;
modelID = 0;
for ii = 1 : length(Scaling_choices)
    modelID = modelID + 1;
    % 1) An input module has been defined
    metaopts.Name = ['SVCModelTest',num2str(modelID)];
    metaopts.Input = 'Input1';
    metaopts.Scaling = logical(Scaling_choices(ii)) ;
    [~,SVCModel] = evalc('uq_createModel(metaopts)');
    Yclass = uq_evalModel(SVCModel,Xval);
    predictErr = mean(Yclass .* Yval < 0) ;
    pass = pass & predictErr < eps;
    %     fprintf('\n pErr = %d \n',predictErr);
    % 2) No input module has been defined
    modelID = modelID + 1;
    metaopts.Name = ['SVCModelTest',num2str(modelID)];
    metaopts.Input = [];
    [~,SVCModel] = evalc('uq_createModel(metaopts)');
    Yclass = uq_evalModel(SVCModel,Xval);
    predictErr = mean(Yclass .* Yval < 0) ;
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
        metaopts.Name = ['SVCModelTest',num2str(modelID)];
        metaopts.Input = 'Input1';
        metaopts.Scaling = logical(Scaling_choices(ii)) ;
        [~,SVCModel] = evalc('uq_createModel(metaopts)');
        Yclass = uq_evalModel(SVCModel,Xval);
        predictErr = mean(Yclass .* Yval < 0) ;
        pass = pass & predictErr < eps;
        %     fprintf('\n pErr = %d \n',predictErr);
        
        % 2) No input module has been defined
        modelID = modelID + 1;
        metaopts.Name = ['SVCModelTest',num2str(modelID)];
        metaopts.Input = [];
        [~,SVCModel] = evalc('uq_createModel(metaopts)');
        Yclass = uq_evalModel(SVCModel,Xval);
        predictErr = mean(Yclass .* Yval < 0) ;
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
