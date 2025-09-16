%% HPC DISPATCHER: ADVANCED USAGE
%
% This example showcases some of the advanced functionalities of the
% DISPATCHER module.
% The example is based on dispatched UQLab MODEL evaluations using
% |uq_evalModel| with a DISPATCHER object.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The computation model is a simple analytical function defined by:
%
% $$
% y = x \sin(x), \; x \in [0,15]
% $$

%%
% In UQLab, the model can be specified directly using a string, written
% below in a vectorized operation:
ModelOpts.mString = 'X.*sin(X)';
ModelOpts.isVectorized = true;

%%
% Create a MODEL object as follows:
myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of a single uniform random variable:
%
% $$
% X \sim \mathcal{U}(0, 15)
% $$

%%
% Specify the probabilistic model of the input variable:
InputOpts.Marginals.Type = 'Uniform';
InputOpts.Marginals.Parameters = [0 15];

%%
% Then create an INPUT object:
myInput = uq_createInput(InputOpts);

%% 4 - DISPATCHER OBJECT
%
% In the following, it is assumed that users have successfully created the
% key pair and set up their local machine to allow for a key-based
% authenticated SSH connection to the remote machine.
% Refer to Appendix A of the HPC Dispatcher Module User Manual for details.
%
% Furthermore, it is also assumed that a remote machine profile file has
% been set up properly; in this example, it is named |myRemoteProfile.m|
% and can be located anywhere in the MATLAB search path.
% Refer to Appendix A of the HPC Dispatcher Module User Manual for details.

%% 
% Assign the profile file to the DISPATCHER options:
DispatcherOpts.Profile = 'myRemoteProfile';

%%
% Increase the display level to show additional information when
% a DISPATCHER object is in use:
DispatcherOpts.Display = 'verbose';

%%
% Then create a DISPATCHER object:
myDispatcher = uq_createDispatcher(DispatcherOpts);

%%
% By default, when a DISPATCHER object is created, several verification
% steps are carried out to ensure that computations may be dispatched to
% the remote machine successfully. With the display level set to verbose
% these verification steps are shown.

%%
% A report on the DISPATCHER object can be produced using the |uq_print|
% command:
uq_print(myDispatcher)

%%
% The report shows some basic information regarding the DISPATCHER object
% setting as well as the remote machine profile. Once a computation has
% been dispatched to the remote machine, the report will also show
% additional information regarding the dispatched computation (also known
% as _Job_).

%% 5 - MODEL EVALUATION USING A DISPATCHER OBJECT
%
% Using the DISPATCHER object created above, a UQLab model evaluation can 
% be dispatched to and executed on the remote machine.

%%
% Create a small set of test sample points:
X = uq_getSample(15);

%% 5.1 Asynchronous dispatched computation
%
% By default, as shown in the basic usage example, a dispatched computation
% is executed in synchronized mode on the remote machine.
% To let the dispatched computation be executed asynchronously,
% set the following property of the DISPATCHER object:
myDispatcher.ExecMode = 'async';

%%
% When a dispatched computation is not synchronized with the local UQLab
% session, the execution is independent of the local session.
% Once the computation is successfully dispatched to the 
% remote machine, the control is immediately given back to the user 
% regardless of whether the remote machine has successfully finished 
% the computation or not.
%
% To dispatch the MODEL evaluation to the remote machine:
Ydispatched = uq_evalModel(X,'HPC')

%%
% To check the status of the dispatched computation:
uq_getStatus(myDispatcher)

%%
% There are six possible status:
%
% * |pending|: a Job associated with the dispatched computation has been
%   created on the remote machine, and it is ready for submission.
% * |submitted|: the Job has been submitted to the remote machine for
%   execution.
% * |running|: the Job is currently being executed on the remote machine.
% * |complete|: the Job execution has been successfully finished.
% * |failed|: the Job execution has exited with errors.
% * |canceled|: the Job has been canceled by the user.

%%
% To pause execution until the dispatched computation finishes, use the
% following command:
uq_waitForJob(myDispatcher)

