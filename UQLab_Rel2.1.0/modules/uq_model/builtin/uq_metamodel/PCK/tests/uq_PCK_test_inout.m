function success = uq_PCK_test_inout( level )
%This test function checks whether all spedifications are passed and used
%in the calibration of the meta-model

success = 0;
rng(1)

%% Start test:
uqlab('-nosplash');
uq_retrieveSession;
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_PCK_test_comp_PCE_Krig...\n']);

%% a computational model with several response values
mopts.mFile = 'uq_ishigami';
mopts.isVectorized = 1;
myModel = uq_createModel(mopts, '-private');

%% and an input model
for ii = 1:3
    iopts.Marginals(ii).Type = 'Uniform';
    iopts.Marginals(ii).Moments = [-pi,pi];
end
myInput = uq_createInput(iopts, '-private');

%% a sequential PC-Kriging model with no default values
sopts.Type = 'Metamodel';
sopts.MetaType = 'PCK';
sopts.Mode = 'optimal';
sopts.Input = myInput;
sopts.FullModel = myModel;
sopts.ExpDesign.Sampling = 'MC';
sopts.ExpDesign.NSamples = 43;
sopts.Display = 0;
sopts.Kriging.Corr.Family = 'Gaussian';
sopts.Kriging.Corr.Type = 'separable';
sopts.PCE.Degree = [2 3];
sopts.CombCrit = 'rel_loo';

mySPCK = uq_createModel(sopts);

%% checks
switch false
    case strcmp(sopts.Mode, mySPCK.Internal.Mode)
        ErrMsg = sprintf('mode');
    case strcmp(sopts.Input.Name, mySPCK.Internal.Input.Name)
        ErrMsg = sprintf('input');
    case strcmp(sopts.FullModel.Name, mySPCK.Internal.FullModel.Name)
        ErrMsg = sprintf('full model');
    case strcmp(sopts.ExpDesign.Sampling, mySPCK.ExpDesign.Sampling)
        ErrMsg = sprintf('sampling strategy');
    case sopts.ExpDesign.NSamples == mySPCK.ExpDesign.NSamples
        ErrMsg = sprintf('number of samples');
    case sopts.Display == mySPCK.Internal.Display
        ErrMsg = sprintf('display');
    case strcmp(sopts.Kriging.Corr.Family, mySPCK.Internal.Kriging.Internal.Kriging.GP.Corr.Family)
        ErrMsg = sprintf('correlation family');
    case strcmp(sopts.Kriging.Corr.Type, mySPCK.Internal.Kriging.Internal.Kriging.GP.Corr.Type)
        ErrMsg = sprintf('correlation type');
    case all(sopts.PCE.Degree == mySPCK.Internal.PCE.Internal.PCE.DegreeArray)
        ErrMsg = sprintf('pce degree array');
    case strcmp(sopts.CombCrit, mySPCK.Internal.CombCrit)
        ErrMsg = sprintf('combination criterion');
    otherwise
        success = 1;
        fprintf('\nTest uq_PCK_test_inout finished successfully!\n')
end

if success == 0
    ErrStr = sprintf('\nError in uq_PCK_test_inout while comparing the %s\n', ErrMsg);
    error(ErrStr);
end

