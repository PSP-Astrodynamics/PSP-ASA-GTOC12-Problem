function pass = uq_PCE_test_ExpDesign( level )
% PASS = UQ_PCE_TEST_EXPDESIGN(LEVEL): non-regression testing for the
% available PCE experimental design sampling strategies

pceMethods = {'OLS','LARS','OMP'}; % This test is not relevant to Quadrature method 
fname = 'KrigValTest.mat';
N = 200;
Nval = 1500;
eps = 1e-5;
rng(10);

% Initialize test:
pass = 1;
evalc('uqlab');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_PCE_test_ExpDesign...\n']);

%% Create input
Input.Marginals.Type = 'Uniform' ;
Input.Marginals.Parameters = [-1, 1] ;
Input.Name = 'Input1';
myInput = uq_createInput(Input);
% Create Experimental Design
model.Name = 'RungeFull';
model.mFile = 'uq_runge' ;

RungeFull = uq_createModel(model);

Xtrain = uq_getSample(N, 'Sobol');
Xval = uq_getSample(Nval, 'Sobol');

Ytrain = uq_evalModel(RungeFull,Xtrain);
Yval = uq_evalModel(RungeFull,Xval);

% General PCE options
metaopts.Type = 'Metamodel';
metaopts.MetaType = 'PCE';
metaopts.Degree = 30;

% Use ExpDesign of Sampling type 'user'
metaopts.ExpDesign = [];
%metaopts.ExpDesign.Sampling = 'user';
metaopts.ExpDesign.X = Xtrain;
metaopts.ExpDesign.Y = Ytrain;
modelID = 0;
for ii = 1 : length(pceMethods)
    modelID = modelID + 1;
    % 1) An input module has been defined
    metaopts.Name = ['PCModelTest',num2str(modelID)];
    metaopts.Input = 'Input1';
    metaopts.Method = pceMethods{ii};
    evalc('PCEModel = uq_createModel(metaopts)');
    Ypred = uq_evalModel(PCEModel,Xval);
    predictErr = calcPredErr(Ypred, Yval) ;
    pass = pass & predictErr < eps;
%     fprintf('\n pErr = %d \n',predictErr);

end
% Use ExpDesign of Sampling type 'data'
metaopts.ExpDesign = [];
% metaopts.ExpDesign.Sampling = 'data';
metaopts.ExpDesign.DataFile = fname;
% create the datafile and define it in ExpDesign
X = Xtrain; Y = Ytrain; 
save(fname,'X','Y')
for ii = 1 : length(pceMethods)
    modelID = modelID + 1;
    % 1) An input module has been defined
    metaopts.Name = ['PCModelTest',num2str(modelID)];
    metaopts.Input = 'Input1';
    evalc('PCEModel = uq_createModel(metaopts)');
    Ypred = uq_evalModel(PCEModel,Xval);
    predictErr = calcPredErr(Ypred, Yval) ;
    pass = pass & predictErr < eps;
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
