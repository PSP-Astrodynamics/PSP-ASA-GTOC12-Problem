%% PUSHOVER ANALYSIS OF A 2-STORY MOMENT FRAME USING OPENSEES
% This example showcases how to link UQLab with OpenSees. OpenSees is the
% _Open System for Earthquake Engineering Simulation_ sponsored by the
% Pacific Earthquake Engineering Research Center (PEER).

%% 
% This example creates a UQLink MODEL object that is a wrapper of
% an OpenSees computational  model of a 2-story moment frame under
% lateral load (pushover analysis). 
% For details about the computational model, see:
% <http://opensees.berkeley.edu/wiki/index.php/Pushover_Analysis_of_2-Story_Moment_Frame
% Pushover Analysis of a 2-Story Moment Frame>
% [Last accessed: 01/07/2018].

%%
% The model inputs are yield moments for columns in Story 1 and 2 and yield
% moments for the beams with plastic hinges.
% The outputs are pushover-curves, i.e., force-displacement curves.

%%
% The analysis simply consists of creating an experimental design of size
% 3, running the OpenSees model for each of the input realizations and
% finally retrieving the results and plotting the curves.

%% 0 - SET THE PATH TO THE OPENSEES EXECUTABLE
%
%################## ONCE THE FILE IS UPDATED, DELETE FROM HERE TO .... ###
fprintf('This example is provided as a template to repeat the OpenSees case study in Chapter 3 of the UQLink Manual.\n');
fprintf('For the example to run it is necessary to: \n');
fprintf('- have OpenSees installed; \n');
fprintf('- update the .Command option below by adding the full path to the OpenSees.exe executable (if ''OpenSees'' is not recognized as an OS environmental variable);\n');
fprintf('- delete or comment out the lines 25 to 35 and save the file; \n');
fprintf('- run the example again.\n' );
return;
%################## ...HERE ##############################################

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(1,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL WITH UQLINK (WRAPPER OF OPENSEES)
%
% The UQLink object is a wrapper of OpenSees.
% The mandatory options are:
%
% * the command line or executable
% * the template file (an OpenSees input ActiveTcL script in which the parameters are tagged using X0001, etc.)
% * the output file name
% * the associated parse file, i.e. the m-file that will read
%   the output quantities of interest from the OpenSees output file

%%
% Select UQLink as the model type:
ModelOpts.Type = 'UQLink';
ModelOpts.Name = 'OpenSeesFrame';

%%
% Provide the mandatory options - the command line, i.e.,
% a sample of the command line that will be run on the shell:
ModelOpts.Command = 'OpenSees pushover_concentrated.tcl';

%%
% Provide the template file, i.e., a copy of the original input files
% where the inputs of interest are replaced by markers:
ModelOpts.Template = 'pushover_concentrated.tcl.tpl';

%%
% Provide the MATLAB file that is used to retrieve the quantity of interest
% from the code output file:
ModelOpts.Output.FileName = 'Vbase.out';
ModelOpts.Output.Parser = 'uq_readOutput_OpenSees_Pushover';

%%
% Provide additional non-mandatory options -
% Execution path (where OpenSees will be run):
ModelOpts.ExecutionPath = fullfile(uq_rootPath,...
    'Examples', 'UQLink', 'OpenSees_Pushover');
%%
% Format of the variables in the OpenSees input file:
ModelOpts.Format = {'%1.8f'};

%%
% Set the display to quiet:
ModelOpts.Display = 'quiet';

%%
% Create the UQLink wrapper:
myUQLinkModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of two independent lognormal 
% random variables:
InputOpts.Marginals(1).Name = 'Mycol_12' ;    %Yield moment columns for story 1 % 2
InputOpts.Marginals(1).Type = 'Lognormal';
InputOpts.Marginals(1).Moments = [20350, 0.1*20350]; 
InputOpts.Marginals(2).Name = 'Mybeam_23';    %Yield moent at plastic hinge location
InputOpts.Marginals(2).Type = 'Lognormal';
InputOpts.Marginals(2).Moments = [10938, 0.1*10938];

%%
% Create the INPUT object:
myInput = uq_createInput(InputOpts);

%% 4 - VARIOUS APPLICATIONS

%% 4.1 - Evaluation of the model
%
% Generate an experimental design (ED) of size $50$:
NSamples = 50;
X = uq_getSample(NSamples);

%%
% Evaluate the OpenSees model on these points,
% where every output is the base shear force at one bearing:
[Y1,Y2,Y3] = uq_evalModel(X);

%%
% The total base shear is the sum of the base shears at all bearings:
baseShear = Y1 + Y2 + Y3;

%%
% It is normalized by the total structural weight
% (Floor2Weight+Floor3Weight):
baseShearNorm = abs(baseShear)/(500+590);

%% 4.2 - Force-displacement curves

%%
% The analysis is run over $3'240$ displacement
% increment steps starting from $0~\%$ to $10~\%$ roof drift:
roofDrift = linspace(0,0.1,3240);

%%
% Normalized base shear vs. displacement:
uq_figure
for ii = 1:NSamples
    uq_plot(roofDrift,baseShearNorm(ii,:)); hold on
end
xlabel('Normalized roof drift $\mathrm{u/H}$')
ylabel('Base shear/Total weight')
title('Pushover curves')