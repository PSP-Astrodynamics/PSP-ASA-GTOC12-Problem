function pass = uq_Dispatcher_tests_usage_UQLinkBasicWithoutMATLAB(DispatcherObj)
%UQ_DISPATCHER_TESTS_USAGE_UQLINKBASICWITHMATLAB tests a dispatched
%   computation of a UQLink model with all the basic settings
%   without MATLAB/UQLab available on the remote machine.
%
%   NOTE:
%   - This tests uses the test function 'uq_SimplySupportedBeam' and the
%     corresponding C-implementation 'myBeam_linux'; both are part of UQLab
%     shipment package.
%   - 'uq_iscloseall' is used to test equalities because the results
%     between the MATLAB function and its C-implementation are expected to
%     be slightly different due to the representation of floating point
%     numbers.

%% Initialize the test
fprintf('Testing: | %s | %s...', DispatcherObj.Name, mfilename)

rng(100,'twister')  % Set random number for reproducibility

% Save current Dispatcher object settings
displayOpt = DispatcherObj.Internal.Display;
execMode = DispatcherObj.ExecMode;
numProcs = DispatcherObj.NumProcs;

% Make sure the display option is quiet
DispatcherObj.Internal.Display = 0;

%% Computational model

% Select the model type corresponding to UQLink
ModelOpts.Type = 'UQLink';
ModelOpts.Name = 'SimplySupportedBeam';

% Provide the name of the 3rd-party code executable
EXECNAME = 'myBeam_linux';

% Provide the name of the input file
INPUTFILE = 'SSBeam_Deflection.inp';

% Create the command string to execute the 3rd-party executable
COMMANDLINE = sprintf('%s %s', EXECNAME, INPUTFILE);

% Set the command string to the UQLink MODEL options
ModelOpts.Command = COMMANDLINE;

% Provide the template file, i.e., a copy of the original input files
% where the inputs of interest are replaced by markers
ModelOpts.Template = 'SSBeam_Deflection.inp.tpl';

% Provide the location of this template file in the local machine
ModelOpts.TemplatePath = fullfile(...
    uq_rootPath, 'Examples', 'UQLink', 'C_SimplySupportedBeam');

% Provide the MATLAB function that is used to retrieve the quantity of
% interest from the code output file
ModelOpts.Output.Parser = 'uq_read_SSBeamDeflection';

% Set output filename of the code execution
ModelOpts.Output.FileName = 'SSBeam_Deflection.out';

% Set the executable path (*note*: the executable is located on the
% remote machine)
REMOTEEXECPATH = [DispatcherObj.Internal.RemoteConfig.RemoteUQLabPath,...
    '/Examples/UQLink/C_SimplySupportedBeam'];
ModelOpts.ExecutablePath = REMOTEEXECPATH;

% Make sure the UQLink dispatched computation uses remote MATLAB
ModelOpts.RemoteMATLAB = false;

%%
% Create a MODEL object in UQLab:
myModel = uq_createModel(ModelOpts,'-private');

%% Probabilistic input model

% Define the corresponding marginals:
InputOpts.Marginals(1).Name = 'b'; % beam width
InputOpts.Marginals(1).Type = 'Lognormal';
InputOpts.Marginals(1).Moments = [0.15 0.0075]; % (m)

InputOpts.Marginals(2).Name = 'h'; % beam height
InputOpts.Marginals(2).Type = 'Lognormal';
InputOpts.Marginals(2).Moments = [0.3 0.015]; % (m)

InputOpts.Marginals(3).Name = 'L'; % beam length
InputOpts.Marginals(3).Type = 'Lognormal';
InputOpts.Marginals(3).Moments = [5 0.05]; % (m)

InputOpts.Marginals(4).Name = 'E'; % Young's modulus
InputOpts.Marginals(4).Type = 'Lognormal';
InputOpts.Marginals(4).Moments = [3e10 4.5e9]; % (Pa)

InputOpts.Marginals(5).Name = 'p'; % uniform load
InputOpts.Marginals(5).Type = 'Lognormal';
InputOpts.Marginals(5).Moments = [1e4 2e3]; % (N/m)

% Create an INPUT object:
myInput = uq_createInput(InputOpts,'-private');

%% Validation data set

% Create a validation set
X = uq_getSample(myInput,2e1);

% Evaluate the model locally
YLocal = uq_SimplySupportedBeam(X);

%% Synchronized dispatched computation (single process)

% Make sure the dispatched computation is synchronized
DispatcherObj.ExecMode = 'sync';

% Test with a single remote process
DispatcherObj.NumProcs = 1;

% Dispatch the computation
Y = uq_evalModel(myModel, X, 'HPC');

% Assert the equality of all outputs
assert(uq_iscloseall(YLocal, Y, 'ATol', 1e-6))

%% Synchronized dispatched computation (multiple processes)

% Test with multiple remote processes
DispatcherObj.NumProcs = 3;

% Dispatch the computation
Y = uq_evalModel(myModel, X, 'HPC');

% Assert the equality of all outputs
assert(uq_iscloseall(YLocal, Y, 'ATol', 1e-6))

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
assert(uq_iscloseall(YLocal, Y, 'ATol', 1e-6))

%% Non-synchronized dispatched computation (multiple processes)

% Test with multiple remote processes
DispatcherObj.NumProcs = 3;

% Dispatch the computation
[~] = uq_evalModel(myModel, X, 'HPC');

% Wait for the Job to finish
uq_waitForJob(DispatcherObj)

% Fetch the results (only two results are available)
Y = uq_fetchResults(DispatcherObj);

% Assert the equality of all outputs
assert(uq_iscloseall(YLocal, Y, 'ATol', 1e-6))

%% Revert any changes made on the Dispatcher object
DispatcherObj.Internal.Display = displayOpt;
DispatcherObj.ExecMode = execMode;
DispatcherObj.NumProcs = numProcs;

%% Return the results
fprintf('PASS\n')

pass = true;

end
