function pass = uq_randomfield_test_10d( level )
% PASS = uq_randomfield_test_nonregulargird: test that both KL and EOLE run
% on non-regular user-given grid.

% In the v2.0 release the error in this setting is around 0.07 for both
% cases - Set an error slightly aboved to pass the test
eps = 0.1;
rng(1) ;
RFMethods = {'KL','EOLE'};
% Initialize test:
pass = 1;
evalc('uqlab');

% Random field options
RFInput.Type = 'RandomField';
RFInput.RFType = 'Gaussian';
RFInput.Corr.Family = 'Gaussian';
RFInput.Corr.Length = 0.5 ; % Using two correlation lengths

% Mean and Standard deviations
RFInput.Std = 1;
RFInput.Mean = 1;

% Give the mesh for the computation of the variance
RFInput.EOLE.CovMesh = lhsdesign(1000,10) ;
% Use that same mesh for sanmpling trajectories (no interpolation then)
RFInput.Mesh = RFInput.EOLE.CovMesh ;

%% RF module
evalc('myRF = uq_createInput(RFInput)');

%% Validation: Check the variance error
pass = pass &  mean(myRF.RF.VarError) < eps ;

analytical_cov = myRF.Internal.Std^2 * ...
    uq_eval_Kernel(RFInput.Mesh,RFInput.Mesh,RFInput.Corr.Length, ...
    myRF.Internal.Corr) ;

X = uq_getSample(1e4);
err_cov = max(max(analytical_cov - cov(X))) ;

pass = pass & err_cov < eps ;

end