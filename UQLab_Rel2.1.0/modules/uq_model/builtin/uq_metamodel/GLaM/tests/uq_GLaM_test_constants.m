function pass = uq_GLaM_test_constants(level)
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
DiffThreReg = 0.2;
DiffThreRep = 0.8;
rng(100,'twister')

if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
    
end
switch level
    case 'normal'
        %
    otherwise
        %
end
fprintf(['\nRunning: |' level '| uq_GLaM_test_constants...\n']);

%% a computational model
modelopts.mFile = 'uq_GBM'; % specify the function name
modelopts.isStochastic = true; % specify the function name
myModel = uq_createModel(modelopts, '-private');        % create the model object

%% and an input model
Input.Marginals(1).Name = 'mu';
Input.Marginals(1).Type = 'Uniform';
Input.Marginals(1).Parameters = [0,0.2]; 

Input.Marginals(2).Name = 'sigma';
Input.Marginals(2).Type = 'Uniform';
Input.Marginals(2).Parameters = [0.1,0.3]; 

Input.Marginals(3).Name = 'Const1';
Input.Marginals(3).Type = 'Constant';
Input.Marginals(3).Parameters = 0.5; 

Input.Marginals(4).Name = 'Const2';
Input.Marginals(4).Type = 'Constant';
Input.Marginals(4).Parameters = 0.5; 

myInput = uq_createInput(Input, '-private');
%% GLaM options
metaopts.Type = 'Metamodel';
metaopts.MetaType = 'GLaM';

metaopts.Input = myInput;
metaopts.FullModel = myModel;

%% Setup for lambda
metaopts.Lambda(1).Degree=0:3;
metaopts.Lambda(2).Degree=0:1;
metaopts.Lambda(3).Degree=0:1;
metaopts.Lambda(4).Degree=0:1;
%%  Get the experimental design
X = uq_getSample(myInput,200,'LHS');
Y = uq_evalModel(myModel,X);
metaopts.ExpDesign.X = X;
metaopts.ExpDesign.Y = Y; 
NLLh = uq_GBM_NLL(X,Y);
%% Create the meta-model for regression method
methods = {'FullReg'};
Nm = length(methods);
myGLaMReg = cell(1,Nm);
NllhGLaMReg = zeros(1,Nm);
for im=1:Nm
    metaopts.Method = methods{im};
    myGLaMReg{im} = uq_createModel(metaopts, '-private');
    NllhGLaMReg(im)=myGLaMReg{im}.Error.NLogLikelihood;
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
