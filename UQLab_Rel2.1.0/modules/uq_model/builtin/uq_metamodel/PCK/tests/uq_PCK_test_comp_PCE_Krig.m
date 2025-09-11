function success = uq_PCK_test_comp_PCE_Krig( level )
%This test function checks the special cases of PC-Kriging:
% - PC-Kriging with nugget correlation should be identical to PCE
% - PC-Kriging with constant tredn should be identical to ordinary Kriging
% - PCE-trend Kriging is identical to sequential PC-Kriging (same
%   polynmials)

success = 0;

%% Start test:
uqlab('-nosplash');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_PCK_test_comp_PCE_Krig...\n']);

%% the ishigami function
mopts.mFile = 'uq_ishigami';
mopts.isVectorized = 1;
myModel = uq_createModel(mopts, '-private');

%% and a probabilistic input model
for ii = 1:3
    iopts.Marginals(ii).Type = 'uniform';
    iopts.Marginals(ii).Parameters = [-pi, pi];
end
myInput = uq_createInput(iopts, '-private');

%% generation of an experimental design
rng(1)
X = uq_getSample(myInput, 20, 'LHS');
Y = uq_evalModel(myModel, X);

%% and a validation set
rng(1)
x = uq_getSample(myInput, 100, 'MC');

%% PC-KRIGING WITH NUGGET CORRELATION SHOULD BE IDENTICAL TO PCE
%PCE
popts.Type = 'Metamodel';
popts.MetaType = 'PCE';
popts.Input = myInput;
popts.FullModel = myModel;
popts.ExpDesign.X = X;
popts.ExpDesign.Y = Y;
popts.Degree = 5;
popts.Display = 0;

myPCE = uq_createModel(popts, '-private');

% sequential PC-Kriging
sopts.Type = 'Metamodel';
sopts.MetaType = 'PCK';
sopts.Mode = 'sequential';
sopts.Input = myInput;
sopts.FullModel = myModel;
sopts.ExpDesign.X = X;
sopts.ExpDesign.Y = Y;
sopts.Kriging.Corr.Family = 'nugget';
sopts.Kriging.Corr.Type = 'Separable';
sopts.PCE.Degree = 5;
sopts.Display = 0;

mySPCK = uq_createModel(sopts, '-private');

%prediction 
y_pce = uq_evalModel(myPCE, x);
y_spck = uq_evalModel(mySPCK, x);
%prediction error
delta_pce_spck = y_pce-y_spck;

%% PC-KRIGING WITH CONSTANT TREND EQUALS ORDINARY KRIGING
%sequential PC-Kriging
sopts2.Type = 'Metamodel';
sopts2.MetaType = 'PCK';
sopts2.Mode = 'sequential';
sopts2.Input = myInput;
sopts2.FullModel = myModel;
sopts2.ExpDesign.X = X;
sopts2.ExpDesign.Y = Y;
sopts2.PCE.Degree = 0;
sopts2.Kriging.Optim.Method = 'none';
sopts2.Kriging.Optim.InitialValue =  [0.5 0.5 0.5];
sopts2.Display = 0;

mySPCK2 = uq_createModel(sopts2, '-private');

% ordinary Kriging
oopts.Type = 'Metamodel';
oopts.MetaType = 'Kriging';
oopts.Input = myInput;
oopts.FullModel = myModel;
oopts.ExpDesign.Sampling = 'user';
oopts.ExpDesign.X = X;
oopts.ExpDesign.Y = Y;
oopts.Display = 0;
oopts.Scaling = mySPCK2.Internal.AuxSpace;

oopts.Optim.Method = 'none';
oopts.Optim.InitialValue =  [0.5 0.5 0.5];

myOK = uq_createModel(oopts, '-private');

%prediction
[y_ok_m, y_ok_s2] = uq_evalModel(myOK, x);
[y_spck2_m, y_spck2_s2] = uq_evalModel(mySPCK2, x);

%prediction error
delta_ok_spck2_m = y_ok_m - y_spck2_m;
delta_ok_spck2_s2 = y_ok_s2 - y_spck2_s2;

%% PCE TREND KRIGING EQUALS SEQUENTIAL PC-KRIGING
eopts.Type = 'Metamodel';
eopts.MetaType = 'PCK';
eopts.Mode = 'sequential';
eopts.Input = myInput;
eopts.FullModel = myModel;
eopts.ExpDesign.X = X;
eopts.ExpDesign.Y = Y;
eopts.Kriging.Optim.Method = 'none' ;
eopts.Kriging.Optim.InitialValue = [0.5 0.5 0.5]  ;

eopts.Display = 0;

%retreive polynomials from mySPCK
eopts.PolyTypes = mySPCK2.Internal.PCE.PCE.Basis.PolyTypes;
eopts.PolyIndices = mySPCK2.Internal.PCE.PCE.Basis.Indices(mySPCK2.Internal.PCE.Internal.PCE.LARS.lars_idx,:);

myPPCK = uq_createModel(eopts);

%prediction
[y_pp_m, y_pp_s2] = uq_evalModel(myPPCK, x);

%prediction error
delta_pp_spck2_m = y_pp_m - y_spck2_m;
delta_pp_spck2_s2 = y_pp_s2 - y_spck2_s2;

%% check the values/error
switch false
    case sum(delta_pce_spck.^2)<1e-20
        ErrMsg = sprintf('delta_pce_spck');
    case sum(delta_ok_spck2_m.^2) == 0
        ErrMsg = sprintf('delta_ok_spck2_m');
    case sum(delta_ok_spck2_s2.^2) <1e-20
        ErrMsg = sprintf('delta_ok_spck2_s2'); 
    case sum(delta_pp_spck2_m.^2) == 0
        ErrMsg = sprintf('delta_pp_spck2_m');
    case sum(delta_pp_spck2_s2.^2) == 0
        ErrMsg = sprintf('delta_pp_spck2_s2');
    otherwise
        success = 1;
        fprintf('\nTest uq_PCK_test_comp_PCE_Krig finished successfully!\n');
end
if success == 0
    ErrStr = sprintf('\nError in uq_PCK_test_comp_PCE_Krig while comparing the %s\n', ErrMsg);
    error(ErrStr);
end

