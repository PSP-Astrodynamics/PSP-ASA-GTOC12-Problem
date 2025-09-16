function pass = uq_GLaM_test_MultiOutput( level )
% PASS = UQ_GLAM_TEST_MULTIOUTPUT(LEVEL): check if the GLaM set-up works for
% different kinds of PCE's
uqlab('-nosplash');
rng(100,'twister')

GLaMMethods = {'FullReg','RepJoint'};
% Initialize test:
pass = true;

if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_GLaM_test_MultiOutput...\n']);

%% a computational model with several response values
modelopts.mFile = 'uq_GBM_MultiOutputs'; % specify the function name
modelopts.isStochastic = true; % specify the function name
myModel = uq_createModel(modelopts, '-private');        % create the model object

%% INPUT
Input.Marginals(1).Name = 'mu';
Input.Marginals(1).Type = 'Uniform';
Input.Marginals(1).Parameters = [0,0.2]; % (m)

Input.Marginals(2).Name = 'sigma';
Input.Marginals(2).Type = 'Uniform';
Input.Marginals(2).Parameters = [0.1,0.3]; % (m)

myInput = uq_createInput(Input, '-private');

%% Setup for lambda
metaopts.Lambda(1).Degree=0:3;
metaopts.Lambda(2).Degree=0:1;
metaopts.Lambda(3).Degree=0:1;
metaopts.Lambda(4).Degree=0:1;

%% GLaM Metamodel
for ii = 1 : length(GLaMMethods)    
    metaopts.Type = 'metamodel';
    metaopts.MetaType = 'GLaM';
    metaopts.Input = myInput ;
    metaopts.FullModel = myModel;
    
    metaopts.Method = GLaMMethods{ii};
    
    switch lower(metaopts.Method)
        case {'fullreg'}
            metaopts.ExpDesign.Sampling = 'LHS';
            metaopts.ExpDesign.NSamples = 250;
        case 'repjoint'
            metaopts.Method = 'RepJoint';
            metaopts.ExpDesign.NSamples = 10;
            metaopts.ExpDesign.Replications = 50;
    end
    try
        myGLaM = uq_createModel(metaopts);
        uq_print(myGLaM,1);
        uq_print(myGLaM,2);
        uq_display(myGLaM,1);
        close(gcf)
        uq_display(myGLaM,1,'lambda');
        close(gcf)
        uq_display(myGLaM,[1 2]);
        close(gcf)
        close(gcf)
        uq_display(myGLaM,[1 2],'lambda');
        close(gcf)
        close(gcf)
    catch
        pass = false;        
    end
end

if ~pass
    ErrStr = '\nError in uq_GLaM_test_MultiOutput\n';
    error(ErrStr)
end
