%% UQLINK: SIMPLY SUPPORTED BEAM
%
% This example showcases how the UQLink module of UQLab can be used 
% to run a third-party software.
% 
% In this example, the third-party software is an executable
% that evaluates the mid-span deflection of a simply supported beam 
% given a set of five input parameters, namely the beam width,
% the beam height, the beam length, its Young's modulus and the load.
% These parameters are read from a simple text file 
% and returned in another text file.
% Then, an Active Kriging Monte Carlo simulation (AK-MCS)
% is carried out to estimate the failure probability of the system 
% under a displacement criterion.

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
% This simple computation is carried out by a code in an executable file,
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
ModelOpts.Name = 'SimplySupportedBeam';

%%
% Provide the execution command line that is used 
% to compute the beam deflection given the input parameters.

%%
% First, provide the path to the executable:
EXECPATH = fullfile(uq_rootPath,...
    'Examples', 'UQLink', 'C_SimplySupportedBeam'); 

%%
% (*Note*: The shipped executable name depends on the operating system):
if ispc
    EXECNAME = 'myBeam_win';
elseif isunix
    if ~ismac
        EXECNAME = 'myBeam_linux';
    else
        EXECNAME = 'myBeam_mac';
    end
end

%%
% Then provide the name of the input file:
INPUTFILE = 'SSBeam_Deflection.inp';

%%
% Generate the final executable name which includes full path
% and is inserted in double quote delimiters:
DELIM = '"';
EXECUTABLE = [DELIM fullfile(EXECPATH,EXECNAME) DELIM];
COMMANDLINE = sprintf('%s %s',EXECUTABLE,INPUTFILE);

%%
% Finally, pass the generated full path to UQLab model options:
ModelOpts.Command = COMMANDLINE;

%%
% Provide the template file, i.e., a copy of the original input files
% where the inputs of interest are replaced by markers:
ModelOpts.Template = 'SSBeam_Deflection.inp.tpl';

%%
% Provide the MATLAB file that is used to retrieve the quantity of interest
% from the code output file:
ModelOpts.Output.Parser = 'uq_read_SSBeamDeflection';
ModelOpts.Output.FileName = 'SSBeam_Deflection.out';

%%
% Set the execution path:
ModelOpts.ExecutionPath = EXECPATH;

%%
% Set the display to quiet:
ModelOpts.Display = 'quiet';

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

%% 4 - RELIABILITY ANALYSIS USING AK-MCS
%
% Select the reliability analysis technique:
AKOptions.Type = 'Reliability';
AKOptions.Method = 'AKMCS';

%%
% Specify the limit-state surface definition:
AKOptions.LimitState.Threshold = 0.015;
AKOptions.LimitState.CompOp = '>=';

%% 
% Specify the maximum number of sample points
% added to the experimental design:
AKOptions.AKMCS.MaxAddedED = 30;

%%
% Specify the initial experimental design:
AKOptions.AKMCS.IExpDesign.N = 20;
AKOptions.AKMCS.IExpDesign.Sampling = 'LHS';

%%
% Specify the meta-model options
% (*note*: all Kriging options are supported):
AKOptions.AKMCS.Kriging.Corr.Family = 'Gaussian';

%%
% Specify the convergence criterion
% for the adaptive experimental design algorithm
AKOptions.AKMCS.Convergence = 'stopPf';

%%
% Run the analysis:
AKAnalysis = uq_createAnalysis(AKOptions);

%%
% Print out a report of the analysis:
uq_print(AKAnalysis)

%%
% *Note:* The reference solution, $P_{f_{ref}} = 0.0171$, 
% is found using a Monte Carlo simulation of $10^5$ samples
% evaluated on the original model.

%%
% Create a graphical representation of the results:
uq_display(AKAnalysis)