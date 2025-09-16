function success = uq_rbdo_test_MultipleOutputs(level)
% SUCCESS = UQ_RBDO_TEST_MULTIPLEOUTPUTS(LEVEL):
%     Testing rbdo from problems with multiple outputs
%
% See also UQ_SELFTEST_UQ_RBDO

uqlab('-nosplash');
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);

success = 1;

% Set seed for reproducibility (Shall we actually?)
rng(1) ;

% allowed error
eps = 1e-2;


%% Reference solution can be computed analytically
% Reference solution computed using double-loop with QMC & IP (regression test)
Fstar = 1370 ;

%% Set up the RBDO problem
% Set anayslsis method to RBDO
RBDopt.Type = 'rbdo' ;
% % Enable display
% RBDopt.Display = 'verbose' ;

%% 2 - Cost function
RBDopt.Cost.mFile = 'uq_bracketstructure_cost';

%% 3 - Computational model / constraints
% Hard constraint
MOpts.mFile = 'uq_bracketstructure_constraint';
myModel = uq_createModel(MOpts,'-private') ;


%% 4 - Probabilistic model
% Note that the inputs are slightly different from the original problem.
% Here we take everything Gaussian as that is the optimal form for SORA and
% SLA. We are only trying to figure out if the methods work for
% multi-output problems, using non-Gaussian distributions would test
% another weakness of 
% Design variables
RBDopt.Input.DesVar(1).Name = '$w_{ab}$';
RBDopt.Input.DesVar(1).Type = 'Gaussian';
RBDopt.Input.DesVar(1).CoV = 0.05;

RBDopt.Input.DesVar(2).Name = '$w_{cd}$';
RBDopt.Input.DesVar(2).Type = 'Gaussian';
RBDopt.Input.DesVar(2).CoV = 0.05;

RBDopt.Input.DesVar(3).Name = '$t$';
RBDopt.Input.DesVar(3).Type = 'Gaussian';
RBDopt.Input.DesVar(3).CoV = 0.05;

%%
% Define an INPUT object for the environmental variables:
InputOpts.Marginals(1).Name = 'P';
InputOpts.Marginals(1).Type = 'Gaussian';
InputOpts.Marginals(1).Moments = [100 0.15*100];

InputOpts.Marginals(2).Name = 'E';
InputOpts.Marginals(2).Type = 'Gaussian';
InputOpts.Marginals(2).Moments = [200 0.08*200];

InputOpts.Marginals(3).Name = 'fy';
InputOpts.Marginals(3).Type = 'Gaussian';
InputOpts.Marginals(3).Moments = [225 0.08*225];

InputOpts.Marginals(4).Name = 'rho';
InputOpts.Marginals(4).Type = 'Gaussian';
InputOpts.Marginals(4).Moments = [7860 0.10*7860];

InputOpts.Marginals(5).Name = 'L';
InputOpts.Marginals(5).Type = 'Gaussian';
InputOpts.Marginals(5).Moments = [5 0.05*5];

myInput = uq_createInput(InputOpts, '-private');

RBDopt.Input.EnvVar = myInput ;

%% 5 - Optimization problem
%
% Design space bounds
RBDopt.Optim.Bounds = [5 5 5; 30 30 30];

%%
% Starting point for optimization
RBDopt.Optim.StartingPoint = [6 8 30];

%% 
% Target reliability index 
RBDopt.TargetBeta = 2;

% Limit-state surface 
RBDopt.LimitState.Model =  myModel ;

% %% RIA
RBDopt.Method = 'ria' ;

myRBDOria = uq_createAnalysis(RBDopt,'-private') ;
%% PMA
RBDopt.Method = 'pma' ;
myRBDOpma = uq_createAnalysis(RBDopt,'-private') ;

%% SOR
RBDopt.Method = 'sora' ;
myRBDOsora = uq_createAnalysis(RBDopt,'-private') ;

%% SLA
RBDopt.Method = 'sla' ;
myRBDOsla = uq_createAnalysis(RBDopt,'-private') ;

%% Two-level with MCS
RBDopt.Method = 'two-level' ;
myRBDOtlmc = uq_createAnalysis(RBDopt,'-private') ;

success = success & abs((Fstar - myRBDOria.Results.Fstar)/Fstar) < eps ;
success = success & abs((Fstar - myRBDOpma.Results.Fstar)/Fstar) < eps ;
success = success & abs((Fstar - myRBDOsora.Results.Fstar)/Fstar) < eps ;
success = success & abs((Fstar - myRBDOsla.Results.Fstar)/Fstar) < eps ;
success = success & abs((Fstar - myRBDOtlmc.Results.Fstar)/Fstar) < eps ;


end