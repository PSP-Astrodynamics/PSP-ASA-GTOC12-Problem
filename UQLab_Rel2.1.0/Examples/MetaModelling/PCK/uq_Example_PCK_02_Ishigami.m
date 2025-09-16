%% PC-KRIGING METAMODELING: MULTIPLE INPUT DIMENSIONS
%
% This example illustrates different aspects of polynomial chaos-Kriging
% (PC-Kriging) metamodel construction
% using the three-dimensional Ishigami function 
% as the full computational model.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(112358,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The Ishigami function is defined as:
%
% $$Y(\mathbf{x}) = \sin(x_1) + 7 \sin^2(x_2) + 0.1 x_3^4 \sin(x_1)$$
%
% where $x_i \in [-\pi, \pi], \; i = 1,2,3.$

%%
% This computation is carried out by the function
% |uq_ishigami(X)| supplied with UQLab.
% The function evaluates the inputs gathered in the $N \times M$
% matrix |X|, where $N$ and $M$ are the numbers of realizations
% and input variables, respectively.
% 
% Create a MODEL object from the |uq_ishigami| function:
ModelOpts.mFile = 'uq_ishigami';

myModel = uq_createModel(ModelOpts);  

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of three independent uniform 
% random variables:
%
% $$X_i \sim \mathcal{U}(-\pi, \pi), \quad i = 1,2,3$$

%%
% Specify these marginals:
for ii = 1:3
    InputOpts.Marginals(ii).Type = 'Uniform';
    InputOpts.Marginals(ii).Parameters = [-pi pi]; 
end

%%
% Create an INPUT object based on the specified marginals:
myInput = uq_createInput(InputOpts);

%% 4 - EXPERIMENTAL DESIGN
%
% To compare different PC-Kriging metamodeling techniques,
% create a single  experimental design of size $80$
% using the Latin Hypercube Sampling:
X = uq_getSample(80,'LHS');

%%
% Evaluate the computational model at the experimental design points:
Y = uq_evalModel(myModel,X);

%% 5 - PC-KRIGING METAMODELS
%
% Two different modes of PC-Kriging metamodel are considered below:
% Sequential mode and Optimal mode.

%% 5.1 Sequential PC-Kriging metamodel
%
% Select |PCK| as the metamodeling tool in UQLab
% and |sequential| as its mode:
SeqPCKOpts.Type = 'Metamodel';
SeqPCKOpts.MetaType = 'PCK';
SeqPCKOpts.Mode = 'sequential';

%%
% Provide the experimental design generated before:
SeqPCKOpts.ExpDesign.X = X;
SeqPCKOpts.ExpDesign.Y = Y;

%%
% Specify the options for the polynomial trend of the PC-Kriging metamodel;
% the trend is determined by LARS
% with the adaptive maximum polynomial degree between $3$ to $15$:
SeqPCKOpts.PCE.Method = 'LARS';
SeqPCKOpts.PCE.Degree = 3:15;

%%
% Use the Gaussian correlation family for the underlying Gaussian process
% model in the PC-Kriging metamodel:
SeqPCKOpts.Kriging.Corr.Family = 'Gaussian';

%%
% Create the Sequential PC-Kriging metamodel:
mySeqPCK = uq_createModel(SeqPCKOpts);

%% 5.2 Optimal PC-Kriging metamodel
% Use all the previous metamodeling options
% and select |optimal| PC-Kriging as the mode:
OptPCKOpts = SeqPCKOpts;
OptPCKOpts.Mode = 'optimal';

%%
% Create the Optimal PC-Kriging metamodel:
myOptPCK = uq_createModel(OptPCKOpts);

%% 6 - VALIDATION
%
% The accuracy of the two metamodels is compared based on a validation set.
% The validation set consists of a large number of Monte Carlo sample:
Xval = uq_getSample(myInput,1e5);
Yval = uq_evalModel(myModel,Xval);

%%
% The accuracy of the metamodels is compared in terms of 
% the relative generalization error, which is defined as:
% 
% $$\widehat{err}_{gen} = \frac{\frac{1}{N}\sum_i \left( y^{(i)}-\widehat{y}^{(i)} 
% \right)^2}{Var\left[ Y \right]}$$
% 
% where $y^{(i)}$ and $\widehat{y}^{(i)}$ are the true response value
% and the corresponding metamodel prediction value evaluated at the
% validation set points, respectively; and $Var$ denotes the variance.

%%
% Hence, predict the response values of the validation set
% for each metamodel:
YvalSeqPCK = uq_evalModel(mySeqPCK,Xval);
YvalOptPCK = uq_evalModel(myOptPCK,Xval);

%%
% Plot the true vs. predicted values:
uq_figure

subplot(1, 2, 1)
uq_formatDefaultAxes(gca);
uq_plot(Yval, YvalSeqPCK, '+')
hold on 
uq_plot([min(Yval) max(Yval)], [min(Yval) max(Yval)], 'k')
hold off
axis equal 
axis([min(Yval) max(Yval) min(Yval) max(Yval)])

title('Sequential PCK')
xlabel('$\mathrm{Y}$')
ylabel('$\mathrm{Y_{PCK}}$')

subplot(1, 2, 2)
uq_formatDefaultAxes(gca);
uq_plot(Yval, YvalOptPCK, '+')
hold on 
uq_plot([min(Yval) max(Yval)], [min(Yval) max(Yval)], 'k')
hold off
axis equal 
axis([min(Yval) max(Yval) min(Yval) max(Yval)]) 

title('Optimal PCK')
xlabel('$\mathrm{Y}$')
ylabel('$\mathrm{Y_{PCK}}$')

%% 
% Finally, compute the relative generalization error and print the results:
errGenSeqPCK = mean((Yval-YvalSeqPCK).^2)/var(Yval);
errGenOptPCK = mean((Yval-YvalOptPCK).^2)/var(Yval);
fprintf('Sequential PC-Kriging model: %5.4e\n',errGenSeqPCK)
fprintf('Optimal PC-Kriging model:    %5.4e\n',errGenOptPCK)