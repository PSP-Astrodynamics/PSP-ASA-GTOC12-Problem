%% TEN-BAR TRUSS ANALYSIS USING ABAQUS FEA
% This example showcases how to link UQLab with Abaqus FEA. Abaqus FEA is a
% commercial finite element software developed by Dassault Systems.

%%
% For more information about the truss model, see:
% Wei, D., and S. Rahman. (2007). Structural Reliability Analysis
% by Univariate Decomposition and Numerical Integration, 
% Probabilistic Engineering Mechanics  (22)1, 27-38.
% <https://doi.org/10.1016/j.probengmech.2006.05.004
% DOI:10.1016/j.probengmech.2006.05.004>
%
% This example creates a UQLink model object that links UQlab to
% an Abaqus computational model of a 10-bar truss.
% The model inputs are the cross-sectional areas and the output
% is the tip deflection (vertical nodal displacement
% at the tip of the truss).
% Various analyses are carried out with the created UQLink MODEL object.

%% 0 - SET THE PATH TO THE ABAQUS EXECUTABLE
%
%################## ONCE THE FILE IS UPDATED, DELETE FROM HERE TO .... ###
fprintf('This example is provided as a template to repeat the Abaqus case study in Chapter 3 of the UQLink Manual.\n');
fprintf('For the example to run it is necessary to: \n') ;
fprintf('- have ABAQUS Standard installed; \n') ;
fprintf('- update the .Command option below by giving the full path to the abaqus.exe executable (if ''abaqus'' is not recognized as an OS environmental variable);\n');
fprintf('- delete or comment out the lines 20 to 33 and save the file; \n');
fprintf('- run the example again.\n' ) ;
return ;
%################## ...HERE ##############################################

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(1,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL WITH UQLINK (WRAPPER OF ABAQUS)
%
% The UQLink object is a wrapper of Abaqus. The mandatory options are:
%
% * the command line or executable
% * the template file (an Abaqus input file in which the parameters are tagged using X0001, etc.)
% * the output file name
% * the associated parser file name, i.e. the m-file that will read
%   the output quantities of interest from the Abaqus output file

%%
% Model type:
ModelOpts.Type = 'UQLink';
ModelOpts.Name = 'TenBarTruss';
%%
% Provide mandatory options - the command line, i.e.,
% a sample of the command line that will be run on the shell:
ModelOpts.Command = 'abaqus -job TenBarTruss interactive';

%%
% Provide the template file, i.e., a copy of the original input files
% where the inputs of interest are replaced by markers:
ModelOpts.Template = 'TenBarTruss.inp.tpl';

%%
% Provide the MATLAB file that is used to retrieve the quantity of interest
% from the code output file:
ModelOpts.Output.FileName = 'TenBarTruss.dat';
ModelOpts.Output.Parser = 'readTenBarTrussOutput';

%%
% Provide additional non-mandatory options -
% Execution path (where Abaqus will be run):
ModelOpts.ExecutionPath = fullfile(uq_rootPath,...
    'Examples','UQLink','Abaqus_Truss') ;
%%
% Specify the format of the variables written in the Abaqus input file:
ModelOpts.Format = {'%1.8f'};

%%
% Set the display to quiet:
ModelOpts.Display = 'quiet';

%%
% Create the UQLink wrapper:
myUQLinkModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of 10 independent bounded Gaussian
% variables:
%
% $$X_i \sim N(2.5, 0.5^2), \quad X_i \in [ 10^{-5}, +\infty], \quad i =1, 2, \ldots, 10$$
%
for ii = 1:10
    InputOpts.Marginals(ii).Name = ['A', num2str(ii)]; % cross section areas
    InputOpts.Marginals(ii).Type = 'Gaussian';
    InputOpts.Marginals(ii).Moments = [2.5 0.5]; % units: in^2
    InputOpts.Marginals(ii).Bounds = [1e-5 inf];
end

% Create the INPUT object
myInput = uq_createInput(InputOpts);

%% 4 - VARIOUS APPLICATIONS

%% 4.1 Estimation of the response PDF using Monte Carlo simulation
%
% Generate an experimental design (ED) of size $250$
% using Latin Hypercube Sampling:
X = uq_getSample(250,'LHS');

%%
% Evaluate the Abaqus model (truss tip deflection) at the ED points:
Y = uq_evalModel(myUQLinkModel,X);

%% 
% Plot a kernel-smoothing density of the tip deflection:
[f,xi] = ksdensity(Y);
uq_figure('Position', [50 50 500 400])
uq_plot(xi,f)
uq_setInterpreters(gca)
xlabel('$\mathrm{u(x)}$', 'FontSize', 24)
ylabel('Density', 'FontSize', 24)

%% 4.2 Polynomial chaos expansion (PCE)
% Select the PCE surrogate model:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'PCE';

%% 
% Select the PCE options and create the PCE model:
MetaOpts.Degree = 1:10 ;
MetaOpts.ExpDesign.X = X;
MetaOpts.ExpDesign.Y = Y;
myPCE = uq_createModel(MetaOpts);

%% 4.3 Use the PCE model for sensitivity analysis
%
PCESobol.Type = 'Sensitivity';
PCESobol.Method = 'Sobol';
PCESobol.Sobol.Order = 2;

PCESobolAnalysis = uq_createAnalysis(PCESobol);

%%
% Display results of Sobol analysis
uq_display(PCESobolAnalysis)

%% 4.4 Reliability analysis
% Perform a reliability analysis using Monte Carlo simulation:
MCSopt.Type = 'Reliability';
MCSopt.Method = 'MCS';

%%
% Define the limit-state surface:
MCSopt.LimitState.Threshold = 18;   % unit: inch
MCSopt.LimitState.CompOp = '>=';

%%
% Run the analysis and display the results:
myMCS = uq_createAnalysis(MCSopt);
uq_display(myMCS)