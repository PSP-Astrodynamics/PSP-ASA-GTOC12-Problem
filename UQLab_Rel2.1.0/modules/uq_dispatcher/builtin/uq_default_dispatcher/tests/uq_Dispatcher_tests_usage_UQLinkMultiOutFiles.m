function pass = uq_Dispatcher_tests_usage_UQLinkMultiOutFiles(DispatcherObj)
%UQ_DISPATCHER_TESTS_USAGE_UQLINKMULTIOUTFILES tests a dispatched
%   computation of a UQLink model with the command line interface of
%   the third-party code having multiple output files.
%
%   The 3rd-party command line interface is of the form:
%
%       <executable> <inputfile> <outputfile 1> <outputfile 2> <outputfile 3>
%
%   NOTE:
%   - This tests uses a Python3 implementation of the Ishigami function
%     named 'uq_ishigami_multioutfiles.py'; it requires numpy.
%   - The UQLink output parser is 'uq_read_ishigami_multioutfiles.m'
%   - 'uq_iscloseall' is used to test equalities because the results
%     between the MATLAB function and its python implementation are
%     expected to be slightly different due to the representation of 
%     floating point numbers.

%% Initialize the test
fprintf('Testing: | %s | %s...', DispatcherObj.Name, mfilename)

rng(100,'twister')  % Set random number for reproducibility

% Save current Dispatcher object settings
displayOpt = DispatcherObj.Internal.Display;
execMode = DispatcherObj.ExecMode;
numProcs = DispatcherObj.NumProcs;

% Make sure the display option is quiet
DispatcherObj.Internal.Display = 0;

% Support files location
supportLoc = fullfile(...
    uq_rootPath, 'modules', 'uq_dispatcher',...
    'builtin', 'uq_default_dispatcher', 'tests', 'support_files');

%% Computational model

% Select the model type corresponding to UQLink
ModelOpts.Type = 'UQLink';
ModelOpts.Name = 'Ishigami';

% Provide the name of the 3rd-party code executable
EXECNAME = 'uq_ishigami_multioutfiles.py';

% Provide the name of the input file
INPUTFILE  = 'myInput.csv';
OUTPUTFILE = {'myOutput1.csv', 'myOutput2.csv', 'myOutput3.csv'};

% Create the command string to execute the 3rd-party executable
COMMANDLINE = sprintf('%s %s %s %s %s %s', EXECNAME, INPUTFILE,...
    OUTPUTFILE{:});

% Set the command string to the UQLink MODEL options
ModelOpts.Command = COMMANDLINE;

% Specify the template file
ModelOpts.Template = 'myInput.csv.tpl';

% Specify the location of this template file in the local machine
ModelOpts.TemplatePath = supportLoc;

% Provide the MATLAB function that is used to retrieve the quantity of
% interest from the code output file
ModelOpts.Output.Parser = 'uq_read_ishigami_multioutfiles';

% Set output filename of the code execution
ModelOpts.Output.FileName = OUTPUTFILE;

% Set the executable path (*note*: the executable is located on the
% remote machine)
REMOTEEXECPATH = [DispatcherObj.Internal.RemoteConfig.RemoteFolder,...
    '/', uq_createUniqueID];
ModelOpts.ExecutablePath = REMOTEEXECPATH;

% Create a MODEL object
myModel = uq_createModel(ModelOpts,'-private');

%% Probabilistic input model

% Specify the probabilistic model of the input variable
for ii = 1:3
    InputOpts.Marginals(ii).Type = 'Uniform';
    InputOpts.Marginals(ii).Parameters = [-pi pi]; 
end

% Create an INPUT object based on the specified marginals
myInput = uq_createInput(InputOpts,'-private');

%% Validation data set

% Create a validation set
X = uq_getSample(myInput,2e1);

% Evaluate the model locally
YLocal = uq_ishigami_various_outputs(X);

%% Set up remote environment
execFile = fullfile(...
    uq_rootPath, 'modules', 'uq_dispatcher',...
    'builtin', 'uq_default_dispatcher', 'tests', 'support_files',...
    EXECNAME);
uq_Dispatcher_tests_support_setupUQLinkRemoteEnv(...
    DispatcherObj, execFile, REMOTEEXECPATH);

%% Synchronized dispatched computation (single process)

% Make sure the dispatched computation uses remote MATLAB/UQLab
myModel.Internal.RemoteMATLAB = true;

% Make sure the dispatched computation is synchronized
DispatcherObj.ExecMode = 'sync';

% Test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation
Y = uq_evalModel(myModel, X, 'HPC');

