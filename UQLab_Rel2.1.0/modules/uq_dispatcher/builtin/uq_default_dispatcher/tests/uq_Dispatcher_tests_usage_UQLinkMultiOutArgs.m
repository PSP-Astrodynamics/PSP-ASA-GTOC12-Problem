function pass = uq_Dispatcher_tests_usage_UQLinkMultiOutArgs(DispatcherObj)
%UQ_DISPATCHER_TESTS_USAGE_UQLINKMULTIOUTARGS tests a dispatched
%   computation of a UQLink model having multiple output arguments.
%
%   NOTE:
%   - This tests uses a function named 'uq_modelMultiOutArgs' which has a
%     multiple output arguments.
%   - 'uq_iscloseall' is used to test equalities because the Python
%     calculation may be slightly different with the MATLAB ones due to the
%     representation of floating point numbers.

%% Initialize the test
fprintf('Testing: | %s | %s...', DispatcherObj.Name, mfilename)

rng(100,'twister')  % Set random number for reproducibility

% Save the current Dispatcher object settings
displayOpt = DispatcherObj.Internal.Display;
execMode = DispatcherObj.ExecMode;
numProcs = DispatcherObj.NumProcs;

% Make sure the display option is quiet
DispatcherObj.Internal.Display = 0;

%% Computational model

% Select the model type corresponding to UQLink
ModelOpts.Type = 'UQLink';
ModelOpts.Name = 'Ishigami';

% Provide the name of the 3rd-party code executable
EXECNAME = 'uq_ishigami_multioutputs.py';

% Provide the name of the input file:
INPUTFILE = 'myInput.csv';
OUTPUTFILE = 'myOutput.csv';

% Create the command string to execute the 3rd-party executable
COMMANDLINE = sprintf('%s %s %s', EXECNAME, INPUTFILE, OUTPUTFILE);

% Set the command string to the UQLink MODEL options
ModelOpts.Command = COMMANDLINE;

% Specify the template file, i.e., a copy of the original input files
% where the inputs of interest are replaced by markers
ModelOpts.Template = 'myInput.csv.tpl';

% Specify the location of this template file in the local machine.
ModelOpts.TemplatePath = fullfile(...
    uq_rootPath, 'modules', 'uq_dispatcher',...
    'builtin', 'uq_default_dispatcher', 'tests', 'support_files');

% Provide the MATLAB function that is used to retrieve the quantity of
% interest from the code output file
ModelOpts.Output.Parser = 'uq_read_ishigami_multioutputs';

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

% Get command to send remote command
sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);

% Create remote folder
uq_Dispatcher_util_mkDir(REMOTEEXECPATH, 'SSHConnect', sshConnect);

% Send the executable to the remote folder
sessionName = uq_Dispatcher_helper_getSessionName(DispatcherObj);

fileToCopy = fullfile(...
    uq_rootPath, 'modules', 'uq_dispatcher',...
    'builtin', 'uq_default_dispatcher', 'tests', 'support_files',...
    'uq_ishigami_multioutputs.py');
copyProgram  = DispatcherObj.Internal.SSHClient.SecureCopy;
sshClientLocation = DispatcherObj.Internal.SSHClient.Location;
if ~isempty(sshClientLocation)
    copyProgram = fullfile(sshClientLocation,copyProgram);
end
    
copyArgs = DispatcherObj.Internal.SSHClient.SecureCopyArgs;
privateKey = DispatcherObj.Internal.RemoteConfig.PrivateKey;
    
uq_Dispatcher_util_copy(...
    fileToCopy, REMOTEEXECPATH,...
    'Mode', 'Local2Remote',...
    'SessionName', sessionName,...
    'RemoteSep', DispatcherObj.Internal.RemoteSep,...
    'CopyProgram', copyProgram,...
    'AdditionalArguments', copyArgs,...
    'PrivateKey', privateKey);
    
% Change the execution right
execFileName = [REMOTEEXECPATH,'/',EXECNAME];
uq_Dispatcher_util_chmod(execFileName, 'u+x', 'SSHConnect', sshConnect);

% Update the newline character
uq_Dispatcher_util_runCLICommand(...
    'sed', {'-i.bak', '''s/\r$//''', execFileName}, sshConnect);

%% Synchronized dispatched computation (single process)

% Make sure the dispatched computation is synchronized
DispatcherObj.ExecMode = 'sync';

% Test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation
[Y1,Y2,Y3,YAll] = uq_evalModel(myModel, X, 'HPC');

