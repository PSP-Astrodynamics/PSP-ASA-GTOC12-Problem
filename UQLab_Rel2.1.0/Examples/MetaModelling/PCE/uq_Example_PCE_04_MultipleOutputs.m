%% PCE METAMODELING: MULTIPLE OUTPUTS
%
% This example showcases an application of polynomial chaos expansion
% (PCE) to the metamodeling of a simply supported beam model
% with multiple outputs.
% The model computes the deflections at several points along the length 
% of the beam subjected to a uniform random load.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The simply supported beam problem is shown in the following figure:
uq_figure
[I,~] = imread('SimplySupportedBeam.png');
image(I)
axis equal
set(gca, 'visible', 'off');

%% 
% The (negative) deflection of the beam at any longitudinal coordinate
% $s$ is given by:
%
% $$V(s) = -\frac{p \,s (L^3 - 2\, s^2 L + s^3) }{2E b h^3}$$
%
% This computation is carried out by the function
% |uq_SimplySupportedBeam9Points(X)| supplied with UQLab.
% The function evaluates the inputs gathered in the $N \times M$
% matrix |X|, where $N$ and $M$ are the numbers of realizations
% and input variables, respectively.
% The input variables are given in the following order:
%
% # $b$: beam width $(m)$
% # $h$: beam height $(m)$
% # $L$: beam length $(m)$
% # $E$: Young's modulus $(Pa)$
% # $p$: uniform load $(N/m)$
%
% The function returns the beam deflection $V(s_i)$
% at nine equally-spaced points along the length
% $s_i = i \cdot L/10, \; i=1,\ldots,9.$ 
%
% Create a MODEL object from the |uq_SimplySupportedBeam9points| function:
ModelOpts.mFile = 'uq_SimplySupportedBeam9points';

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
Input.Marginals(1).Name = 'b';  % beam width
Input.Marginals(1).Type = 'Lognormal';
Input.Marginals(1).Moments = [0.15 0.0075];  % (m)

Input.Marginals(2).Name = 'h';  % beam height
Input.Marginals(2).Type = 'Lognormal';
Input.Marginals(2).Moments = [0.3 0.015];  % (m)

Input.Marginals(3).Name = 'L';  % beam length
Input.Marginals(3).Type = 'Lognormal';
Input.Marginals(3).Moments = [5 0.05];  % (m)

Input.Marginals(4).Name = 'E';  % Young's modulus
Input.Marginals(4).Type = 'Lognormal';
Input.Marginals(4).Moments = [3e10 4.5e9];  % (Pa)

Input.Marginals(5).Name = 'p';  % uniform load
Input.Marginals(5).Type = 'Lognormal';
Input.Marginals(5).Moments = [1e4 2e3];  % (N/m)

%%
% Create an INPUT object based on the defined marginals:
myInput = uq_createInput(Input);

%% 4 - POLYNOMIAL CHAOS EXPANSION (PCE) METAMODELS
%
% Select PCE as the metamodeling technique:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'PCE';

%%
% Select the sparse-favouring least-square minimization LARS for 
% the PCE coefficients calculation strategy:
MetaOpts.Method = 'LARS';

%% 
% Specify the sparse truncation scheme (hyperbolic norm with $q = 0.75$):
MetaOpts.TruncOptions.qNorm = 0.75;

%%
% Specify the range of degrees to be compared by the adaptive algorithm:
MetaOpts.Degree = 2:10;
%%
% The degree with the lowest Leave-One-Out cross-validation (LOO)
% error estimator is chosen as the final metamodel.

%%
% Least-square methods rely on the evaluation of the model response on an
% experimental design. The following options configure UQLab to generate an
% experimental design of size $150$ based on a latin hypercube sampling of
% the input model (also available: 'MC', 'Sobol', 'Halton'):
MetaOpts.ExpDesign.NSamples = 150;
MetaOpts.ExpDesign.Sampling = 'LHS';

%%
% Create the LARS-based PCE metamodel:
myPCE_LARS = uq_createModel(MetaOpts);

%% 
% Select the Orthogonal Matching Pursuit (OMP) least-square minimization
% to compare the results with LARS:
MetaOpts.Method = 'OMP'; 

%% 
% Use the same experimental design used for LARS:
MetaOpts.ExpDesign.Sampling = 'User';
MetaOpts.ExpDesign.X = myPCE_LARS.ExpDesign.X; 
MetaOpts.ExpDesign.Y = myPCE_LARS.ExpDesign.Y; 

%% 
% Create the OMP-based PCE metamodel:
myPCE_OMP = uq_createModel(MetaOpts); 

%% 5 - VALIDATION OF THE RESULTS
%
% The deflections $V(s_i)$ at the nine points are plotted
% for three realizations of the random inputs.
% Relative length units are used for comparison,
% because $L$ is one of the random inputs.

%% 5.1 Create and evaluate the validation set
%
% Generate a validation sample:
Nval = 3;
Xval = uq_getSample(Nval);

%%
% Evaluate the original "simply supported beam" model
% at the validation set points:
Yval = uq_evalModel(myModel,Xval);

%%
% Evaluate the PCE metamodels at the same points:
Y_PC_LARS = uq_evalModel(myPCE_LARS,Xval);
Y_PC_OMP = uq_evalModel(myPCE_OMP,Xval); 

%% 5.2 Create plots
%
% For each sample points of the validation set $\mathbf{x}^{(i)}$,
% the simply supported beam deflection $\mathcal{M}(\mathbf{x}^{(i)})$
% is compared against the one predicted by the two PCE metamodels
% $\mathrm{\mathcal{M}^{PCE}_{LAR}(\mathbf{x}^{(i)})}$ and
% $\mathrm{\mathcal{M}^{PCE}_{OMP}(\mathbf{x}^{(i)})}$:
li = 0:0.1:1;  % use normalized positions
uq_figure

% Loop over the realizations
cmap = uq_colorOrder(Nval);
for ii = 1:Nval
    uq_plot(...
        li, [0,Yval(ii,:),0],...
        li, [0,Y_PC_LARS(ii,:),0], '--o',...
        li, [0,Y_PC_OMP(ii,:),0], ':x',...
        'MarkerSize', 4,...
        'Color', cmap(ii,:))  % plot with a different color
    hold on
end
hold off

ylim([-0.013 0.005])

xlabel('$\mathrm{L_{rel}}$ (-)')
ylabel('$\mathrm V$ (m)')
uq_legend({'$\mathrm{\mathcal{M}(\mathbf{x}^{(1)})}$',...
    '$\mathrm{\mathcal{M}^{PCE}_{LAR}(\mathbf{x}^{(1)})}$',...
    '$\mathrm{\mathcal{M}^{PCE}_{OMP}(\mathbf{x}^{(1)})}$',...
    '$\mathrm{\mathcal{M}(\mathbf{x}^{(2)})}$',...
    '$\mathrm{\mathcal{M}^{PCE}_{LAR}(\mathbf{x}^{(2)})}$',...
    '$\mathrm{\mathcal{M}^{PCE}_{OMP}(\mathbf{x}^{(2)})}$',...
    '$\mathrm{\mathcal{M}(\mathbf{x}^{(3)})}$',...
    '$\mathrm{\mathcal{M}^{PCE}_{LAR}(\mathbf{x}^{(3)})}$',...
    '$\mathrm{\mathcal{M}^{PCE}_{OMP}(\mathbf{x}^{(3)})}$'},...
    'Location', 'north')
