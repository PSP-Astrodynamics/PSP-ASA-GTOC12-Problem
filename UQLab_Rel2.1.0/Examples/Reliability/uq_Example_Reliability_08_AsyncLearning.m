%% RELIABILITY: ASYNCHRONOUS ACTIVE LEARNING
% 
% This example showcases asynchronous learning in UQLab. This feature is
% useful when the user wishes to carry out the required model evaluations
% outside of UQLab.
%
% In this example, active learning is carried out without the definition of
% a computational model. UQLab therefore only returns the model evaluations
% required to enrich the experimental design, without executing them. The
% user can perform their evaluation outside UQLab and/or Matlab, and resume
% the analysis once they become available. 

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace,
% set the random number generator for reproducible results
% and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2- PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of two independent
% and identically-distributed standard Gaussian random variables:
%
% $X_i \sim \mathcal{N}(0, 1), \quad i = 1, 2$
%
% Specify the probabilistic model for the two input random variables:
InputOpts.Marginals(1).Name = 'X1'; 
InputOpts.Marginals(1).Type = 'Gaussian';
InputOpts.Marginals(1).Parameters = [0 1];
InputOpts.Marginals(2).Name = 'X2';  
InputOpts.Marginals(2).Type = 'Gaussian';
InputOpts.Marginals(2).Parameters = [0 1];

myInput = uq_createInput(InputOpts);

%% 3 - STRUCTURAL RELIABILITY%
% Failure event is defined as $g(\mathbf{x}) \leq 0$.
% The failure probability is then defined as
% $P_f = P[g(\mathbf{x})\leq 0]$.
%
% In this example, the limit-state function g is not defined in UQLab.
% Instead, the samples to evaluate to enrich the experimental design
% $x^\ast$ are returned by the active learning algorithm. The user then
% evaluates them externally before resuming the analysis. For illustration
% purposes, only 3 iterations of the algorithm are performed here. 


%% 3.1 - Initial set-up
% Select the Reliability module and the active learning method:

ALROptions.Type = 'Reliability';
ALROptions.Method = 'ALR';

%%
% Specify the size of the iniitial experimental design
ALROptions.ALR.IExpDesign.N = 4 ;

%%
% Enable the asynchronous learning  feature
ALROptions.Async.Enable = true ;

%%
% Allow asyncrhonous learning also for the initial experimental design
ALROptions.Async.InitED = true ;

%%
% Run the active learning reliability analysis:
myALRAnalysis = uq_createAnalysis(ALROptions);

%%
% The execution stops right before the initial experimental design is
% evaluated

%% 3.2 - Evaluating the initial ED
% This first set of samples consists in the 5 initial experimental design
% points.  
% They are saved in  |.Results.NextSample|. 
Xnext = myALRAnalysis.Results.NextSample ;
Ynext = 2.5 - (Xnext(:,1)+ Xnext(:,2))/sqrt(2) + 0.1 * (Xnext(:,1) - Xnext(:,2)).^2 ;

%%
% Resume the analysis by submitting the newly evaluated samples
myALRAnalysis = uq_resumeAnalysis(Ynext);

%% 3.3 - Resuming the analysis
% The next sample is retrieved and evaluted again
Xnext = myALRAnalysis.Results.NextSample ;
Ynext = 2.5 - (Xnext(:,1)+ Xnext(:,2))/sqrt(2) + 0.1 * (Xnext(:,1) - Xnext(:,2)).^2 ;

%%
%Resume the analysis by submitting the newly evaluated samples
myALRAnalysis = uq_resumeAnalysis(Ynext);

%%
% Retrieve the next sample to evalute
Xnext = myALRAnalysis.Results.NextSample ;
Ynext = 2.5 - (Xnext(:,1)+ Xnext(:,2))/sqrt(2) + 0.1 * (Xnext(:,1) - Xnext(:,2)).^2 ;

%% 3.4 - Using the analysis snapshot
% When an analysis is run with the asynchronous feature enabled, a snapshot
% of the analysis is always saved locally in a .mat file. This file can be
% retrieved and loaded to resume the anaylsis even if the user closed
% Matlab, cleared the workspace or reinitialized UQLab.

%%
% Get the Matlab file of the latest snapshot:
LatestSnapshot = myALRAnalysis.Results.Snapshot 

%%
% Resume the analysis using the snapshot file
myALRAnalysis = uq_resumeAnalysis(LatestSnapshot, Ynext );

%%
% In this example, convergence has not yet been achieved. However, it is
% possible to print and display the current state of the analysis.

%%
% Print out a summary of the results
uq_print(myALRAnalysis) ;

%%
% Visualize the results of the analysis
uq_display(myALRAnalysis) ;
