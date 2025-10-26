function pass = uq_Dispatcher_tests_usage_PCEMultiOutArgs(DispatcherObj)
%UQ_DISPATCHER_TESTS_USAGE_PCEMULTIOUTARGS tests a dispatched computation
%   of a PCE model having multiple output arguments (i.e., bootstrap PCE).
%
%   NOTE:
%   - 'uq_iscloseall' is used to test equalities because the remote MATLAB
%     version may differ and this causes a very small different between
%     the computed numbers.

%% Inititialize the test    
fprintf('Testing: | %s | %s...', DispatcherObj.Name, mfilename)

rng(100,'twister')  % Set random number for reproducibility

% Save current Dispatcher object settings
displayOpt = DispatcherObj.Internal.Display;
execMode = DispatcherObj.ExecMode;
numProcs = DispatcherObj.NumProcs;

% Make sure that the display option is quiet
DispatcherObj.Internal.Display = 0;

%% Computational model

% Create a MODEL object using a function handle
ModelOpts.mHandle = @(X) [X.*sin(X) X.*cos(X)];
myFullModel = uq_createModel(ModelOpts,'-private');

%% Probabilistic input model

% Specify the probabilistic model of the input variable
InputOpts.Marginals(1).Type = 'Uniform';
InputOpts.Marginals(1).Parameters = [0 15];

% Create the INPUT object
myInput = uq_createInput(InputOpts,'-private');

%% Bootstrap PCE metamodel

% Select PCE as the metamodeling tool
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'PCE';
MetaOpts.Display = 'quiet';

% Specify the full computational model
MetaOpts.FullModel = myFullModel;

% Specify the INPUT object
MetaOpts.Input = myInput;

% Create an experimental design
X = uq_getSample(myInput,15);
Y = uq_evalModel(myFullModel,X);

% Specify the experimental design
MetaOpts.ExpDesign.X = X;
MetaOpts.ExpDesign.Y = Y;

% Specify the degree of the expansion
MetaOpts.Degree = 11;

% Specify the number of points in the experimental design
MetaOpts.ExpDesign.NSamples = 15;

% Enable bootstrapping by specifying the number of bootstrap replications
MetaOpts.Bootstrap.Replications = 100;

% Create the PCE metamodel
myPCE = uq_createModel(MetaOpts,'-private');

%% Validation data set

% Create a validation sample on a regular grid:
Xval = linspace(0, 15, 1000)';

% Evaluate the PCE metamodel and the corresponding bootstrap replications
% on the validation sample:
[YPCValLocal,YPCVarLocal,YPCValBootstrapLocal] = uq_evalModel(myPCE,Xval);

%% Synchronized test

% Make sure the dispatched computation is synchronized
DispatcherObj.ExecMode = 'sync';

% Test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation
[YPCVal,YPCVar,YPCValBootstrap] = uq_evalModel(myPCE, Xval, 'HPC');

% Assert the equality of all outputs
assert(uq_iscloseall(YPCValLocal,YPCVal))
% Increase tolerance because some values may be close to zero
assert(uq_iscloseall(YPCVarLocal, YPCVar, 'ATol', 1e-6))
assert(uq_iscloseall(YPCValBootstrapLocal,YPCValBootstrap))

% Test with multiple remote processes
DispatcherObj.NumProcs = 3;

% Dispatch the computation
[YPCVal,YPCVar,YPCValBootstrap] = uq_evalModel(myPCE, Xval, 'HPC');

% Assert the equality of all outputs
assert(uq_iscloseall(YPCValLocal,YPCVal))
% Increase tolerance because some values may be close to zero
assert(uq_iscloseall(YPCVarLocal, YPCVar, 'ATol', 1e-6))
assert(uq_iscloseall(YPCValBootstrapLocal,YPCValBootstrap))

%% Non-synchronized test

% Make sure the dispatched computation is not synchronized
DispatcherObj.ExecMode = 'async';

% Test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation
[~,~,~] = uq_evalModel(myPCE, Xval, 'HPC');

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results
[YPCVal,YPCVar,YPCValBootstrap] = uq_fetchResults(DispatcherObj);

% Assert the equality of all outputs
assert(uq_iscloseall(YPCValLocal,YPCVal))
% Increase tolerance because some values may be close to zero
assert(uq_iscloseall(YPCVarLocal, YPCVar, 'ATol', 1e-6))
assert(uq_iscloseall(YPCValBootstrapLocal,YPCValBootstrap))

% Test with multiple remote processes
DispatcherObj.NumProcs = 3;

% Dispatch the computation
[~,~,~] = uq_evalModel(myPCE, Xval, 'HPC');

% Wait for the Job to finish:
uq_waitForJob(DispatcherObj)

% Fetch the results
[YPCVal,YPCVar,YPCValBootstrap] = uq_fetchResults(DispatcherObj);

% Assert the equality of all outputs
assert(uq_iscloseall(YPCValLocal,YPCVal))
% Increase tolerance because some values may be close to zero
assert(uq_iscloseall(YPCVarLocal, YPCVar, 'ATol', 1e-6))
assert(uq_iscloseall(YPCValBootstrapLocal,YPCValBootstrap))

%% Revert any changes made on the Dispatcher object
DispatcherObj.Internal.Display = displayOpt;
DispatcherObj.ExecMode = execMode;
DispatcherObj.NumProcs = numProcs;

%% Return the results
fprintf('PASS\n')

pass = true;

end
