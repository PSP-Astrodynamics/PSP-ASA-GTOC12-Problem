%% RANDOM FIELD: CONDITIONAL RANDOM FIELDS
%
% This example showcases how to define a conditional random field and
% sample trajectories from it

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - PROBABILISTIC INPUT MODEL

%%
% Specify the type of input
RFInput.Type = 'RandomField' ;
RFInput.DiscScheme = 'KL' ;
%%
% Specify the correlation family
RFInput.Corr.Family = 'Gaussian' ;

%%
% Specify the correlation length
RFInput.Corr.Length = 0.2 ;

%%
% Specify the expansion order
RFInput.ExpOrder = 10 ;

%%
% Specify the mesh for the sampling of the random field
RFInput.Mesh = linspace(-1,1,250)';

%%
% Specify the mean and standard deviation of the random field
RFInput.Mean = 5 ;
RFInput.Std = 1 ;

%%
% Specify the conditional data
RFInput.RFData.X = [-0.5; 0; 0.5] ;
RFInput.RFData.Y = [1; 5; 4] ;

%%
% Create an INPUT object based on the specified random field options
myRF = uq_createInput(RFInput) ;

%%
% Print a report of the created INPUT object
uq_print(myRF);

%%
%  Display the generated random field
uq_display(myRF);

%% 3 - DRAW SAMPLES AND DISPLAY TRAJECTORIES
%
% Draw $10^5$ samples using Monte Carlo sampling
X = uq_getSample(1e5, 'MC') ;

%% 4 - COMPARISON WITH KRIGING
%
% Select the metamodeling tool and the Kriging module:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'Kriging';

%% 
% Assign the experimental design and the corresponding model responses:
MetaOpts.ExpDesign.X = RFInput.RFData.X;
MetaOpts.ExpDesign.Y = RFInput.RFData.Y;

%%
% Perform ordinary Kriging
% (i.e., Kriging with a constant trend):
MetaOpts.Kriging.Trend.Type = 'ordinary';

%%
% Specify the mean of the random field as the constant term in ordinary Kriging
MetaOpts.Kriging.beta = RFInput.Mean;  

%%
% Specify the Kriging variance
MetaOpts.Kriging.sigmaSQ = 1 ;

%%
% Specify the correlation length
MetaOpts.Kriging.theta = 0.2 ;

%%
% Specify the correlation family options
MetaOpts.Kriging.Corr.Family = 'Gaussian';
MetaOpts.Kriging.Corr.Type = 'ellipsoidal' ;

%%
% Create the custom Kriging model
myCustomKriging = uq_createModel(MetaOpts);


%%
% Evaluate the Kriging model on the random field mesh
Yval =uq_evalModel(RFInput.Mesh);

%%
% Plot on the same figure: 
%  - the Kriging prediction 
%  - the mean of the sampled trajectories.

uq_plot(RFInput.Mesh,Yval,'--','linewidth',3); hold on ;
uq_plot(RFInput.Mesh,mean(X),'linewidth',2);
mylegend = legend('Kriging predictor','Sample mean');
set(mylegend, 'Interpreter', 'latex','FontSize',16,'Orientation','horizontal');