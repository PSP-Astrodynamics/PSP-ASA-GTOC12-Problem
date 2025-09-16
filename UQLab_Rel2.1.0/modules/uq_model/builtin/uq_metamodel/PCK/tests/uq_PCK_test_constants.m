function success = uq_PCK_test_constants( level )
% This test function checks whether PC-Kriging works with constants, in
% particular: 
% - constants as dummy variables in computational model
% - setting one by one variables to constants
% - setting all variables to constants

success = 0;

%% Start test: 
uqlab('-nosplash');
uq_retrieveSession;
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_PCK_test_constants...\n']);

%% Test 1: constants as dummy variables in computational model
% Ishigami function
mopts.mFile = 'uq_ishigami';
mopts.isVectorized = 1;
myModel = uq_createModel(mopts, '-private');

% Probabilistic input vector 
for ii = 1:3
    iopts.Marginals(ii).Type = 'uniform';
    iopts.Marginals(ii).Parameters = [-pi, pi];
end
myInput = uq_createInput(iopts, '-private');

% Same with dummy marginals
ioptsd = iopts;
ioptsd.Marginals(4).Type = 'constant';
ioptsd.Marginals(4).Parameters = 1;
myInputDummy = uq_createInput(ioptsd, '-private');

% Get an experimental design
X = uq_getSample(myInput, 20, 'lhs');
Y = uq_evalModel(myModel, X);

% Compute two PC-Kriging models with different input dimensionality
sopts.Type = 'Metamodel';
sopts.MetaType = 'PCK';
sopts.Mode = 'sequential';
sopts.Display = 0;
sopts.Input = myInput;
sopts.FullModel = myModel;
sopts.ExpDesign.X = X;
sopts.ExpDesign.Y = Y;
sopts.Kriging.Optim.Method = 'none';
sopts.Kriging.Optim.InitialValue = [0.5 0.5 0.5];
mySPCK = uq_createModel(sopts, '-private');

soptsd = sopts;
soptsd.Input = myInputDummy;
soptsd.ExpDesign.X = [X, ones(20,1)];
mySPCKd = uq_createModel(soptsd, '-private');

[ym,ys] = uq_evalModel(mySPCK, [0,0,0]);
[ymd,ysd] = uq_evalModel(mySPCKd, [0,0,0,1]);


%% Test 2: setting one by one variables to constants
% Set a struct indicating which variables are constants
idx(1).Constants = 1;
idx(2).Constants = 2;
idx(3).Constants = 3;
idx(4).Constants = [1 2];
idx(5).Constants = [1 3];
idx(6).Constants = [2 3];

passi = zeros(size(idx));

% Loop over all cases
for ii = 1:length(idx);
    ioptsi = iopts;
    for jj = 1:length(idx(ii).Constants)
        ioptsi.Marginals(idx(ii).Constants(jj)).Type = 'constant';
        ioptsi.Marginals(idx(ii).Constants(jj)).Parameters = 0;
    end
    myInputi = uq_createInput(ioptsi, '-private');
    soptsi = sopts;
    soptsi.Input = myInputi;
    soptsi.ExpDesign = [];
    soptsi.ExpDesign.NSamples = 20;
    soptsi.Kriging.Optim.InitialValue = 0.5*ones(1,3-length(idx(ii).Constants));
    mySPCKi = uq_createModel(soptsi, '-private');
    
    if size(mySPCKi.ExpDesign.U,2) == 3-length(idx(ii).Constants) && ...
            all(mySPCKi.ExpDesign.X(1,idx(ii).Constants) == 0) && ...
            size(mySPCKi.Internal.PCE.PCE.Basis.Indices,2) == 3-length(idx(ii).Constants)
        passi(ii) = 1;
    end
    
end

%% Test 3: setting all variables to constants
% Modify the input vector
for ii = 1:3
    ioptsa.Marginals(ii).Type = 'constant';
    ioptsa.Marginals(ii).Parameters = 0;
end
myInputa = uq_createInput(ioptsa, '-private');

% Compute the PC-Kriging meta-model
soptsa.Type = 'Metamodel';
soptsa.MetaType = 'PCK';
soptsa.Mode = 'sequential';
soptsa.Display = 0;
soptsa.Input = myInputa;
soptsa.FullModel = myModel;
soptsa.ExpDesign.NSamples = 20;
try
    errora = [];
    mySPCKa = uq_createModel(soptsa, '-private');
catch errora
end

%% Check the values/errors
switch false
    % Related to Test 1
    case ym == ymd
        ErrMsg = sprintf('ym and ymd');
    case ys == ysd
        ErrMsg = sprintf('ys and ysd');
    case mySPCK.Error.LOO == mySPCKd.Error.LOO
        ErrMsg = sprintf('LOO and LOOd');
        
    % Related to Test 2
    case all(passi)
        ErrMsg = sprintf('passi (constant indices)');
        
    % Related to Test 3
    case strcmp(errora.message, 'Only constants in the input model, no meta-modelling required.')
        ErrMsg = sprintf('all marginals constant');
    otherwise
        success = 1;
        fprintf('\nTest uq_PCK_test_constants finished successfully!\n');
end
if success == 0
    ErrStr = sprintf('\nError in uq_PCK_test_constants while computing %s\n', ErrMsg);
    error(ErrStr);
end