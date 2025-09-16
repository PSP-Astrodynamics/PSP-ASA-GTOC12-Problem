%% RELIABILITY: PARALLEL SYSTEM
%
% In this example, the failure probability of a parallel system is
% computed using a plain Monte Carlo simulation (MCS)
% and the First-Order Reliability Method (FORM).
% The results are then compared.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace,
% set the random number generator for reproducible results,
% and initialize the UQLab framework:
clearvars
rng(2,'twister')
uqlab

%% 2 - COMPUTATIONAL MODELS
%
% The parallel system consists of two two-dimensional Resistance-Stress
% (R-S) limit state functions that are defined as follows:
%
% $$
% g_1(r, s) = 1.2 r - 0.9 s; \quad g_2(r, s) = r - s
% $$
%
% Create two MODEL objects based on the limit state functions
% using string with vectorized operation:
Model1Opts.mString = '1.2*X(:,1) - 0.9*X(:,2)';
Model1Opts.isVectorized = true;
myLimitState1 = uq_createModel(Model1Opts);

Model2Opts.mString = 'X(:,1) - X(:,2)';
Model2Opts.isVectorized = true; 
myLimitState2 = uq_createModel(Model2Opts);

%%
% The full parallel system limit state function can be calculated 
% by just taking the maximum of the two limit state functions:
ModelFullOpts.mString = 'max(X(:,1) - X(:,2), 1.2*X(:,1) - 0.9*X(:,2))';
ModelFullOpts.isVectorized = true; 
myLimitStateFull = uq_createModel(ModelFullOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of two independent 
% Gaussian random variables:
%
% $$
% R \sim \mathcal{N} (3, 0.3),\, S \sim \mathcal{N} (2, 0.4)
% $$
%
% Specify the marginals of the two input random variables:
InputOpts.Marginals(1).Name = 'R';
InputOpts.Marginals(1).Type = 'Gaussian';
InputOpts.Marginals(1).Moments = [3 0.3];

InputOpts.Marginals(2).Name = 'S';
InputOpts.Marginals(2).Type = 'Gaussian';
InputOpts.Marginals(2).Moments = [2 0.4];

%%
% Create an INPUT object based on the specified marginals:
myInput = uq_createInput(InputOpts);

%% 4 - RELIABILITY ANALYSIS
%
% Failure event is defined as $g(\mathbf{x}) \leq 0$.
% The failure probability is then defined as
% $P_f = P[g(\mathbf{x}) \leq 0]$.
%
%% 4.1 Monte Carlo simulation (MCS)
%
% Select the Reliability module and the Monte Carlo simulation (MCS)
% method:
MCSOpts.Type = 'Reliability';
MCSOpts.Method = 'MCS';

%%
% MCS is performed on the full parallel system limit state function.
% Select the function:
uq_selectModel(myLimitStateFull)

%%
% Specify the maximum sample size:
MCSOpts.Simulation.MaxSampleSize = 2e6;

%%
% Run the Monte Carlo simulation:
myMCSAnalysis = uq_createAnalysis(MCSOpts);

%%
% Store the probality of failure in a variable:
Pf_MC = myMCSAnalysis.Results.Pf;

%% 4.2 First-order reliability method (FORM)
%
% Select the Reliability module and the FORM method:
FORMOpts.Type = 'Reliability';
FORMOpts.Method = 'FORM';

%%
% FORM is performed on each component of the system.
% First, select the first component (i.e., the first limit state function):
uq_selectModel(myLimitState1)

%%
% Run the FORM analysis on the first limit state function:
myFORMAnalysis1 = uq_createAnalysis(FORMOpts);

%%
% Then, perform the FORM analysis on the second limit state function:
uq_selectModel(myLimitState2)
myFORMAnalysis2 = uq_createAnalysis(FORMOpts);

%%
% Retrieve the reliability index of each component:
betaHL1 = myFORMAnalysis1.Results.BetaHL;
betaHL2 = myFORMAnalysis2.Results.BetaHL;

%%
% Calculate the unit vectors ($\alpha$) in the direction
% of the design point for each system component:
alpha1 = myFORMAnalysis1.Results.Ustar / betaHL1; 
alpha2 = myFORMAnalysis2.Results.Ustar / betaHL2;

%%
% The failure probability of the parallel system is calculated by:
%
% $$P_f = \Phi_2(-\beta, 0, R),$$
%
% where $\Phi_2$ is a bivariate Gaussian distribution, with zero mean,
% unit variance, and correlation matrix $R$, evaluated at point $-\beta$.
%
% The correlation matrix $R$ is defined as follows:
%
% $$R= \left[\matrix{ 1 & \alpha_1 \cdot \alpha_2 \cr
% \alpha_1 \cdot \alpha_2 & 1} \right]$$
%
% Finally, the failure probability based on the FORM method
% is computed as follows:
B = [betaHL1; betaHL2];
R = [ 1 alpha1*alpha2'; alpha1*alpha2' 1];
Pf_FORM = mvncdf(-B, [0; 0], R);

%%
% For more details about the derivation of the formula see, for example,
% Chapter 15 of Engineering Design Reliability Handbook, CRC Press 2004.

%% 5 - RESULTS COMPARISON
%
% Compare the failure probabilities obtained by the MCS and FORM:
fprintf('Results:\n Pf[MC]   = %.3e\n Pf[FORM] = %.3e\n', Pf_MC, Pf_FORM)
