%% HPC DISPATCHER: USING UQ_MAP TO DISPATCH GENERIC FUNCTIONS AND OPERATIONS
%
% This example showcases how the DISPATCHER module can be used to dispatch
% a generic function evaluation to a remote machine using the
% dispatcher-aware command |uq_map|.
% Built-in MATLAB functions, user-defined functions, and UQLab
% functionalities are supported.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator,
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - |UQ_MAP|
%
% The dispatcher-aware command |uq_map| is used to dispatch a generic
% function evaluation to a remote machine.
% |uq_map| itself is a generic function that works with or without a
% DISPATCHER object.
%
% In essence, |uq_map| evaluates a specific function on each element of a
% given input sequence.
% The basic use of |uq_map| is as follows:

%%
%  uq_map(func,inputs)

%%
% Where:
% 
% * |func| is a Matlab function handle that needs to be evaluated on
%   multiple inputs. MATLAB, user-defined, or UQLab functions are
%   supported.
% * |inputs| is a sequence of inputs to the function |func|. This can be a
%   cell array, a struct array, or numerical matrices.

%%
% For instance, |uq_map| can be used to evaluate the mean of each element
% of a cell array that contains sets of random values of different sizes as
% follows: 
uq_map(@mean, {randn(100,1), randn(1000,1), randn(1000,1)})

%%
% The output of |uq_map| is a cell array with the same number of elements
% as the input sequence.

%%
% If used without a DISPATCHER object as the above example, the function
% evaluations are carried out on the local machine.
% However, if used with a DISPATCHER object, the evaluations are carried
% out on the remote machine.
% An existing DISPATCHER object can be used to dispatch a |uq_map|
% computation by using the following command:

%%
%  uq_map(func, inputs, DispatcherObj)
%
% Where |DispatcherObj| is a DISPATCHER object. When dispatched, |uq_map|
% computations may also be executed in parallel.

%% 3 - DISPATCHER OBJECT
%
% In the following example, it is assumed that an encrypted
% key-exchange-based SSH connection to the remote machine can be
% established, and that a remote machine profile file has been set up.
% Refer to Appendix A and B for instructions on how to set up the
% passwordless SSH connection and the remote machine profile file,
% respectively.

%%
% It is assumed that a remote machine profile file named
% |myRemoteProfile.m| has been set up properly and is available in
% the MATLAB search path.
%
% Specify the name of the profile file:
DispatcherOpts.Profile = 'myRemoteProfile';

%%
% To execute a dispatched computation in parallel on the remote machine,
% set the desired number of parallel processes:
DispatcherOpts.NumProcs = 4;

%%
% Then create a DISPATCHER object:
myDispatcher = uq_createDispatcher(DispatcherOpts);

%% 4 - DISPATCHING EVALUATIONS OF BUILT-IN MATLAB FUNCTIONS
%
% To illustrate the basic usage of dispatch-enabled |uq_map|, compute the
% sum of a cell array with six different elements on the remote machine as
% follows: 
inputs = {linspace(1,10); linspace(1,100); linspace(1,1000);...
    [0 2 3]; [1 2 3 4 5 6 7]; rand(10,3)};
uq_map(@sum, inputs, myDispatcher, 'ExecMode', 'async')

%%
% Notice that the function |sum| is a built-in MATLAB function.

%%
% By default, |uq_map| dispatches the computation and let the remote
% machine execute the computation asynchronously.
% Once the computation is successfully dispatched, control is given back to
% the user without waiting for the dispatched computation to finish.

%%
% A report on the current dispatched computation (i.e., _Job_) can be 
% printed as follows:
uq_print(myDispatcher)

%%
% To get the status of the current Job:
uq_getStatus(myDispatcher)

%%
% Wait for the Job to finish before continuing:
uq_waitForJob(myDispatcher)

%%
% Once finished, the computation results on the remote machine can be 
% fetched to the local UQLab session:
Y = uq_fetchResults(myDispatcher)

%%
% Functions that return multiple outputs may also be dispatched and fetched.
%
% The command below illustrates evaluating a function that returns multiple
% outputs on the remote machine:
inputs = {randi(100,1,10), randi(100,1,100), randi(100,1,1000)};
uq_map(@min, inputs, myDispatcher,...
    'NumOfOutArgs', 2,...
    'ExecMode', 'async')

%%
% The command finds the minimum of each element of the cell array. Notice
% that the built-in MATLAB function |min| may return two output arguments:
% the minimum value and the index of the minimum value.

%%
% Because the number of outputs of a function cannot be inferred from the
% function itself, the number of requested output arguments (named argument
% |'NumOfOutArgs'|) must be explicitly specified (the default is $1$, i.e.,
% only the first output is computed).

%%
% Wait for the Job to finish:
uq_waitForJob(myDispatcher)

%%
% The results of the function with multiple output arguments can be fetched
% as follows:
[Y1,Y2] = uq_fetchResults(myDispatcher)

%% 5 - DISPATCHING EVALUATIONS OF USER-DEFINED FUNCTIONS
%
% Evaluations of user-defined functions may also be dispatched to the
% remote machine using |uq_map| and a DISPATCHER object.

