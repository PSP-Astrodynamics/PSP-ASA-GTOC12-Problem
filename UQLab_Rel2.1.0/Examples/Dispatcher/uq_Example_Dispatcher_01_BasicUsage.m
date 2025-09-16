%% HPC DISPATCHER: BASIC USAGE
%
% This example showcases the application of the HPC DISPATCHER module to
% dispatch a UQLab MODEL evaluation to a remote machine along with
% the basic features of the DISPATCHER module.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, fix the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL

%%
% The computational model is a simple analytical function defined by:
% $$
% Y = x \sin(x), \; x \in [0, 15]
% $$
%
% In UQLab, the model can be specified directly as a string, written below
% in a vectorized format:
ModelOpts.mString = 'X.*sin(X)';
ModelOpts.isVectorized = true;

myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of a single uniform random
% variable:
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

%% 4 - DISPATCHER CONFIGURATION
%
% A DISPATCHER object is specified, at the minimum, by a remote machine
% profile file. This remote machine profile file contains, among other
% things, the authentication to a remote machine and the setup of the
% computing environment of the machine.
% 
% The file is stored as a MATLAB script and can be located anywhere in the
% MATLAB search path.
% In the folder |$UQLABROOT/Profiles/HPC|, a basic template file
% |profile_file_template_basic.m| can be used as a starting point.
% Refer to Appendix B of the HPC Dispatcher Module User Manual for details
% on how to set up a remote machine profile.
%
% The DISPATCHER object communicates with the remote machine using
% the encrypted SSH (secure shell) protocol. A key-based authentication for
% the SSH connection to the remote machine must first be set up by
% creating an SSH key-pair.
% Refer to Appendix A of the HPC Dispatcher Module User Manual for details
% on how to set up a key-based authentication.
%
% In the following, it is assumed that users have successfully created the
% key pair and set up their local machine to allow for an SSH connection to
% the remote machine using a key-based authentication.

%%
% Assume the profile is saved in a file |myRemoteProfile.m| available in
% the MATLAB search path.
DispatcherOpts.Profile = 'myRemoteProfile';

%%
% Create a DISPATCHER object:
myDispatcher = uq_createDispatcher(DispatcherOpts);

%%
% A report on the DISPATCHER object can be printed on screen using the
% |uq_print| command:
uq_print(myDispatcher)

%%
% Details regarding dispatched computations are stored in Jobs. Notice 
% that at this stage, no jobs have been submitted yet.

%% 5 - DISPATCHED MODEL EVALUATION USING A DISPATCHER OBJECT
%
% Using the DISPATCHER object created above, a UQLab model evaluation can 
% be dispatched to the remote machine.

%%
% Create a small set of test sample points:
X = uq_getSample(10);

%%
% Dispatch the MODEL evaluation to the remote machine using the 'HPC' flag
% as follows:
Ydispatched = uq_evalModel(X,'HPC')

%%
% Notice that except for the message printed out on the MATLAB command
% windows regarding the status of the remote execution, there is no
% difference between the usual local computation and the dispatched
% computation.

%%
% *Note*: This displayed message can be suppressed by setting the
% DISPATCHER object display option to 'quiet'.

%%
% To verify the results of the dispatched computation, evaluate the same
% MODEL on the local machine:
Ylocal = uq_evalModel(X)

%% 
% Verify that the two results are the same: 
AreTheResultsIdentical = isequal(Ydispatched,Ylocal)