%%
% Once finished, the computation results are stored in the remote machine
% and they must be explicitly retrieved (_fetched_) to the local session:
Ydispatched = uq_fetchResults(myDispatcher)

%% 5.2 Parallel execution
%
% Dispatched UQLab MODEL evaluations may be executed in parallel by setting
% the number of desired parallel processes. For instance, the following
% sets the number of processes to three:
myDispatcher.NumProcs = 3;

%%
% This setting means that three parallel processes will be created on the
% remote machine and each process will be responsible for evaluating one
% third of the model evaluations.

%%
% Set the execution mode back to the default 'synchronized' mode so that
% its results are automatically fetched to the local session:
myDispatcher.ExecMode = 'sync';

%%
% Evaluating the MODEL once more, this time in parallel:
YdispatchedPar = uq_evalModel(X,'HPC')

%%
% The parallelization of the MODEL evaluation is transparent. That is,
% there is no difference from the user perspective whether the evaluation
% is carried out with one or more processes.

%% 5.3 Multiple dispatched computations
%
% Due to the asynchronous nature of the remote execution, multiple
% computations may be dispatched one after the other without waiting for
% any of the previous dispatched computations to finish.
%
% To illustrate this, make sure that the DISPATCHER |ExecMode| is set to
% |async|:
myDispatcher.ExecMode = 'async';

%%
% Create several more additional samples of different sizes:
X1 = uq_getSample(5);
X2 = uq_getSample(5e1);

%%
% Create multiple new dispatched computations on these samples:
uq_evalModel(X1,'HPC');
uq_evalModel(X2,'HPC');

%%
% All the Jobs (i.e., dispatched computations) associated with a DISPATCHER
% object can be displayed using the command |uq_listJobs|:
uq_listJobs(myDispatcher)

%%
% The most recent Job is listed, by default, at the bottom.
% Notice that several Jobs have been created in the current UQLab session
% so far.
%
% Calling |uq_listJobs| does not automatically check and update the
% status of each associated Job so that an overview can be provided
% quickly.
% To update the Jobs status, call the same command with the following
% command:
%   uq_listJobs(myDispatcher, 'UpdateStatus', true)

%%
% When there are multiple jobs associated with the DISPATCHER object, 
% the report produced by calling the command |uq_print| on the object will
% show the summary of the last created Job:
uq_print(myDispatcher)

%%
% The summary of another Job can be shown by explicitly specifying the Job
% index (as shown in, for example, |uq_listJobs|). For instance, the
% summary of Job #2 can be printed as follows:
uq_print(myDispatcher,2)

%%
% Most user commands related to DISPATCHER object work similarly. 
% For example, using the command |uq_fetchResults|, the results of any 
% completed dispatched computations can be fetched by selecting the Job
% index. 
% For example, one can fetch the results of the first Job with:
Y3 = uq_fetchResults(myDispatcher,1)

%%
% By default, as with the |uq_print| command, |uq_fetchResults| fetches the
% results of the last created Job associated with the DISPATCHER object.

%% 5.4 Saving and loading a DISPATCHER object
%
% A DISPATCHER object can be saved using the command |uq_saveDispatcher| to
% a file:
uq_saveDispatcher('mySavedDispatcher');

%%
% At this point, the DISPATCHER object may be removed from the UQLab
% session, MATLAB closed, and the computer shut down.
%
% Clear all the current variables and restart UQLab:
clearvars
uqlab('-nosplash')

%%
% The DISPATCHER object can be loaded back to the current session as 
% follows:
myDispatcher = uq_loadDispatcher('mySavedDispatcher');

%%
% When a DISPATCHER object is retrieved, the results of any complete
% dispatched computations can be fetched back, as long as the directory
% structure on the remote machine is still intact.

%%
% List and update the status of all Jobs:
uq_listJobs(myDispatcher, 'UpdateStatus', true)

%%
% To fetch back the results of the fourth Job:
Y4 = uq_fetchResults(myDispatcher,4);

%%
% Create a histogram from these fetched results:
uq_histogram(Y4)
