%% MODEL MODULE: STOCHASTIC SIMULATOR WITH TRAJECTORIES
%
% This example showcases the various ways to define a stochastic 
% simulator in UQLab using the geometric Brownian motion at time 1
% as the computational model.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The value of the geometric Brownian motion at time 1 follows a mixture
% Gaussian distribution:
%
% $$Y_{x} \sim 0.4 \mathcal{N}(\mu_1(x),0.8) + 0.6 \mathcal{N}(\mu_2(x),0.8)$$
%
% where $\mu_1(x) = 4\sin(\pi x)^2 + 4x - 2$, $\mu_2(x) = 4\sin(\pi x)^2 - 4x + 2$
% and $x \in [0,1]$
%
% This computation is carried out by the function
% |uq_1dbimodal(X,R)| supplied with UQLab.
% The inputs this function are gathered into the $N \times M$ matrix |X| 
% where $N$ and $M$ are the numbers of realizations and input.
% R corresponding to the number of replications that should be generated
% for each set of the input parameters. If it is not provided, its value is
% set to 1
% 
ModelOpts.mFile = 'uq_1dbimodal';
ModelOpts.isStochastic = true;
myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of
% two independent uniform random variables:
%
% $X \sim \mathcal{U}(0,1)$
inputOpt.Marginals(1).Type = 'Uniform';
inputOpt.Marginals(1).Parameters = [0,1];
myInput = uq_createInput(inputOpt);


%% 4 - GENERATING AND MANAGING OUTPUT TRAJECTORIES
%% 4.1 Generate a single trajectory
% A stochastic simulator can be seen as a random field with the input as
% the index. When fixing the internal stochasticity, we are able to
% evaluate a trajectory. This is usually achieved by controlling the random
% seed
N = 20;
X = linspace(0,1,N)';
Ytraj1 = uq_evalModel(myModel,X,'evalTraj',true);
uq_figure
uq_plot(X,Ytraj1,'-*')
xlabel('$x$')
ylabel('$y$')
title('Single trajectory');

%% 4.2 Generate multiple trajectories
R = 5;
Ytraj2 = uq_evalModel(myModel,X,R,'evalTraj',true);
% the output is an 3-d array of N*1*R: each slice in the third
% direction is a vector of N*1*1 and it is a trajectory
uq_figure
uq_plot(X,reshape(Ytraj2,[],R,1),'-*')
xlabel('$x$')
ylabel('$y$')
title([num2str(R),' trajectories']);

%% 4.3 Explore the dependency structure of the random field

% Generate first a relatively large number of trajectories
R2 = 500;
Ytraj3 = uq_evalModel(myModel,X,R2,'evalTraj',true);

% estimate the mean and variance on the experimental design
Ymean = mean(Ytraj3,3);
Yvar = var(Ytraj3,0,3);

% plot the empirical mean
uq_figure
uq_plot(X,Ymean,'-*')
title('Empirical mean')
xlabel('$x$')
ylabel('$\hat{m}(x)$')

% plot the empirical variance
uq_figure
uq_plot(X,Yvar,'-*')
title('Empirical variance')
xlabel('$x$')
ylabel('$\hat{v}(x)$')

%%
% For trajectories, we can also evaluate the correlation between inputs
% within each trajectory
Ycorr = corr(squeeze(Ytraj3)');

% and plot it
uq_figure
imagesc(Ycorr,"XData",X,"YData",X); 
axis equal tight xy;
title('Empirical correlation')
uq_formatDefaultAxes(gca)
xlabel('$x_1$')
ylabel('$x_2$')
zlabel('$\hat{\rho}(x_1,x_2)$')
cb = colorbar;
title(cb,'$\hat{\rho}(x_1,x_2)$','interpreter','latex')

%% 4.4 Random seed manipulation
% One can generate a trajectory corresponding to 
% a specific random seed (integer between within [0,2^32-1])
Ytraj4= uq_evalModel(myModel,X,'randomSeed',5);
Ytraj5= uq_evalModel(myModel,X,'randomSeed',5);

% because the random seed is fixed, the two trajectories are identical
disp(['The difference between the two trajectories is ',num2str(max(abs(Ytraj5(:)-Ytraj4(:))))]);

%%
% One can also provide a set of random seeds
% because the trajectories are stored in a 3-d array with the third
% dimension corresponding to the random seed, the speficied random seeds
% should be an array of 1*1*R
randSeed1 = reshape([1,2,3,4,5,6,7,8],1,1,[]);
Ytraj6= uq_evalModel(myModel,X,'randomSeed',randSeed1);
Ytraj7= uq_evalModel(myModel,X,'randomSeed',randSeed1);
disp(['The difference between two sets of runs is ',num2str(max(abs(Ytraj7(:)-Ytraj6(:))))]);

%%
% We can also control the random seeds for each single model run. In this
% the speficied random seeds should be of dimension N*1*R
randSeed2 = reshape(1:N*R,N,1,R);
Ytraj8= uq_evalModel(myModel,X,'randomSeed',randSeed2);
Ytraj9= uq_evalModel(myModel,X,'randomSeed',randSeed2);
disp(['The difference between two sets of runs is ',num2str(max(abs(Ytraj9(:)-Ytraj8(:))))]);


%% 4.5 Returning random seeds for repeatability
% When evaluating trajectories, UQLab can also return the corresponding random seeds
% which allows for reproducibility, i.e., generate the same trajectories
[Ytraj10,randomSeed3] = uq_evalModel(myModel,X,R,'evalTraj',true);
Ytraj11 = uq_evalModel(myModel,X,R,'randomSeed',randomSeed3);
disp(['The difference between two sets of runs is ',num2str(max(abs(Ytraj11(:)-Ytraj10(:))))]);
