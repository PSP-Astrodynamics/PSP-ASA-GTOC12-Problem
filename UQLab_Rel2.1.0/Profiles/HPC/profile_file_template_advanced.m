%% ADVANCED REMOTE MACHINE PROFILE FILE TEMPLATE
%
% The advanced template is identical to the basic template, with the 
% exception of the scheduler settings.
% This template contains the additional settings required to use a custom
% scheduler not supported by the DISPATCHER module out-of-the-box.
%
% Replace the value of each variable with the correct values of the actual
% remote machine; consult the machine documentation or system administrator
% to obtain these values.

%% Authentication
%
% This section contains the user's login information to the remote machine.
% For a passwordless SSH connection to the remote machine, an SSH key pair
% must be generated and the location of the private key file be specified
% below.
Hostname = 'my.host.name';
Username = 'myusername';
PrivateKey = '/path/to/myPrivateKey';

%%
% *Optional for Windows users*
%
% Instead of providing those three pieces of information, Windows users
% have the option to specify a PuTTY saved session.
% Make sure that the saved session is allowed to connect to the remote
% machine without prompting for a password.
% Refer to Appendix A of the DISPATCHER module user manual for detail.
%
% To use PuTTY saved session, comment the previous three lines and
% uncomment the line below and replace the value with the name of the saved
% session.
% SavedSession = 'mySavedSession';

%% Remote workspace
%
% The variable 'RemoteFolder' provides the location of a writeable
% directory on the remote machine to store the dispatched computations.
%
% Note the following restrictions on how the remote folder is specified:
%
% * The user must have a write-access to the specified remote folder
% * The remote folder must not contain any whitespaces.
% * The tilde (~) symbol as a shortcut to |$HOME| is not supported.
%   If it is used, the user must the full path to their |$HOME| folder.
%
% The DISPATCHER module will verify these restrictions and will throw an
% error if they are violated.
RemoteFolder = '/home/myusername/myDispatchedComputations';

%% Remote computing environment
%
% This section stores the variables used to set up the computing
% environment on the remote machine.

%% MATLAB
%
% The command that runs MATLAB (i.e., the executable) on the remote
% machine:
MATLABCommand = '';

%%
% If left empty, then MATLAB will not be available for dispatched
% computations. Without using MATLAB for dispatched computations,
% the user may still dispatch UQLink MODEL evaluations to the remote
% machine.

%% UQLab
%
% The location of UQLab on the remote machine:
RemoteUQLabPath = '';

%%
% If left empty, then UQLab will not be available for dispatched
% computations. Without using UQLab for dispatched computations, the user
% may still dispatch |uq_map| computations to the remote machine as long as
% they do not depend on UQLab functionalities.

%%
% *UQLab license file is required on the remote machine*
%
% The license file for UQLab is also required on the remote machine. This
% file must be stored in the |core| folder inside the remote UQLab path.

%% Remote environment
%
% |EnvSetup| and |PrevCommands| are used to specify the commands to be
% executed on the remote machine in order to set up the remote computing
% environment.
%
% In many HPC cluster organizations, an environment module
% system is employed and users must explicitly write the commands to load
% the required software to make them available on the remote machine
% (for example, MATLAB and MPI). If this is the case, then these commands
% must be specified here.

%%
% The commands to execute on the remote machine *before* the dispatched
% computation is submitted (for example, for loading an implementation
% of MPI):
EnvSetup = {};

%%
% The commands to execute on each of the remote machines to which the
% dispatched computation is distributed (for example, for loading MATLAB):
PrevCommands = {};

%% Job scheduler
%
% Specify a custom scheduler employed by the remote machine:
Scheduler = 'custom';

%%
% The scheduler-specific settings must now be specified for the custom
% variable and stored in a structure variable named |SchedulerVars|.
% The details of each field can be found in Table 3 of the DISPATCHER
% module user manual.
%
% The first grouping of the fields is related to creating a job script:
SchedulerVars.Pragma = '';            % Prefix in the directive in a job script
SchedulerVars.JobNameOption = '';     % Option to specify the job name
SchedulerVars.StdOutFileOption = '';  % Option to specify a file to redirect the standard output
SchedulerVars.StdErrFileOption = '';  % Option to specify a file to redirect the standard error 
SchedulerVars.WallTimeOption = '';    % Option to specify the walltime requirement
SchedulerVars.NodesOption = '';       % Option to specify the nodes requirement
SchedulerVars.CPUsOption = '';        % Option to specify the CPUs requirement
SchedulerVars.NodesCPUsOption = '';   % Option to specify both the nodes and CPUs requirement
SchedulerVars.CustomSettings = {};    % Additional custom options (e.g., for memory requirement)

%%
% The next grouping of the fields is related to the relevant commands of
% the custom scheduler used to submit and cancel a job on the remote
% machine from the command line interface:
SchedulerVars.SubmitCommand = 'qsub';
SchedulerVars.CancelCommand = 'qdel';

%%
% The above commands are assumed to be callable from the PATH.

%%
% Specify the regular expression to parse the Job ID from the job
% submission command:
SchedulerVars.SubmitOutputPattern = '';

%%
% The above regular expression is used to extract the ID of a submitted
% job. Submitting a job script to a scheduler typically produces a string
% that contains the job ID.
% For example, submitting a job script to the Slurm scheduler produces,
% by default, the following string:
%
%   Submitted batch job <jobID>
%
% Because <jobID> is strictly numerical, regular expression to extract the
% ID is: |[0-9]+|.

%%
% Specify the environment variable that stores the directory from which the
% job is submitted:
SchedulerVars.WorkingDirectory = '';

%%
% Specify the environment variable that stores the node number to which the
% job is executed:
SchedulerVars.NodeNo = '';
