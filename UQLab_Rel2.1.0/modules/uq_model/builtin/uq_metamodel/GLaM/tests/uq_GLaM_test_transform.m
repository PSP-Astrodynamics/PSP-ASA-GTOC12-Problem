function pass = uq_GLaM_test_transform(level)
% UQ_GLaM_TEST_CONSTANTS(LEVEL)
% 
% Summary:  
%   Tests if GLaM can be set up with constants
%
% Details:
%   
%% start a new session
uqlab('-nosplash');
pass = true;
rng(100,'twister')

DiffThreReg = 0.2;
DiffThreRep = 0.8;

if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
    
end
switch level
    case 'normal'
        %
    otherwise
        %
end
fprintf(['\nRunning: |' level '| uq_GLaM_test_transform...\n']);

%% a computational model
modelopts.mFile = 'uq_GBM'; % specify the function name
modelopts.isStochastic = true; % specify the function name
myModel = uq_createModel(modelopts, '-private');        % create the model object

%% and an input model
Input.Marginals(1).Name = 'mu';
Input.Marginals(1).Type = 'Uniform';
Input.Marginals(1).Parameters = [0,0.2]; % (m)

Input.Marginals(2).Name = 'sigma';
Input.Marginals(2).Type = 'Uniform';
Input.Marginals(2).Parameters = [0.1,0.3]; % (m)

myInput = uq_createInput(Input, '-private');
%% GLaM model options
metaopts.Type = 'Metamodel';
metaopts.MetaType = 'GLaM';
metaopts.Input = myInput;
metaopts.FullModel=myModel;
%%
% Setup for lambda (check default values)
metaopts.Lambda(1).TruncOptions.qNorm=0.5:0.1:1;
metaopts.Lambda(2).TruncOptions.qNorm=0.5:0.1:1;
metaopts.Lambda(2).Transform.Type='exp';
metaopts.Lambda(3).Degree=0:2;
metaopts.Lambda(3).TruncOptions.qNorm=0.5:0.1:1;
metaopts.Lambda(3).Transform.Type='logistic';
metaopts.Lambda(3).Transform.Parameters = [-0.1,0.5];
metaopts.Lambda(4).Transform.Type='logistic';
%%  Get the experimental design
X = uq_getSample(myInput,200,'LHS');
Y = uq_evalModel(myModel,X);
metaopts.ExpDesign.X = X;
metaopts.ExpDesign.Y = Y; 
NLLh = uq_GBM_NLL(X,Y);
%% Create the meta-model for regression method
methods = {'FullReg'};
Nm = length(methods);
NllhGLaMReg = zeros(1,Nm);
for im=1:Nm
    metaopts.Method = methods{im};
    myGLaMReg = uq_createModel(metaopts, '-private');
    NllhGLaMReg(im)=myGLaMReg.Error.NLogLikelihood;
end
%% For replication based method
metaopts = rmfield(metaopts,'ExpDesign');
metaopts.ExpDesign.Replications = 50;
metaopts.ExpDesign.NSamples = 20;
metaopts.Method = 'RepJoint';
myGLaMRep = uq_createModel(metaopts, '-private');
NllhGLaMRep = myGLaMRep.Error.NLogLikelihood;
%% Check regression method
Er=abs(NllhGLaMReg-NLLh)/abs(NLLh);
if max(Er)>DiffThreReg
    pass = false;
end
%% Check replication-based method
NllhRep = uq_GBM_NLL(myGLaMRep.ExpDesign.X,myGLaMRep.ExpDesign.Y);
Er2 = abs(NllhGLaMRep-NllhRep)/abs(NllhRep);
if max(Er2)>DiffThreRep
    pass = false;
end
%% 
if ~pass
    ErrStr = '\nError in uq_GLaM_test_constants\n';
    error(ErrStr);
end
