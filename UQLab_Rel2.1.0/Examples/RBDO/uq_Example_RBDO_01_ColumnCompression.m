%% RBDO: COLUMN UNDER COMPRESSION
%
% This example showcases the application of different reliability-based
% design optimization (RBDO) methods available in UQLab for the solution
% of a column under compression problem.

%%
% The RBDO problem features a column of rectangular cross section submitted 
% to a compressive load $F_{ser}$.
% The problem consists in minimizing its cross-sectional area $b \times h$
% while avoiding buckling which would occur if the service load $F_{ser}$ 
% is larger than the critical Euler load.
% The latter reads:
%
% $$F_{cr} = k \frac{\pi^2 E b h^3}{12 L^2}$$
%
% where:
%
% * $k$ is a multiplicative parameter accounting for noise
%   that may affect the Euler force
% * $L$ is the length of the column
% * $E$ is the column constitutive material Young's modulus

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(1,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The limit state function is defined by the following function:
%
% $$g(\mathbf{d,Z}) = k \frac{\pi^2 E b h^3}{12 L^2} - F_{ser}$$
%
% where $\mathbf{d} = \{b,h\}$ are the deterministic design parameters and 
% $\mathbf{Z} = \{k, E, L\}$ are the random environmental variables.
%
% The computation of the limit state function is carried out
% by the function |uq_columncompression_constraint| supplied with UQLab.

%%
% Create a MODEL object for the constraint (limit state) function model 
% using the function file:
ModelOpts.mFile = 'uq_columncompression_constraint';

myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The environmental variables are modeled probalistically using three
% independent random variables.
%
% Specify the marginals each of which follows a lognormal distribution:
InputOpts.Marginals(1).Name = 'k' ;  % the multiplicative parameter
InputOpts.Marginals(1).Type = 'Lognormal';
InputOpts.Marginals(1).Moments = [0.6 0.1*0.6];

InputOpts.Marginals(2).Name = 'E';  % Young's modulus of the column
InputOpts.Marginals(2).Type = 'Lognormal';
InputOpts.Marginals(2).Moments = [1e4 0.05*1e4];

InputOpts.Marginals(3).Name = 'L';  % length of the column
InputOpts.Marginals(3).Type = 'Lognormal';
InputOpts.Marginals(3).Moments = [3e3 0.01*3e3];

%%
% Create an INPUT object based on the specified marginals:
myInput = uq_createInput(InputOpts);

%% 4 - RELIABILITY-BASED DESIGN OPTIMIZATION (RBDO) SETUP

%% 4.1 Design and environmental variables
%
% The probabilistic input model consists of two deterministic design
% parameters and three random environmental variables.
%
% Specify the design variables:
RBDOOpts.Input.DesVar(1).Name = 'b';
RBDOOpts.Input.DesVar(1).Type = 'constant';
RBDOOpts.Input.DesVar(2).Name = 'h';
RBDOOpts.Input.DesVar(2).Type = 'constant';

%%
% Specify the INPUT object used for the environmental variables:
RBDOOpts.Input.EnvVar = myInput;


%% 4.2 Cost function
%
% The cost function reads:
%
% $$c(\mathbf{d}) = b h$$
%
% Create a cost function model using a Matlab string (X(1) is b and X(2) is h):
RBDOOpts.Cost.mString = 'X(:,1) .* X(:,2)';

%% 4.3 Hard constraint
%
% The limit state function corresponds to the predefined computational
% model. 
%
% Assign this to the RBDO analysis options:
RBDOOpts.LimitState.Model = myModel;

%% 4.4 Soft constraint
%
% In this example, a soft constraint is also considered.
% A solution is admissible only when $b < h$.
%
% Create a soft constraint function using a string (understood as X(2)-X(1)>0)
RBDOOpts.SoftConstraints.mString = 'X(:,2) - X(:,1)';

%% 4.5 Optimization setting
%
% To specify the optimization problem,
% the bounds of the design space are first defined as follows:
RBDOOpts.Optim.Bounds = [150 150; 350 350];

%%
% Optionally, the starting point for the optimization algorithm
% can also be provided:
RBDOOpts.Optim.StartingPoint = [350 300];

%%
% Then, define the target failure probability:
RBDOOpts.TargetPf = 0.05;

%% 5 - RELIABILITY-BASED DESIGN OPTIMIZATION (RBDO)
%
% RBDO is performed using the following approaches:
%
% * Reliability index approach (RIA)
% * Performance measure approach (PMA)
% * Sequential optimization and reliability assessment (SORA)
% * Single loop optimization (SLA)
% * Two-level approach with Monte Carlo simulation (MCS)
% * Quantile Monte Carlo (QMC)

%% 5.1 Reliability index approach (RIA)
%
% Select RIA to solve the RBDO problem:
RIAOpts = RBDOOpts;
RIAOpts.Type = 'RBDO';
RIAOpts.Method = 'RIA';

%%
% Run the RBDO analysis:
myRBDO_RIA = uq_createAnalysis(RIAOpts) ;

%%
% Print out a report of the results:
uq_print(myRBDO_RIA)

%%
% Display a graphical representation of the results:
uq_display(myRBDO_RIA)

%% 5.2 Performance measure approach (PMA)
%
% Select PMA to solve the RBDO problem:
PMAOpts = RBDOOpts;
PMAOpts.Type = 'RBDO';
PMAOpts.Method = 'PMA';

%%
% Run the RBDO analysis:
myRBDO_PMA = uq_createAnalysis(PMAOpts) ;

%%
% Print out a report of the results:
uq_print(myRBDO_PMA)

%%
% Display a graphical representation of the results:
uq_display(myRBDO_PMA)

%% 5.3 Sequential optimization and reliability assessment (SORA)
%
% Select SORA to solve the RBDO problem:
SORAOpts = RBDOOpts;
SORAOpts.Type = 'RBDO';
SORAOpts.Method = 'SORA';

%%
% Run the RBDO analysis:
myRBDO_SORA = uq_createAnalysis(SORAOpts) ;

%%
% Print out a report of the results:
uq_print(myRBDO_SORA)

%%
% Display a graphical representation of the results:
uq_display(myRBDO_SORA)

%% 5.4 Single loop approach (SLA)
%
% Select SLA to solve the RBDO problem:
SLAOpts = RBDOOpts;
SLAOpts.Type = 'RBDO';
SLAOpts.Method = 'SLA';

%%
% Run the RBDO analysis:
myRBDO_SLA = uq_createAnalysis(SLAOpts);

%%
% Print out a report of the results:
uq_print(myRBDO_SLA)

%%
% Display a graphical representation of the results:
uq_display(myRBDO_SLA)

%% 5.5 Two-level approach with Monte Carlo simulation
%
% Select the generalized two-level approach to solve the RBDO problem: 
TLOpts = RBDOOpts ;
TLOpts.Type = 'RBDO';
TLOpts.Method = 'two-level';
%%
% By default:
% * the optimizer is the constrained (1+1)-CMA-ES
% * the reliability analysis (in the inner loop) is carried out using Monte
%   Carlo simulation

%%
% Run the RBDO analysis:
myRBDO_TL = uq_createAnalysis(TLOpts);

%%
% Print out a report of the results:
uq_print(myRBDO_TL)

%%
% Create a graphical representation of the results:
uq_display(myRBDO_TL)

%% 5.6 Quantile Monte Carlo (QMC) approach
%
% Select QMC as the RBDO method:
QMCOpts = RBDOOpts;
QMCOpts.Type = 'RBDO';
QMCOpts.Method = 'QMC';

%%
% Run the RBDO analysis:
myRBDO_QMC = uq_createAnalysis(QMCOpts) ;

%%
% Print out a report of the results:
uq_print(myRBDO_QMC)

%%
% Display a graphical representation of the results:
uq_display(myRBDO_QMC)
