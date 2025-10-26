%% MODEL MODULE: MULTIPLE OUTPUTS
%
% This example showcases the modeling of the deflection of a simply
% supported beam subjected to a uniform random load at several points along
% its length.

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
set(gca,'visible','off')

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
% The simply supported beam model has five independent inputs
% modeled by lognormal random variables.
% The parameters of the distributions are given in the following table:

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
InputOpts.Marginals(1).Name = 'b'; % beam width
InputOpts.Marginals(1).Type = 'Lognormal';
InputOpts.Marginals(1).Moments = [0.15 0.0075]; % (m)

InputOpts.Marginals(2).Name = 'h'; % beam height
InputOpts.Marginals(2).Type = 'Lognormal';
InputOpts.Marginals(2).Moments = [0.3 0.015]; % (m)

InputOpts.Marginals(3).Name = 'L'; % beam length
InputOpts.Marginals(3).Type = 'Lognormal';
InputOpts.Marginals(3).Moments = [5 0.05]; % (m)

InputOpts.Marginals(4).Name = 'E'; % Young's modulus
InputOpts.Marginals(4).Type = 'Lognormal';
InputOpts.Marginals(4).Moments = [3e10 4.5e9] ; % (Pa)

InputOpts.Marginals(5).Name = 'p'; % uniform load
InputOpts.Marginals(5).Type = 'Lognormal';
InputOpts.Marginals(5).Moments = [1e4 2e3]; % (N/m)

%%
% Create an INPUT object based on the defined marginals:
myInput = uq_createInput(InputOpts);

%% 4 - VISUALIZATION OF MODEL RESPONSES
%
% Generate five sample points:
X = uq_getSample(5,'LHS');

%%
% Evaluate the corresponding computational model responses:
Y = uq_evalModel(myModel,X);

%%
% The output |Y| is a $N \times N_{out}$ and consists of
% five realizations $(N = 5)$,
% each with $N_{\mathrm{out}} = 9$ values:
Ysize = size(Y);

%% 
% The deflections $V(s_i)$ at the nine points are plotted
% for three realizations of the random inputs.
% Relative length units are used for comparison,
% because $L$ is one of the random inputs:
myColors = uq_colorOrder(Ysize(1));
li = 0:0.1:1;  % use normalized positions

uq_figure
% Loop over the realizations and plot with a different color
for ii =  1:Ysize(1)
    uq_plot(li, [0 Y(ii,:) 0], 'x-', 'Color', myColors(ii,:))
    hold on
end
hold off

ylim([-0.013 0.005])
xlabel('$\mathrm{L_{rel}}$ (-)')
ylabel('$\mathrm{V}$ (m)')
uq_legend(...
    {'Realization 1','Realization 2','Realization 3',...
    'Realization 4', 'Realization 5'},...
    'Location', 'north')
