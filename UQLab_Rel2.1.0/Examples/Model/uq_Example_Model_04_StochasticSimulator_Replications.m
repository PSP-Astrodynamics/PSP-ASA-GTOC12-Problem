%% MODEL MODULE: STOCHASTIC SIMULATOR
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
% The value of the geometric Brownian motion at time 1 follows a lognormal
% distribution:
%
% $$Y_{\mathbf{x}} \sim \mathcal{L}\mathcal{N}(x_1 - x^2_2/2,x_2)$$
%
% where $x_1 \in {R}, \; x_2 > 0$;
%
% This computation is carried out by the function
% |uq_GBM(X,R)| supplied with UQLab.
% The inputs this function are gathered into the $N \times M$ matrix |X| 
% where $N$ and $M$ are the numbers of realizations and input.
%
% R is the number of replications that should be generated for each set of
% the input parameters. If it is not provided, its value is 
% set to 1
% 
ModelOpts.mFile = 'uq_GBM';
ModelOpts.isStochastic = true;
myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of
% two independent uniform random variables:
%
% $X_1 \sim \mathcal{U}(0, 0.1), X_2 \sim \mathcal{U}(0.1, 0.4)$

inputOpt.Marginals(1).Type = 'Uniform';
inputOpt.Marginals(1).Parameters = [0,0.1];
inputOpt.Marginals(2).Type = 'Uniform';
inputOpt.Marginals(2).Parameters = [0.1,0.4];

% Create an INPUT object based on the marginals:
myInput = uq_createInput(inputOpt);

%% 4.1 Explore stochastic behaviors
X = [0.05,0.25];
% evaluate the stochastic simulator once for X and the simulator produces 
% one realization of the underlying response distribution
Y1 = uq_evalModel(myModel,X);

% evaluate the stochastic simulator another time for the same value of X
Y2 = uq_evalModel(myModel,X);

% Due to the intrinsic stochasticity, the results are different upon two
% model runs
display(['The first runs gives ',num2str(Y1), ', while the second run returns ',num2str(Y2)]);

%% 4.2 Run replications
% To see the response distribution f_{Y|x}, we need to perform replications
R = 1000;
Yrep1 = zeros(R,1);
for r=1:R
    yr = uq_evalModel(myModel,X);
    Yrep1(r)=yr;
end
% plot the response distribution
myColors = uq_colorOrder(2);
uq_figure
uq_histogram(Yrep1, 'FaceColor', myColors(1,:),'normalized','pdf')
title(['Model response for (',num2str(X(1)),',',num2str(X(2)),')'])
xlabel('$Y_{x}$')

%%
% We can also perform directly replications within UQLab:
Yrep2 = uq_evalModel(myModel,X,R);% This is a 3-d array of size 1*1*R
uq_figure
uq_histogram(squeeze(Yrep2), 'FaceColor', myColors(2,:),'normalized','pdf')
title(['Model response for (',num2str(X(1)),',',num2str(X(2)),')'])
xlabel('$Y_{x}$')

%%
% The two samples come from the same response distribution, and we can
% compare them with a QQ-plot:
uq_figure;
qqplot(Yrep1(:),Yrep2(:));
axis equal tight
title('QQ-plot of the two replicated samples')
xlabel('$Y^{1}_{x}$','Interpreter','latex')
ylabel('$Y^{2}_{x}$','Interpreter','latex')
uq_formatDefaultAxes(gca)

%% 4.3 Run replications for multiple values of X
Xval = [0.07,0.13
         0.04,0.21
         0.05,0.3
         ];
Nval = size(Xval,1);
Yresp3 = uq_evalModel(myModel,Xval,R);% Yresp is a 3-d array of size Nval*1*R

% plot the histograms for each point
myColors = uq_colorOrder(Nval);
ll = cell(1,Nval);
uq_figure;
ix = 1;
uq_histogram(squeeze(Yresp3(ix,:,:)),'FaceColor', myColors(ix,:),'normalized','pdf');
ll{ix} = ['$\mathbf{x}=(',num2str(Xval(ix,1),'%4.2f'),',',num2str(Xval(ix,2),'%4.2f'),')$'];
hold on
for ix=2:Nval
    uq_histogram(squeeze(Yresp3(ix,:,:)),'FaceColor', myColors(ix,:),'normalized','pdf');
    ll{ix} = ['$\mathbf{x}=(',num2str(Xval(ix,1),'%4.2f'),',',num2str(Xval(ix,2),'%4.2f'),')$'];
end
title(['Histograms of model responses at ',num2str(Nval),' points'])
xlabel('$Y_{x}$')
uq_legend(ll);
hold off

% calculate some summary statistics from replications
mm = mean(Yresp3,3);% mean
vv = var(Yresp3,0,3); %variance
qq = quantile(Yresp3,[0.05,0.5,0.95],3);% 0.5%, 50%, 95% quantiles

%% 3.4 Aggregate all the randomness in a single histogram
NMC = 1e4;
XMC = uq_getSample(NMC);
Yresp4 = uq_evalModel(myModel,XMC);% If R is not provided, only a single run will be performed for each value of x

% plot the full histogram of Y (aggregating all the randomness)
uq_figure;
uq_histogram(squeeze(Yresp4(:,1,:)),'FaceColor', myColors(1,:),'normalized','pdf');
title('Aggregated response histogram')
xlabel('$Y$')