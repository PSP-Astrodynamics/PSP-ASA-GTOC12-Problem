%% RBDO: BRACKET STRUCTURE
%
% This example showcases the application of two-level reliability-based 
% design optimization (RBDO) techniques using different reliability
% analysis and optimization algorithms.

%%
% In this example, a two-member bracket structure as illustrated in the
% figure below is considered.
% The structure is pin-joined at the point $B$.
% A load $P$ is applied to the horizontal member at a distance $L$ of its
% hinge.
% The RBDO problem aims at minimizing the weight of the bracket
% while ensuring that:
%
% * the maximum bending stress in the horizontal member is smaller
%   than the yield stress;
% * the  compression force in the member $AB$ is smaller than the critical
%   Euler force.
uq_figure
[I,~] = imread('Bracket_structure.png');
image(I)
axis equal
set(gca, 'visible', 'off')

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(1,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL

%% 2.1 Cost function
%
% The cost function is the weight of the structure which is given by:
%
% $$ c(\mathbf{d}) = \rho t L ( \frac{4 \sqrt{3}}{9} w_{AB} + w_{CD} ) $$
%
% where $\mathbf{d} = \left\{w_{AB}, w_{CD}, t \right\}$ is a vector
% gathering the design parameters:
% the widths of members $AB$ and $CD$, respectively and
% their thickness,
% $L$ is the length of member $AB$,
% and $\rho$ is the constitutive material weight density.
%
% The computation is carrried out by the function
% |uq_bracketstructure_cost| supplied with UQLab.

%%
% Assign the function file to the RBDO options:
RBDOOpts.Cost.mFile = 'uq_bracketstructure_cost';

%% 2.2 Limit state function
%
% The optimization is carried out under the constraints that:
%
% * the maximum bending stress $\sigma_b$ in the member $AB$ is smaller
%   than the yield stress $\sigma_y$:
%
% $$ g_1(\mathbf{X}(\mathbf{d}),\mathbf{Z}) = \sigma_y - \sigma_b $$
%
% where $\sigma_b = \frac{6 M_B}{w_{CD} t^2}$ and $M_B = \frac{P L }{3} +
% \frac{\rho g w_{CD} t L^2}{18}$.
%
% * the  compression force in the member AB is smaller than the critical
%   Euler force
%
% $$ g_2(\mathbf{X}(\mathbf{d}),\mathbf{Z}) = F_b - F_{AB} $$
%
% where
% $F_b = \frac{\pi^2 E I }{L_{AB}}^2 = \frac{pi^2 E t
% w_{AB}^3}{12(2L/3sin^2\theta)^2}$ and 
% $F_{AB} = \frac{1}{\cos \theta}(\frac{3P}{2} + \frac{3 \rho g w_{CD} t
% L}{4})$.
%
% These two constraints are implemented in  the function
% |uq_bracketstructure_constraint| supplied with UQLab.

%%
% Create a MODEL object from the function file:
ModelOpts.mFile = 'uq_bracketstructure_constraint';
myModel = uq_createModel(ModelOpts);

%%
% Assign the model as limit-state for the RBDO problem:
RBDOOpts.LimitState.Model = myModel;

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of three random design
% and five random environmental variables.

%% 3.1 Design variables
%
% The design variables are considered random and follow a Gaussian
% distribution, the mean of which is the current design.
% The coefficient of variation is set to $5\%$. 

%%
% Define the design variables by specifying the distribution
% and the coefficients of variation:
RBDOOpts.Input.DesVar(1).Name = '$w_{ab}$';
RBDOOpts.Input.DesVar(1).Type = 'Gaussian';
RBDOOpts.Input.DesVar(1).CoV = 0.05;

RBDOOpts.Input.DesVar(2).Name = '$w_{cd}$';
RBDOOpts.Input.DesVar(2).Type = 'Gaussian';
RBDOOpts.Input.DesVar(2).CoV = 0.05;

RBDOOpts.Input.DesVar(3).Name = '$t$';
RBDOOpts.Input.DesVar(3).Type = 'Gaussian';
RBDOOpts.Input.DesVar(3).CoV = 0.05;

%% 3.2 Environmental variables
%
% The five environmental variables are described in the table below.

%%
% <html>
% <table border=1><tr>
% <td><b>Variable</b></td>
% <td><b>Description</b></td>
% <td><b>Distribution</b></td>
% <td><b>Mean</b></td>
% <td><b>Coef. of variation</b></td></tr>
% <tr>
% <td>P</td>
% <td>Applied load (in kN)</td>
% <td>Gumbel</td>
% <td>100 </td>
% <td>0.15 </td>
% </tr>
% <tr>
% <td>E</td>
% <td>Young's modulus (in GPa)</td>
% <td>Gumbel</td>
% <td>200</td>
% <td>0.08</td>
% </tr>
% <tr>
% <td>fy</td>
% <td>Yield stress (in MPa)</td>
% <td>Lognormal</td>
% <td>225</td>
% <td>0.08</td>
% </tr>
% <tr>
% <td>rho</td>
% <td>Unit mass (in kg/m3)</td>
% <td>Weibull</td>
% <td>7860</td>
% <td>0.10</td>
% </tr>
% <tr>
% <td>L</td>
% <td>Length (in m)</td>
% <td>Normal</td>
% <td>5</td>
% <td>0.05</td>
% </tr>
% </table>
% </html>

%%
% Define an INPUT object for the environmental variables:
InputOpts.Marginals(1).Name = 'P';
InputOpts.Marginals(1).Type = 'Gumbel';
InputOpts.Marginals(1).Moments = [100 0.15*100];

InputOpts.Marginals(2).Name = 'E';
InputOpts.Marginals(2).Type = 'Gumbel';
InputOpts.Marginals(2).Moments = [200 0.08*200];

InputOpts.Marginals(3).Name = 'fy';
InputOpts.Marginals(3).Type = 'Lognormal';
InputOpts.Marginals(3).Moments = [225 0.08*225];

InputOpts.Marginals(4).Name = 'rho';
InputOpts.Marginals(4).Type = 'Weibull';
InputOpts.Marginals(4).Moments = [7860 0.10*7860];

InputOpts.Marginals(5).Name = 'L';
InputOpts.Marginals(5).Type = 'Gaussian';
InputOpts.Marginals(5).Moments = [5 0.05*5];

%%
% Create an INPUT object based on the specified marginals:
myInput = uq_createInput(InputOpts);

%%
% Associate the INPUT object to the RBDO analysis:
RBDOOpts.Input.EnvVar = myInput;

%% 4 - OPTIMIZATION SETUP
%
% To specify the optimization problem,
% first define the bounds of the search (or design) space.
% Here the design space is the hypercube ${D} = [5,30]^3$:
RBDOOpts.Optim.Bounds = [5 5 5; 30 30 30];

%%
% Optionally, the starting point for the optimization algorithm
% can also be provided:
RBDOOpts.Optim.StartingPoint = [10 10 25];

%% 
% Set the target reliability index to $\bar{\beta} = 2$
% (this corresponds to $\bar{P}_f = 0.0228$):
RBDOOpts.TargetBeta = 2;

%% 5 - RELIABILITY-BASED DESIGN OPTIMIZATION (RBDO)
%
% RBDO is now performed using different two-level approaches
% with a combination of the following reliability analysis methods and 
% optimization algorithms:
%
% * Monte Carlo simulation (MCS) in the inner loop
%   with the constrained CMAES (CCMAES).
%   This combination is the default two-level approach
% * Quantile Monte Carlo (QMC) with interior point (IP)
% * Inverse first-order reliability method (FORM)
%   with sequential quadratic programming (SQP)

%%
% Select the RBDO module and the two-level approach:
RBDOOpts.Type = 'RBDO';
RBDOOpts.Method = 'two-level';

%% 5.1 Monte Carlo simulation (MCS) with CCMAES
%
% By default, the two-level approach assumes Monte Carlo simulation (MCS)
% in the inner loop and constrained (1+1)-CMA-ES as the optimizer:
MCCOpts = RBDOOpts;

%%
% Set the maximum sample size for the MCS:
MCCOpts.Reliability.Simulation.MaxSampleSize = 5e4;

%%
% Set the maximum number of iterations:
MCCOpts.Optim.MaxIter = 350;

%%
% Run the RBDO analysis:
myRBDO_MCC = uq_createAnalysis(MCCOpts);

%%
% Print out a report of the results:
uq_print(myRBDO_MCC)

%%
% Display a graphical representation of the results:
uq_display(myRBDO_MCC)

%% 5.2 Quantile Monte Carlo (QMC) with IP
%
% Select QMC as the RBDO method and IP as the optimization method:
QIPOpts = RBDOOpts;
QIP.Method = 'QMC';
QIPOpts.Optim.Method = 'IP';

%%
% Set the maximum number of iterations:
QIPOpts.Optim.MaxIter = 100;

%%
% Set the finite difference step size:
QIPOpts.Optim.IP.FDStepSize = 0.1;

%%
% Set the maximum sample size:
QIPOpts.Reliability.Simulation.MaxSampleSize = 1e4;

%%
% Run the RBDO analysis:
myRBDO_QIP = uq_createAnalysis(QIPOpts);

%%
% Print out a report of the results:
uq_print(myRBDO_QIP)

%%
% Display a graphical representation of the results:
uq_display(myRBDO_QIP)

%% 5.3 Inverse FORM with SQP
%
% Select inverse FORM as the RBDO method
% and SQP as the optimization method:
IFSOpts = RBDOOpts;
IFSOpts.Reliability.Method = 'IFORM';
IFSOpts.Optim.Method = 'SQP';

%%
% Set the maximum number of iterations:
IFSOpts.Optim.MaxIter = 100;

%%
% Set the finite difference step size:
IFSOpts.Optim.SQP.FDStepSize = 0.1;

%%
% Run the RBDO analysis:
myRBDO_IFS = uq_createAnalysis(IFSOpts);

%%
% Print out a report of the results:
uq_print(myRBDO_IFS)

%%
% Display a graphical representation of the results:
uq_display(myRBDO_IFS)
