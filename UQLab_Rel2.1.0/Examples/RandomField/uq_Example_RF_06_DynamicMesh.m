%% RANDOM FIELD: DEFINING A MESH AT SAMPLING STAGE
%
% This example showcases how to define a new mesh to sample trajectories of
% a random field.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(1,'twister')
uqlab

%% 2 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input is a one-dimensional Gaussian random field with
% Gaussian correlation function. The discretization is carried out using
% EOLE.

%%
% Specify the type of input
RFInput.Type = 'RandomField' ;

%%
% Specify the correlation family
RFInput.Corr.Family = 'Gaussian' ;

%%
% Specify the correlation length
RFInput.Corr.Length = 1 ;

%%
% Specify the domain of definition of the random field
RFInput.Domain = [0;10] ;

%%
% Specify the mean and standard deviation of the random field
RFInput.Mean = 5 ;
RFInput.Std = 2 ;

%%
% Create an INPUT object based on the specified random field options
myRFInput = uq_createInput(RFInput);

%%
% Print a report of the created INPUT object
uq_print(myRFInput);

%%
% Display the created INPUT
uq_display(myRFInput);

%%
% Get the internal mesh that has been used for display: Note that this is
% the same mesh used to discretize the random field
InternalMesh = myRFInput.Internal.Mesh ;
N = size(InternalMesh,1)

%% 3 - SAMPLING ON A NEW MESH

%%
% Create a new mesh to represent the random field
SamplingMesh = linspace(0,10,250)' ;

%%
% Sample on the new mesh
X = uq_getSample(10,'Mesh',SamplingMesh);

%%
% Plot the trajectories on the new mesh
uq_plot(SamplingMesh,X);

%%
% Sample another by choosing optimized LHS for the Gaussian random variables xi
X2 = uq_getSample(10,'LHS','LHsiterations',100,'Mesh',SamplingMesh);