% Assert the equality of all outputs
assert(uq_iscloseall(YLocal, [Y1,Y2,Y3], 'ATol', 1e-3))
assert(uq_iscloseall(YLocal, YAll, 'ATol', 1e-3))

%% Synchronized dispatched computation (multiple processes)

% Test with multiple remote processes
DispatcherObj.NumProcs = 3;

% Dispatch the computation
[Y1,Y2,Y3,YAll] = uq_evalModel(myModel, X, 'HPC');

% Assert the equality of all outputs
assert(uq_iscloseall(YLocal, [Y1,Y2,Y3], 'ATol', 1e-3))
assert(uq_iscloseall(YLocal, YAll, 'ATol', 1e-3))

%% Non-synchronized dispatched computation (single process)

% Make sure the dispatched computation is not synchronized
DispatcherObj.ExecMode = 'async';

% Test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation
[~,~,~,~] = uq_evalModel(myModel, X, 'HPC');

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results
[Y1,Y2,Y3,YAll] = uq_fetchResults(DispatcherObj);

% Assert the equality of all outputs
assert(uq_iscloseall(YLocal, [Y1,Y2,Y3], 'ATol', 1e-3))
assert(uq_iscloseall(YLocal, YAll, 'ATol', 1e-3))

%% Non-synchronized dispatched computation (multiple process)

% Test with multiple remote processes
DispatcherObj.NumProcs = 3;

% Dispatch the computation
[~,~,~,~] = uq_evalModel(myModel, X, 'HPC');

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results (only two results are available)
[Y1,Y2,Y3,YAll] = uq_fetchResults(DispatcherObj);

% Assert the equality of all outputs
assert(uq_iscloseall(YLocal, [Y1,Y2,Y3], 'ATol', 1e-3))
assert(uq_iscloseall(YLocal, YAll, 'ATol', 1e-3))

%% Synchronized dispatched computation (single process) - NO MATLAB/UQLab

% Turn off the requirement of remote MATLAB
myModel.Internal.RemoteMATLAB = false;

% Make sure the dispatched computation is synchronized
DispatcherObj.ExecMode = 'sync';

% Test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation
[Y1,Y2,Y3,YAll] = uq_evalModel(myModel, X, 'HPC');

% Assert the equality of all outputs
assert(uq_iscloseall(YLocal, [Y1,Y2,Y3], 'ATol', 1e-3))
assert(uq_iscloseall(YLocal, YAll, 'ATol', 1e-3))

%% Synchronized dispatched computation (multiple processes) - NO MATLAB/UQLab

% Test with multiple remote processes
DispatcherObj.NumProcs = 3;

% Dispatch the computation
[Y1,Y2,Y3,YAll] = uq_evalModel(myModel, X, 'HPC');

% Assert the equality of all outputs
assert(uq_iscloseall(YLocal, [Y1,Y2,Y3], 'ATol', 1e-3))
assert(uq_iscloseall(YLocal, YAll, 'ATol', 1e-3))

%% Non-synchronized dispatched computation (single process) - NO MATLAB/UQLab

% Make sure the dispatched computation is not synchronized
DispatcherObj.ExecMode = 'async';

% Test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation
[~,~,~,~] = uq_evalModel(myModel, X, 'HPC');

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results
[Y1,Y2,Y3,YAll] = uq_fetchResults(DispatcherObj);

% Assert the equality of all outputs
assert(uq_iscloseall(YLocal, [Y1,Y2,Y3], 'ATol', 1e-3))
assert(uq_iscloseall(YLocal, YAll, 'ATol', 1e-3))

%% Non-synchronized dispatched computation (multiple process) - NO MATLAB/UQLab

% Test with multiple remote processes
DispatcherObj.NumProcs = 3;

% Dispatch the computation
[~,~,~,~] = uq_evalModel(myModel, X, 'HPC');

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results (only two results are available)
[Y1,Y2,Y3,YAll] = uq_fetchResults(DispatcherObj);

% Assert the equality of all outputs
assert(uq_iscloseall(YLocal, [Y1,Y2,Y3], 'ATol', 1e-3))
assert(uq_iscloseall(YLocal, YAll, 'ATol', 1e-3))

%% Revert any changes made on the Dispatcher object
DispatcherObj.Internal.Display = displayOpt;
DispatcherObj.ExecMode = execMode;
DispatcherObj.NumProcs = numProcs;

%% Clean up remote environment
uq_Dispatcher_util_runCLICommand('rm', {'-rf', REMOTEEXECPATH}, sshConnect);

%% Return the results
fprintf('PASS\n')

pass = true;

end
