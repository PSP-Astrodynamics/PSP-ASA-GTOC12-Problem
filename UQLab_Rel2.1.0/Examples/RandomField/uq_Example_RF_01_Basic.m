%% RANDOM FIELD: RANDOM FIELDS DEFINITION
%
% This example showcases how to define a random field and then sample
% trajectories from it.

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
% Specify the mesh where the random field is sampled
RFInput.Mesh = linspace(0,10,250)' ;

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
% Display the first five eigenvectors of the random field (note: they are
% shown on the EOLE mesh)
uq_figure;
uq_plot(myRFInput.RF.CovMesh, myRFInput.RF.Phi(:,1:5)) ;
xlabel ('$x$','interpreter','latex') ;
ylabel('$\Phi$','interpreter','latex') ;
mylegend = legend('$\Phi_1$','$\Phi_2$','$\Phi_3$','$\Phi_4$','$\Phi_5$');
set(mylegend, 'Interpreter', 'latex','FontSize',16,'Orientation','horizontal');

%% 3 - DRAW SAMPLES AND VALIDATE THE COVARIANCE APPROXIMATION
% Sample trajectories using Monte Carlo simulation
X = uq_getSample(1e5);

%%
% Calculate the analytical covariance matrix
analytical_cov = myRFInput.Internal.Std^2 * ...
    uq_eval_Kernel(RFInput.Mesh,RFInput.Mesh,RFInput.Corr.Length, ...
    myRFInput.Internal.Corr) ;

%%
% Plot the analytical  covariance
uq_figure; 
imagesc(analytical_cov) ; axis equal tight
uq_formatDefaultAxes(gca) % format the figure
cl = get(gca,'CLim'); % get the colorbar limits
colorbar ;

%%
% Estimate the process covariance using the sampled trajectories
estimated_cov = cov(X) ;

%%
% Plot the estimated covariance
uq_figure; 
imagesc(estimated_cov); axis equal tight
uq_formatDefaultAxes(gca) % format the figure
set(gca,'CLim',cl); % set the colorbar limits identical to the analytical figure
colorbar ;
                         
%%
% Compare the two covariance matrices
uq_figure; 
imagesc((analytical_cov-estimated_cov)./RFInput.Std^2) ; axis equal tight
uq_formatDefaultAxes(gca) % format the figure
colorbar ;
