%% PCE METAMODELING: ESTIMATION OF STATISTICAL MOMENTS
%
% This example showcases an application of sparse
% polynomial chaos expansion (PCE) to the estimation of
% the statistical moments of a computational model with random inputs.
% The model is a simply supported beam model that computes
% deflections at mid-span of a beam subjected to a uniform random load.
% The convergence behavior of the PCE-based and pure Monte-Carlo-based 
% estimation of the statistical moments is compared.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The simply supported beam model is shown in the following figure:
uq_figure
[I,~] = imread('SimplySupportedBeam.png');
image(I)
axis equal
set(gca,'visible','off')

%% 
% The forward model computes the deflection of the beam $V$
% at mid-span location, which reads:
%
% $$ V = \frac{ 5 p L^4 }{32 E b h^3}$$
%
% This computation is carried out by the function
% |uq_SimplySupportedBeam(X)| supplied with UQLab.
% The input variables of this function are gathered into the $N \times M$
% matrix |X|, where $N$ and $M$ are the numbers of realizations
% and input variables, respectively.
% The input variables are given in the following order:
%
% # $b$: beam width $(m)$
% # $h$: beam height $(m)$
% # $L$: beam length $(m)$
% # $E$: Young's modulus $(MPa)$
% # $p$: uniform load $(kN/m)$

%%
% Create a MODEL object from the function:
ModelOpts.mFile = 'uq_SimplySupportedBeam';
ModelOpts.isVectorized = true;

myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The simply supported beam model has five inputs,
% modeled by independent lognormal random variables.
% The detailed model is given in the following table:

%%
% <html>
% <table border=1><tr>
% <td><b>Variable</b></td>
% <td><b>Description</b></td>
% <td><b>Distribution</b></td>
% <td><b>Mean</b></td>
% <td><b>Std. deviation</b></td></tr>
% <tr>
% <td>b</td>
% <td>Beam width</td>
% <td>Lognormal</td>
% <td>0.15 m</td>
% <td>7.5 mm</td>
% </tr>
% <tr>
% <td>h</td>
% <td>Beam height</td>
% <td>Lognormal</td>
% <td>0.3 m</td>
% <td>15 mm</td>
% </tr>
% <tr>
% <td>L</td>
% <td>Length</td>
% <td>Lognormal</td>
% <td>5 m</td>
% <td>50 mm</td>
% </tr>
% <tr>
% <td>E</td>
% <td>Young modulus</td>
% <td>Lognormal</td>
% <td>30000 MPa</td>
% <td>4500 MPa</td>
% </tr>
% <tr>
% <td>p</td>
% <td>Uniform load</td>
% <td>Lognormal</td>
% <td>10 kN/m</td>
% <td>2 kN/m</td>
% </tr>
% </table>
% </html>

%%
% Define an INPUT object with the following marginals:
Input.Marginals(1).Name = 'b'; % beam width
Input.Marginals(1).Type = 'Lognormal';
Input.Marginals(1).Moments = [0.15 0.0075]; % (m)

Input.Marginals(2).Name = 'h'; % beam height
Input.Marginals(2).Type = 'Lognormal';
Input.Marginals(2).Moments = [0.3 0.015]; % (m)

Input.Marginals(3).Name = 'L'; % beam length
Input.Marginals(3).Type = 'Lognormal';
Input.Marginals(3).Moments = [5 0.05]; % (m)

Input.Marginals(4).Name = 'E'; % Young's modulus
Input.Marginals(4).Type = 'Lognormal';
Input.Marginals(4).Moments = [3e10 4.5e9]; % (Pa)

Input.Marginals(5).Name = 'p'; % uniform load
Input.Marginals(5).Type = 'Lognormal';
Input.Marginals(5).Moments = [1e4 2e3]; % (N/m)

%%
% Create the INPUT object:
myInput = uq_createInput(Input);