% Assert the equality of all outputs
try
    assert(uq_iscloseall(YLocal, Y, 'ATol', 1e-3))
catch e
    cleanRemote(REMOTEEXECPATH,DispatcherObj)
    rethrow(e)
end

%% Synchronized dispatched computation (multiple processes)

% Test with multiple remote processes
DispatcherObj.NumProcs = 3;

% Dispatch the computation
Y = uq_evalModel(myModel, X, 'HPC');

% Assert the equality of all outputs
try
    assert(uq_iscloseall(YLocal, Y, 'ATol', 1e-3))
catch e
    cleanRemote(REMOTEEXECPATH,DispatcherObj)
    rethrow(e)
end

%% Non-synchronized dispatched computation (single process)

% Make sure the dispatched computation is not synchronized
DispatcherObj.ExecMode = 'async';

% Test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation
[~] = uq_evalModel(myModel, X, 'HPC');

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results
Y = uq_fetchResults(DispatcherObj);

% Assert the equality of all outputs
try
    assert(uq_iscloseall(YLocal, Y, 'ATol', 1e-3))
catch e
    cleanRemote(REMOTEEXECPATH,DispatcherObj)
    rethrow(e)
end

%% Non-synchronized dispatched computation (multiple process)

% Test with multiple remote processes
DispatcherObj.NumProcs = 3;

% Dispatch the computation
[~] = uq_evalModel(myModel, X, 'HPC');

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results (only two results are available)
Y = uq_fetchResults(DispatcherObj);

% Assert the equality of all outputs
try
    assert(uq_iscloseall(YLocal, Y, 'ATol', 1e-3))
catch e
    cleanRemote(REMOTEEXECPATH,DispatcherObj)
    rethrow(e)
end

%% Synchronized dispatched computation (single process) - No MATLAB/UQLab

% Turn off the requirement of remote MATLAB
myModel.Internal.RemoteMATLAB = false;

% Make sure the dispatched computation is synchronized
DispatcherObj.ExecMode = 'sync';

% Test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation
Y = uq_evalModel(myModel, X, 'HPC');

% Assert the equality of all outputs
try
    assert(uq_iscloseall(YLocal, Y, 'ATol', 1e-3))
catch e
    cleanRemote(REMOTEEXECPATH,DispatcherObj)
    rethrow(e)
end

%% Synchronized dispatched computation (multiple processes) - No MATLAB/UQLab

% Test with multiple remote processes
DispatcherObj.NumProcs = 3;

% Dispatch the computation
Y = uq_evalModel(myModel, X, 'HPC');

% Assert the equality of all outputs
try
    assert(uq_iscloseall(YLocal, Y, 'ATol', 1e-3))
catch e
    cleanRemote(REMOTEEXECPATH,DispatcherObj)
    rethrow(e)
end

%% Non-synchronized dispatched computation (single process) - No MATLAB/UQLab

% Make sure the dispatched computation is not synchronized
DispatcherObj.ExecMode = 'async';

% Test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation
[~] = uq_evalModel(myModel, X, 'HPC');

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results
Y = uq_fetchResults(DispatcherObj);

% Assert the equality of all outputs
try
    assert(uq_iscloseall(YLocal, Y, 'ATol', 1e-3))
catch e
    cleanRemote(REMOTEEXECPATH,DispatcherObj)
    rethrow(e)
end

%% Non-synchronized dispatched computation (multiple process) - No MATLAB/UQLab

% Test with multiple remote processes
DispatcherObj.NumProcs = 3;

% Dispatch the computation
[~] = uq_evalModel(myModel, X, 'HPC');

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results (only two results are available)
Y = uq_fetchResults(DispatcherObj);

% Assert the equality of all outputs
try
    assert(uq_iscloseall(YLocal, Y, 'ATol', 1e-3))
catch e
    cleanRemote(REMOTEEXECPATH,DispatcherObj)
    rethrow(e)
end

%% Revert any changes made on the Dispatcher object
DispatcherObj.Internal.Display = displayOpt;
DispatcherObj.ExecMode = execMode;
DispatcherObj.NumProcs = numProcs;

%% Clean up remote environment
cleanRemote(REMOTEEXECPATH,DispatcherObj)

%% Return the results
fprintf('PASS\n')

pass = true;

end


%% ------------------------------------------------------------------------
function cleanRemote(remoteDir,DispatcherObj)

sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);
uq_Dispatcher_util_runCLICommand('rm', {'-rf', remoteDir}, sshConnect);

end
