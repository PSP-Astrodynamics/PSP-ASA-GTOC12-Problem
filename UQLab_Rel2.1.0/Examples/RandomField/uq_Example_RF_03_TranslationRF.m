%% RANDOM FIELD: NON-GAUSSIAN TRANSLATION RANDOM FIELDS
%
% This example showcases how to define a lognormal random field and
% transform it into random fields with same copula but different marginals
% using point-by-point isoprobabilistic transformation. Such random fields
% are known as translation random fields.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input is a one-dimensional lognormal random field with
% Gaussian correlation function. The discretization is carried out using
% Karhunen-Loève expansion.

%%
% Specify the type of input
RFInput.Type = 'RandomField' ;

%%
% Specify the type of random fields
RFInput.RFType = 'Lognormal' ;

%%
% Specify Karhunen-Loève as discretization scheme
RFInput.DiscScheme = 'KL' ;

%%
% Specify the correlation family
RFInput.Corr.Family = 'Gaussian' ;

%%
% Specify the correlation length
RFInput.Corr.Length = 1 ;

%%
% Specify the mesh when the random field is sampled
RFInput.Mesh = linspace(0,10,100)' ;

%%
% Specify the mean and standard deviation of the random field
RFInput.Mean = 10 ;
RFInput.Std = 5 ;

%%
% Create an INPUT object based on the specified random field options
myRFInput = uq_createInput(RFInput);

%%
% Print a report of the created INPUT object
uq_print(myRFInput);

%% 3 - TRANSFORM AND COMPARE TRAJECTORIES
%
% Trajectories from the lognormal random field are sampled, then
% translated to Gaussian and Gumbel realizations

%% 
% Sample some realizations of the random field
X = uq_getSample(250);

%%
% Transform the trajectories into ones with Gaussian marginals
Y = uq_translateRF(X, myRFInput, 'Gaussian');


%% 
% Transform the trajectories into ones with Gumbel marginals
Z = uq_translateRF(X, myRFInput, 'Gumbel');

%% 
% Plot trajectories of the Lognormal random field
uq_figure;
p = plot(myRFInput.Internal.Mesh,X,'-','linewidth',0.5,'color',[.5 .5 .5]);
uq_formatDefaultAxes(gca)
xlabel ('$x$','interpreter','latex') ;
ylabel('$H(x)$','interpreter','latex') ;
title('Lognormal random field','Interpreter', 'latex','FontSize',16) ;

% Superimpose sample mean and quantiles
hold on;
m = uq_plot(myRFInput.Internal.Mesh,mean(X),'-b');
qq = uq_plot(myRFInput.Internal.Mesh,quantile(X,[.05 .95]),'--b');
legend([m qq(1) p(1)],'Samples mean','5-95% quantile','Trajectories')

%% 
% Plot trajectories of the corresponding random field with Gaussian
% marginals
uq_figure;
p = plot(myRFInput.Internal.Mesh,Y,'-','linewidth',0.5,'color',[.5 .5 .5]);
uq_formatDefaultAxes(gca)
xlabel ('$x$','interpreter','latex') ;
ylabel('$H(x)$','interpreter','latex') ;
title('Gaussian random field','Interpreter', 'latex','FontSize',16) ;

% Superimpose sample mean and quantiles
hold on;
m = uq_plot(myRFInput.Internal.Mesh,mean(Y),'-b');
qq = uq_plot(myRFInput.Internal.Mesh,quantile(Y,[.05 .95]),'--b');
legend([m qq(1) p(1)],'Samples mean','5-95% quantile','Trajectories')

%% 
% Plot trajectories of the corresponding Gaussian random field with Gumbel
% marginals
uq_figure;
p = plot(myRFInput.Internal.Mesh,Z,'-','linewidth',0.5,'color',[.5 .5 .5]);
uq_formatDefaultAxes(gca)
xlabel ('$x$','interpreter','latex') ;
ylabel('$H(x)$','interpreter','latex') ;
title('Gaussian random field with Gumbel marginals','Interpreter', 'latex','FontSize',16) ;

% Superimpose sample mean and quantiles
hold on;
m = uq_plot(myRFInput.Internal.Mesh,mean(Z),'-b');
qq = uq_plot(myRFInput.Internal.Mesh,quantile(Z,[.05 .95]),'--b');
legend([m qq(1) p(1)],'Samples mean','5-95% quantile','Trajectories')