%% 4 - POLYNOMIAL CHAOS EXPANSION (PCE) METAMODEL
%
% Select PCE as the metamodeling tool:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'PCE';

%%
% Select the sparse-favouring least-square minimization LARS
% for the coefficient calculation strategy:
MetaOpts.Method = 'LARS';

%% 
% Specify a sparse truncation scheme (hyperbolic norm with $q = 0.75$):
MetaOpts.TruncOptions.qNorm = 0.75;

%%
% Specify the range of the degrees to be compared
% by the adaptive algorithm:
MetaOpts.Degree = 2:10;
%%
% The degree with the lowest Leave-One-Out cross-validation (LOO)
% error estimator is chosen as the final metamodel.

%% 5 - MONTE-CARLO- VS PCE-BASED ESTIMATION OF MOMENTS
%
% The moments of a PCE can be analytically calculated
% from its coefficients without additional sampling.
% In this section, the mean and standard deviation estimates obtained
% from Monte-Carlo (MC) samples of increasing size are compared to the ones
% based on the PCE of the same samples.
%
% The simply supported beam model with lognormal input distributions allows
% for the explicit calculation of mean and standard deviation, which are
% provided for reference:
mean_exact = 0.008368320689566;
std_exact = 0.002538676671701;

%%
% Specify a set of experimental design sizes to test:
NED = [50 100 150 200 500];

%%
% Initialize the arrays in which the results will be stored:
mean_MC = zeros(size(NED));
std_MC = zeros(size(NED));
mean_PCE = zeros(size(NED));
std_PCE = zeros(size(NED));

%% 
% Loop over the experimental design sizes. In each step, generate an 
% experimental design, create a PCE metamodel,
% and compute the corresponding mean and standard deviation:
for ii = 1: length(NED)
    
    % Get a sample from the probabilistic input model with LHS sampling
    X_ED = uq_getSample(NED(ii),'LHS');
    
    % Evaluate the full model on the current experimental design
    Y_ED = uq_evalModel(myModel,X_ED);
    
    % Calculate the moments of the experimental design
    mean_MC(ii) = mean(Y_ED);
    std_MC(ii) = std(Y_ED, 0, 1);
    
    % Use the sample as the experimental design for the PCE
    MetaOpts.ExpDesign.X = X_ED;
    MetaOpts.ExpDesign.Y = Y_ED;
    
    % Create and add the PCE metamodel to UQLab
    myPCE = uq_createModel(MetaOpts);
    
    % Calculate the mean and standard deviation from the PCE coefficients
    mean_PCE(ii) = myPCE.PCE.Moments.Mean;
    std_PCE(ii) = sqrt(myPCE.PCE.Moments.Var);

end

%% 6 - CONVERGENCE PLOTS
%
% Plot the convergence of the mean estimates from MCS and PCE:
uq_figure

cmap = uq_colorOrder(2);
uq_plot(NED, abs(mean_MC/mean_exact-1), '-', 'Color', cmap(1,:))
hold on
uq_plot(NED, abs(std_MC/std_exact-1), '--', 'Color', cmap(1,:))
uq_plot(NED, abs(mean_PCE/mean_exact-1), '-', 'Color', cmap(2,:))
uq_plot(NED, abs(std_PCE/std_exact - 1), '--', 'Color', cmap(2,:))
set(gca, 'YScale', 'log')
hold off

ylim([1e-8 1])
xlim([NED(1) NED(end)])
xlabel('$\mathrm N$')
uq_legend({'$\mathrm{|\hat{\mu}_Y^{MC} / \mu_Y - 1 |}$',...
    '$\mathrm{|\hat{\sigma}_Y^{MC} / \sigma_Y - 1 |}$', ...
    '$\mathrm{|\hat{\mu}_Y^{PC} / \mu_Y - 1 |}$', ...
    '$\mathrm{|\hat{\sigma}_Y^{PC} / \sigma_Y - 1 |}$'}, ...
    'Location', 'southwest')
