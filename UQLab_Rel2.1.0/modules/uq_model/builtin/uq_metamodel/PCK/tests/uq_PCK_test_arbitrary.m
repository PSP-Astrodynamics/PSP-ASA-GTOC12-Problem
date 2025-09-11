function success = uq_PCK_test_arbitrary( level )
% This function tests whether arbitrary polynomials work in PC-Kriging. The
% following tests are carried out: 
% - Test 1: Based on truncated input marginals, a PC-Kriging model is 
%   composed. Then, the resulting meta-model should be based on arbitrary
%   polynomials. 
% - Test 2: Given a user-defined trend of arbitrary polynomials, a 
%   PC-Kriging model is computed.

success = 0;

%% Start test: 
uqlab('-nosplash');
uq_retrieveSession;
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_PCK_test_constants...\n']);


%% Test 1: Truncated input marginals test
% Create an input model of truncated distributions
iopts.Marginals(1).Type = 'uniform';
iopts.Marginals(1).Parameters = [0,1];
iopts.Marginals(1).Bounds = [0.1 0.9];
iopts.Marginals(2).Type = 'Gaussian';
iopts.Marginals(2).Parameters = [0 2];
iopts.Marginals(3).Type = 'Gamma';
iopts.Marginals(3).Moments = [1, 1];
iopts.Marginals(3).Bounds = [0 2];
myInput = uq_createInput(iopts, '-private');

% Computational model
mopts.mFile = 'uq_ishigami';
myModel = uq_createModel(mopts, '-private');

% PC-Kriging model
sopts.Type = 'Metamodel';
sopts.MetaType = 'PCK';
sopts.Mode = 'sequential';
sopts.Display = 0;
sopts.Input = myInput;
sopts.FullModel = myModel;
sopts.ExpDesign.NSamples = 10;
sopts.Kriging.Optim.Method = 'none';
sopts.Kriging.Optim.InitialValue = [0.5 0.5 0.5];
mySPCK = uq_createModel(sopts, '-private');


%% Test 2: User-defined arbitrary polynomials in the trend
% Input marginals as Gaussians with zero mean and unit variance
for ii = 1:3
    iopts2.Marginals(ii).Type = 'Gaussian';
    iopts2.Marginals(ii).Parameters = [0,2];
end
myInput2 = uq_createInput(iopts2, '-private');

% The same computational model as before is used
% myModel

% PC-Kriging model
sopts2.Type = 'Metamodel';
sopts2.MetaType = 'PCK';
sopts2.Mode = 'sequential';
sopts2.Display = 0;
sopts2.Input = myInput2;
sopts2.FullModel = myModel;
sopts2.ExpDesign.NSamples = 10;
sopts2.PolyTypes = [{'arbitrary'}, {'arbitrary'}, {'arbitrary'}];
sopts2.PolyIndices = [0 0 0; 1 1 1; 5 5 5];
sopts2.Kriging.Optim.Method = 'none';
sopts2.Kriging.Optim.InitialValue = [0.5 0.5 0.5];
mySPCK2 = uq_createModel(sopts2, '-private');


%% Compare the results
switch false
    % Test 1
    case strcmp(mySPCK.Internal.PCE.PCE.Basis.PolyTypes(1), 'arbitrary') && ...
            strcmp(mySPCK.Internal.PCE.PCE.Basis.PolyTypes(2), 'Hermite') && ...
            strcmp(mySPCK.Internal.PCE.PCE.Basis.PolyTypes(3), 'arbitrary')
        ErrMsg = sprintf('polynomial basis in PCE');
    case all(iopts.Marginals(1).Bounds == mySPCK.Internal.AuxSpace.Marginals(1).Bounds) && ...
            all([0 1] == mySPCK.Internal.AuxSpace.Marginals(2).Parameters) && ...
            all((iopts.Marginals(3).Bounds == mySPCK.Internal.AuxSpace.Marginals(3).Bounds))
        ErrMsg = sprintf('definition of the auxiliary space');
    case all(mySPCK.Internal.Kriging.Internal.Scaling.Marginals(1).Bounds == mySPCK.Internal.AuxSpace.Marginals(1).Bounds) && ...
            all(mySPCK.Internal.Kriging.Internal.Scaling.Marginals(2).Parameters == mySPCK.Internal.AuxSpace.Marginals(2).Parameters) && ...
            all(mySPCK.Internal.Kriging.Internal.Scaling.Marginals(3).Bounds == mySPCK.Internal.AuxSpace.Marginals(3).Bounds)
        ErrMsg = sprintf('scaled space in Kriging');
    
    % Test 2    
    case all(all(sopts2.PolyIndices == mySPCK2.Internal.PCE.PCE.Basis.Indices))
        ErrMsg = sprintf('the custom index set');
    case strcmp(sopts2.PolyTypes(1), mySPCK2.Internal.PCE.PCE.Basis.PolyTypes(1)) && ...
            strcmp(sopts2.PolyTypes(2), mySPCK2.Internal.PCE.PCE.Basis.PolyTypes(2)) && ...
            strcmp(sopts2.PolyTypes(3), mySPCK2.Internal.PCE.PCE.Basis.PolyTypes(3))
        ErrMsg = sprintf('custom polynomial basis in PCE');
    case all(mySPCK2.Internal.Kriging.Internal.Scaling.Marginals(1).Parameters == iopts2.Marginals(1).Parameters) && ...
            all(mySPCK2.Internal.Kriging.Internal.Scaling.Marginals(2).Parameters == iopts2.Marginals(2).Parameters) && ...
            all(mySPCK2.Internal.Kriging.Internal.Scaling.Marginals(3).Parameters == iopts2.Marginals(3).Parameters)
        ErrMsg = sprintf('custom scaled space in Kriging');
        
    otherwise
        success = 1;
        fprintf('\nTest uq_PCK_test_arbitrary finished successfully!\n');
end
if success == 0
    ErrStr = sprintf('\nError in uq_PCK_test_arbitrary while computing %s\n', ErrMsg);
    error(ErrStr);
end