%% BASIC REMOTE MACHINE PROFILE FILE TEMPLATE
%
% The basic template contains all the variables required by the DISPATCHER
% module to dispatch UQLab computations applicable to many remote machine
% setups.
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
% Refer to Appendix A of the DISPATCHER module user manual for details.
%
% To use PuTTY saved session, comment the previous three lines and
% uncomment the line below and replace the value with the name of the saved
% session.
% SavedSession = 'mySavedSession';

%% Remote workspace
%
% The variable 'RemoteFolder' provides the location of a directory on the
% remote machine that will be used to store the dispatched computations.
%
% Please note the following:
%
% * The user must have a read- and write-access to the specified remote
%   folder 
% * The tilde (~) symbol as a shortcut to |$HOME| is not supported, the
%   user must the full path to their |$HOME| folder. 
% * [Only when using the TORQUE remote scheduler: The remote folder full
%   path must not contain any whitespaces.] 
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
% Specify the scheduler employed by the remote machine:
Scheduler = 'none';

%%
% Supported values for |Scheduler| are:
%
% * 'torque' (TORQUE)
% * 'pbs' (PBS)
% * 'lsf' (LSF)
% * 'slurm' (Slurm)
% * 'none' (no scheduler employed)
%
% Warning!
% Without using a scheduler on the remote machine, the machine can be
% easily flooed with computations, especially when multiple computations
% are simultaneously dispatched.
