%% RANDOM FIELD: DISCRETIZATION METHODS
%
% This example showcases how to define a two-dimensional random field using
% three different discretization techniques

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework
uqlab
clearvars
rng(100) ;

%% 2 - PROBABILISTIC INPUT MODEL
%
% Specify the type of input
RFInput.Type = 'RandomField' ;

%%
% Specify the family of the correlation function
RFInput.Corr.Family = 'Gaussian' ;

%%
% Specify the correlation length
RFInput.Corr.Length= [0.2, 0.6] ;

%%
% Specify the two-dimensional grid for the mesh
x = linspace(0,1,50) ;
y = linspace(0,1,50) ;
[X,Y] = meshgrid(x,y) ;  
RFInput.Mesh= [X(:) Y(:)] ;

%%
% Specify the mean and standard deviation of the random field
RFInput.Std=1;
RFInput.Mean=1;

%% 3 - DIFFERENT DISCRETIZATION TECHNIQUES
%
% Discretize the random field using different methods

%% 3.1 - EOLE
% Create an INPUT object based on the specified random field options (EOLE
% is the default discretization method)
myRFDefault = uq_createInput(RFInput);

%%
% Print a report of the created INPUT object
uq_print(myRFDefault);

%%
% Display the created INPUT
uq_display(myRFDefault);


%% 3.2 - Karhunen-Loève - Nyström
%
% Specify the discretization scheme, herein Karhunen-Loève (Nyström is the
% default KL solver)
RFInput.DiscScheme = 'KL' ;


%%
% Specify the number of samples per dimension for quadrature
RFInput.KL.SPD = 20 ;

%%
% Create an INPUT object based on the specified random field options
myRFKLNystrom = uq_createInput(RFInput);

%%
% Print a report of the created INPUT object
uq_print(myRFKLNystrom);

%%
% Display the created INPUT
uq_display(myRFKLNystrom);

%% 3.2 - Karhunen-Loève - Discrete
%
% Specify using the discrete/pca approach for KL
RFInput.KL.Method = 'Discrete' ;

%%
% Create an INPUT object based on the specified random field options
myRFKLDiscrete = uq_createInput(RFInput);

%%
% Print a report of the created INPUT object
uq_print(myRFKLDiscrete) ;

%%
% Display the created INPUT
uq_display(myRFKLDiscrete) ;