%% HPC DISPATCHER: REMOTE EVALUATION OF A UQLINK MODEL
%
% This example showcases how the DISPATCHER module may be used to dispatch
% a UQLink model evaluation with or without MATLAB/UQLAB available on 
% the remote machine. 
% 
% In this example, the 3rd-party software (i.e., code) is an executable
% that evaluates the mid-span deflection of a simply supported beam 
% given a set of five input parameters, namely the beam width,
% the beam height, the beam length, its Young's modulus, and the load.
% These parameters are read from a simple text file 
% and returned in another text file.
% The executable is assumed to be available on the remote machine.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(1,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The simply supported beam problem is shown in the following figure:
uq_figure('Position', [50 50 500 400]) 
[I,~] = imread('SimplySupportedBeam.png');
image(I)
axis equal
set(gca, 'visible', 'off')

%% 
% The (negative) deflection of the beam at the midspan location (V)
% is given by:
%
% $$ V = \frac{ 5 p  L^4 }{32 E b h^3} $$
%
% This simple computation is carried out by code in an executable file,
% herein called 'myBeam', that takes as input a text file
% which contains a header followed by five lines.
% Each of the lines represents the parameters in the following order:
%
% # $b$: beam width
% # $h$: beam height
% # $L$: beam length
% # $E$: Young's modulus
% # $p$: uniform load
% 
% This code returns the computed deflection in an output file using
% the same name as the provided input file but with the extension '.out'.

%%
% Select the model type corresponding to UQLink:
ModelOpts.Type = 'UQLink';

%%
% Provide the execution command line that is used 
% to compute the beam deflection given the input parameters.

%%
% First, provide the name of the 3rd-party code executable:
EXECNAME = 'myBeam_linux';

%%
% This executable runs on a Linux operating system on the remote machine.
% Computations can only be dispatched using the DISPATCHER module to
% a remote machine that runs a Linux operating system.

%%
% Then provide the name of the input file:
INPUTFILE = 'SSBeam_Deflection.inp';

%%
% Create the command string to execute the 3rd-party executable (i.e.,
% including the input file):
COMMANDLINE = sprintf('%s %s', EXECNAME, INPUTFILE);

%%
% Set the command string to the UQLink MODEL options:
ModelOpts.Command = COMMANDLINE;

%%
% Provide the template file, i.e., a copy of the original input files
% where the inputs of interest are replaced by markers:
ModelOpts.Template = 'SSBeam_Deflection.inp.tpl';

%%
% Provide the location of this template file in the local machine.
ModelOpts.TemplatePath = fullfile(...
    uq_rootPath, 'Examples', 'UQLink', 'C_SimplySupportedBeam');
%%
% *Note*: This template file will be copied to the remote folder where the
%         computational job will be executed

%%
% Provide the MATLAB function that is used to retrieve the quantity of
% interest from the code output file:
ModelOpts.Output.Parser = 'uq_read_SSBeamDeflection';

%%
% Set output filename of the code execution:
ModelOpts.Output.FileName = 'SSBeam_Deflection.out';

%%
% Set the executable path (*note*: this is the executable path *on the
% remote machine*): 
EXECPATH = '/path/to/the/executable/executableName';
ModelOpts.ExecutablePath = EXECPATH;

%%
% Create a MODEL object in UQLab:
myBeamModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The simply supported beam model has five independent random inputs,
% modelled by lognormal random variables. 
% The input model is detailed in the following table:

%%
% <html>
% <table border=1><tr>
% <td><b>Variable</b></td>
% <td><b>Description</b></td>
% <td><b>Distribution</b></td>
% <td><b>Mean</b></td>
% <td><b>Std. deviation</b></td></tr>
% <tr>
% <td>b</td>
% <td>Beam width</td>
% <td>Lognormal</td>
% <td>0.15 m</td>
% <td>7.5 mm</td>
% </tr>
% <tr>
% <td>h</td>
% <td>Beam height</td>
% <td>Lognormal</td>
% <td>0.3 m</td>
% <td>15 mm</td>
% </tr>
% <tr>
% <td>L</td>
% <td>Length</td>
% <td>Lognormal</td>
% <td>5 m</td>
% <td>50 mm</td>
% </tr>
% <tr>
% <td>E</td>
% <td>Young's modulus</td>
% <td>Lognormal</td>
% <td>30000 MPa</td>
% <td>4500 MPa</td>
% </tr>
% <tr>
% <td>p</td>
% <td>Uniform load</td>
% <td>Lognormal</td>
% <td>10 kN/m</td>
% <td>2 kN/m</td>
% </tr>
% </table>
% </html>

%%
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

%%
% Create an INPUT object:
myInput = uq_createInput(InputOpts);

%% 4 - DISPATCHER OBJECT
%
% A DISPATCHER object is specified, at the minimum, by a remote machine
% profile file. The file contains everything necessary to setup of the
% remote computing environment. See Chapter 2 and Appendix A of the
% HPC dispatcher module user manual for more information on how to set up a
% profile file.
% 
% The profile file is stored as a MATLAB script and can be located anywhere
% in the MATLAB search path. 
% As a starting point, a basic template file
% |profile_file_template_basic.m| is available in |$UQLABROOT/Profiles/HPC|.
%
% Furthermore, it is assumed that a key-based authenticated SSH connection
% to the remote machine can be established.
% Refer to Appendix A and B of the Dispatcher user manual for instructions
% on how to set up the key-based authentication and the remote machine
% profile file, respectively.

%%
% Suppose a profile file named |myRemoteProfile.m| is available in the
% MATLAB search path.
%
% Specify the name of the profile file:
DispatcherOpts.Profile = 'myRemoteProfile';

%%
% To execute the UQLink MODEL evaluation in parallel on the remote machine,
% set the desired number of parallel processes:
DispatcherOpts.NumProcs = 4;

%%
% Then create a DISPATCHER object:
myDispatcher = uq_createDispatcher(DispatcherOpts);

%%
% A report on the dispatcher unit can be produced using the |uq_print| 
% command:
uq_print(myDispatcher)

%% 5 - MODEL EVALUATION IN PARALLEL USING A DISPATCHER UNIT

%%
% Generate a random sample of input values:
X = uq_getSample(1e2);

%% 5.1 Remote machine without MATLAB/UQLab
%
% Third-party code execution with UQLink can be dispatched to the remote
% machine even without MATLAB or UQLab installed on the machine, as long as
% the 3rd-party code does not require MATLAB (or UQLab) to run.

%%
% Dispatch the UQLink model evaluation as follows:
YwithoutMATLAB = uq_evalModel(X,'HPC'); 

%%
% By default, the dispatched computation is synchronized with respect to
% the local UQLab session.

%% 5.2 Remote machine with MATLAB and UQLab
%
% If both MATLAB and UQLab are available on the remote machine, they may be
% used in the dispatched computation of the UQLink model.
% By using MATLAB and UQLab on the remote machine, the pre-processing of 
% the third-party code inputs as well as the post-processing of the outputs
% are carried out on the remote machine. In the case of particularly large
% input and output files, this may speed up the dispatched computations.

%%
% To use remote MATLAB/UQLab, set the following option:
ModelOpts.RemoteMATLAB = true;

%%
% Create another UQLink MODEL object :
myModelRemoteMATLAB = uq_createModel(ModelOpts);

%%
% Dispatch the UQLink MODEL evaluation to the remote machine:
YwithMATLAB = uq_evalModel(X,'HPC');

%% 5.3 Verification
%
% Confirm that two dispatched computations (i.e., Jobs) have been created
% so far:
uq_listJobs(myDispatcher)

%%
% Verify that the two results are identical:
isequal(YwithMATLAB,YwithoutMATLAB)