%%
% For instance, consider the following local function:
%
% <include>myFunction.m</include>

%%
% To evaluate this function using |uq_map| on set of inputs,
% use the following command:
X = [0 0 0; 0.5*pi 0.5*pi 0.5*pi; pi pi pi];
uq_map(@myFunction, X, myDispatcher,...
    'MatrixMapping', 'ByRows',...
    'ExecMode', 'async')

%%
% Note that |myFunction| is evaluated for each row of the input matrix |X|.
% This is done by using the named argument |'MatrixMapping'| with
% |'ByRows'| as the value.

%%
% Wait for the Job to finish:
uq_waitForJob(myDispatcher)

%%
% Fetch the results back to the local machine:
Y = uq_fetchResults(myDispatcher)

%%
% Parameters can be passed to |uq_map| if they are supported by the
% function. If specified, Parameters are always taken to be the last
% positional argument of the function.
% For example, to change the value of parameters in the dispatched
% evaluation of |myFunction|:
P.a = 8;
P.b = 0.5;
uq_map(@myFunction, X, myDispatcher,...
    'Parameters', P,...
    'MatrixMapping', 'ByRows',...
    'ExecMode', 'async')

%%
% Wait for the Job to finish:
uq_waitForJob(myDispatcher)

%%
% Fetch the results back to the local UQLab session:
Y = uq_fetchResults(myDispatcher)

%%
% By default, the user-defined function is automatically copied to the
% remote machine.
% However, if the user-defined function depends on other functions or
% external data files, they must be explicitly made available on the
% remote machine.
% There are two ways to deal with this requirement:
%
% # Copy all the required files to the remote machine manually and define
%   additional remote paths in the |DispatcherObj.AddToPath| and
%   |DispatcherObj.AddTreeToPath|. This is the recommended approach for
%   frequently use or a large body of files or large-sized data.
% # Specify the required files in the call to |uq_map| using named
%   arguments (|'AttachedFiles'|). The attached files will be copied
%   every time |uq_map| is called. This is the recommended approach for
%   relatively small-sized helper functions or data files.

%% 6 - DISPATCHING EVALUATIONS OF ANONYMOUS FUNCTIONS
%
% An anonymous function may be passed directly to |uq_map|. In case the
% anonymous function contains calls to user-defined functions, users are
% responsible for attaching the required files.

%%
% To illustrate this feature, define an anonymous function:
mse = @(X) sqrt(mean((X(:,1) - X(:,2)).^2)); 

%%
% Generate several illustrative data sets:
inputs = {...
    [randn(1e2,1),randn(1e2,1)];...
    [randn(1e3,1),randn(1e3,1)];...
    [randn(1e4,1),randn(1e4,1)]};

%%
% Dispatch the anonymous function evaluation to the remote machine:
uq_map(mse, inputs, myDispatcher, 'ExecMode', 'async')

%%
% Wait for the Job to finish:
uq_waitForJob(myDispatcher)

%%
% Fetch the results back to the local UQLab session:
Y = uq_fetchResults(myDispatcher)

%% 7 - DISPATCHING EVALUATIONS OF UQLAB FUNCTIONS
%
% To access UQLab functionalities on the remote machine, UQLab must be
% installed and available, and its location must be set properly in the
% remote machine profile file. 
%
% To use |uq_map| with a function that depends on UQLab, use:
%
%   uq_map(func, inputs, parameters, DispatcherObj,...
%       'UQLab', true)

%%
% As an example, the following command create three different UQLab MODEL
% objects from three different strings on the remote machine:
ModelOpts1.mString = '2*X';
ModelOpts2.mString = 'X+2';
ModelOpts3.mString = 'X+1';
inputs = {ModelOpts1;ModelOpts2;ModelOpts1};
uq_map(@uq_createModel, inputs, myDispatcher,...
    'UQLab', true,...
    'ExecMode', 'async')

%%
% Wait for the Job to finish:
uq_waitForJob(myDispatcher)

%%
% Fetching the results gives 3 MODEL objects:
myDispatchedModels = uq_fetchResults(myDispatcher)

%%
% The objects can be used as any MODEL objects.
% For instance, to evaluate the first MODEL on an input:
uq_evalModel(myDispatchedModels{1},10)

%% 8 - EVALUATIONS OF LINUX COMMANDS
%
% Linux commands may also be executed on the remote machines on a sequence
% of inputs. When dispatching a Linux command, neither MATLAB nor UQLab is
% required on the remote machine.
% 
% The following command computes the sum of two numbers on the remote
% machine:
inputs = {{1,2}; {3,4}; {5,6}; {8,7}};
uq_map('echo {1}+{2} | bc', inputs, myDispatcher, 'ExecMode', 'async')

%%
% Wait for the Job to finish:
uq_waitForJob(myDispatcher)

%%
% There is no function to fetch the results when dispatching 
% Linux commands as the outputs are, by default, produced in
% the standard output. 
% Therefore, fetching the results of the Job will yield an empty array:
Y = uq_fetchResults(myDispatcher)

%%
% However, the content of the output streams may be fetched instead:
outputStream = uq_fetchOutputStreams(myDispatcher)
