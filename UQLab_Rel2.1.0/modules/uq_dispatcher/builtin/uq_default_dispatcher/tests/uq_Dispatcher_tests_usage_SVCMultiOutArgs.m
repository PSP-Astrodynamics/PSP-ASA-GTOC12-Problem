function pass = uq_Dispatcher_tests_usage_SVCMultiOutArgs(DispatcherObj)
%UQ_DISPATCHER_TESTS_USAGE_PCEMULTIOUTARGS tests a dispatched computation
%   of an SVC model having multiple output arguments (the class prediction
%   and the continuous prediction).
%
%   NOTE:
%   - 'uq_iscloseall' is used to test equalities because the remote MATLAB
%     version may differ and this causes a very small different between
%     the computed numbers.

%% Initialize the test
fprintf('Testing: | %s | %s...', DispatcherObj.Name, mfilename)

rng(100,'twister')  % Set random number for reproducibility

% Save current Dispatcher object settings
displayOpt = DispatcherObj.Internal.Display;
execMode = DispatcherObj.ExecMode;
numProcs = DispatcherObj.NumProcs;

% Make sure that the display option is quiet
DispatcherObj.Internal.Display = 0;

%% Retrieve data set

% The Fisher's iris data set is stored in a MAT-file
% in the following location:
FILELOCATION = fullfile(...
    uq_rootPath, 'Examples', 'SimpleDataSets', 'Fisher_Iris');

%%
% Read the data set and store the contents in matrices:
load(fullfile(FILELOCATION,'fisher_iris_reduced.mat'), 'X', 'Y')

%% SVC metamodel

% Select the metamodeling tool and the SVC module:
SVCOpts.Type = 'Metamodel';
SVCOpts.MetaType = 'SVC';
SVCOpts.Display = 'quiet';

% Assign the experimental design to the metamodel specification
SVCOpts.ExpDesign.X = X;
SVCOpts.ExpDesign.Y = Y;

% Select a linear penalization
SVCOpts.Penalization = 'linear';

% Use the span leave-one-out (LOO) error estimate
% to calibrate the kernel hyperparameters
SVCOpts.EstimMethod = 'SpanLOO';

% Use the cross-entropy method for the optimization
SVCOpts.Optim.Method = 'CE';

% Create the Sequential PC-Kriging metamodel
mySVC = uq_createModel(SVCOpts,'-private');

%% Validation data set

% Evaluate the true model responses for the validation set
[YClsLocal,YSVCLocal] = uq_evalModel(mySVC,X);

%% Synchronized dispatched computation (single process)

% Make sure the dispatched computation is synchronized
DispatcherObj.ExecMode = 'sync';

% Test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation
[YCls,YSVC] = uq_evalModel(mySVC, X, 'HPC');

% Assert the equality of all outputs
assert(uq_iscloseall(YClsLocal,YCls))
assert(uq_iscloseall(YSVCLocal,YSVC))

%% Synchronized dispatched computation (multiple processes)

% Test with multiple remote processes
DispatcherObj.NumProcs = 3;

% Dispatch the computation
warning('off')  % Supress expected warning
[YCls,YSVC] = uq_evalModel(mySVC, X, 'HPC');
warning('on')

% Assert the equality of all outputs
assert(uq_iscloseall(YClsLocal,YCls))
assert(uq_iscloseall(YSVCLocal,YSVC))

%% Non-synchronized dispatched computation (single process)

% Make sure the dispatched computation is not synchronized
DispatcherObj.ExecMode = 'async';

% Test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation
[~,~] = uq_evalModel(mySVC, X, 'HPC');

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results
[YCls,YSVC] = uq_fetchResults(DispatcherObj);

% Assert the equality of all outputs
assert(uq_iscloseall(YClsLocal,YCls))
assert(uq_iscloseall(YSVCLocal,YSVC))

%% Non-synchronized dispatched computation (multiple process)

% Test with multiple remote processes
DispatcherObj.NumProcs = 3;

% Dispatch the computation
[~,~] = uq_evalModel(mySVC, X, 'HPC');

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results
[YCls,YSVC] = uq_fetchResults(DispatcherObj);

% Assert the equality of all outputs
assert(uq_iscloseall(YClsLocal,YCls))
assert(uq_iscloseall(YSVCLocal,YSVC))

%% Revert any changes made on the Dispatcher object
DispatcherObj.Internal.Display = displayOpt;
DispatcherObj.ExecMode = execMode;
DispatcherObj.NumProcs = numProcs;

%% Return the results
fprintf('PASS\n')

pass = true;

end
