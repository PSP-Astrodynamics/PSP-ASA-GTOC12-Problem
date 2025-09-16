%% RANDOM FIELD: CORROSION OF A STEEL BEAM
% This example showcases how to build a probabilistic model which is a
% blend of random scalar variables and a random field for a standard
% uncertainty quantification analysis. The application of interest is the
% assessment of the resistance of a beam subject to corrosion.


%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(1,'twister')
uqlab


%% 2 - PROBABILISTIC INPUT MODEL

%% 2.1 - SCALAR RANDOM VARIABLES
% The steel bending beam has three scalar random variables: the yield
% stress, the beam breadth and the beam height. They are defined as an
% input object in this section
%%
% Define an INPUT object with the following marginals:
Input.Marginals(1).Name = 'fy'; % Yield stress
Input.Marginals(1).Type = 'Lognormal';
Input.Marginals(1).Moments = [240e3 240e2]; % (m)

Input.Marginals(2).Name = 'b0'; % beam breadth
Input.Marginals(2).Type = 'Lognormal';
Input.Marginals(2).Moments = [0.2 0.03*0.2]; % (m)

Input.Marginals(3).Name = 'h0'; % beam height
Input.Marginals(3).Type = 'Lognormal';
Input.Marginals(3).Moments = [0.05 0.03*0.05]; % (m)

%%
% Create the INPUT object:
myScalarInput = uq_createInput(Input) ;


%% 2.2 RANDOM FIELD
% The steel beam is subjected to a stochastic load  modelled as a Gaussian
% random process with Gaussian autocorrelation. The corresponding input
% object is defined in this section
%%
% Specify the type of input
RFInput.Type = 'RandomField';

%%
% Specify the correlation family
RFInput.Corr.Family = 'Gaussian' ;

%%
% Specify the discretization domain (Duration of 10 years, expressed in
% months)
RFInput.Domain= [0, 120]';

%%
% Specify the number of points for building the mesh
RFInput.SPD = 121 ;

%%
% Specify the correlation length (three months)
RFInput.Corr.Length = 3;

%%
% Specify the expansion order
RFInput.ExpOrder = 20 ;

%%
% Specify the mean and standard deviation of the random field
RFInput.Mean = 15 ;
RFInput.Std = 0.3*15 ;

%%
% Create an INPUT object based on the specified random field options
myRFInput = uq_createInput(RFInput);

%%
% Print a report of the created INPUT object
uq_print(myRFInput);

%% 2.3 MERGE THE TWO INPUTS
% When a random field object is created, UQLab generates an internal
% input object corresponding to the underlying Gaussian random vairables $\xi$. 
% It is then possible to merge the scalar
% random variable input object to the latter, for further use in a UQ
% analysis

%%
% Merge the two inputs
myFullInput = uq_mergeInputs(myScalarInput, myRFInput.UnderlyingGaussian) ;

%% 3 - COMPUTATIONAL MODEL
%
% The steel bending beam model is shown in the following figure:
figure
[I,~] = imread('SteelBeamCorrosion.png');
image(I)
axis equal tight
set(gca,'visible','off')

%%
% The forward model describes the formation of a plastic hinge midspan monthly and
% for a period of $10$ years. The corrosion is modelled by a linear
% increade of corrosion depth in the form $d_c = \kappa t$. $\kappa$ is a
% deterministic parameter controllling the corrosion kinematics. 
% The limit-state function thereofre reads:
%
% $$ V = \frac{ (b_0 - 2 \kappa t)(h_0 - 2 \kappa t)^2 f_y}{4} - (\frac{F L}{4} + \frac{\rho b_0 h_0 L^2}{8})$$
%
% This computation is carried out by the function
% |uq_SteelBeamCorrosion(X)| supplied with UQLab.
% The input variables of this function are gathered into the $N \times M$
% matrix |X|, where $N$ and $M$ are the numbers of realizations
% and input variables, respectively.
% The input variables are given in the following order:
%
% # $f_y$: Steel yield stress $(MPa)$
% # $b_0$: Initial beam width $(m)$
% # $h_0$: Initial beam height $(m)$
% # $\xi$: Vector of standard Gaussian variables describing the random
% field (-) - Their dimension is equal to the expansion order, herein  $20$
%
% The remaining variables are deterministic  and directly provided within
% the file provided by UQLab. Their values are the following:
%
% # $L$: Beam length $( 5 m)$
% # $\kappa$: Corrosion kinematic parameter $(1 mm / year)$
% # $\rho$: Steel mass density $(78.5 kN/mm)$


%%
% Create a MODEL object from the steel beam function:
ModelOpts.mFile = 'uq_SteelBeamCorrosion';
ModelOpts.Parameters = myRFInput ;
myModel = uq_createModel(ModelOpts);

%% 4. EXPERMENTAL DESIGN
% Construct a surrogate based on 150 model runs
X = uq_getSample(myFullInput, 120, 'LHS') ;

%%
% Evaluate the computational model
fprintf('Evaluating the experimental design...')
Y = uq_evalModel(myModel, X) ;
fprintf(' done!\n\n')

%% 4 - POLYNOMIAL CHAOS EXPANSION (PCE) METAMODEL
%
% Select PCE as the metamodeling tool:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'PCE';
MetaOpts.Display = 'quiet';
%%
% Specify a sparse truncation scheme (hyperbolic norm with $q = 0.75$):
MetaOpts.TruncOptions.qNorm = 0.75;

%%
% Specify the range of the degrees to be compared
% by the adaptive algorithm:
MetaOpts.Degree = 3:10;

%%
% Define the experimental design for PCE
MetaOpts.ExpDesign.X = X ;
MetaOpts.ExpDesign.Y = Y ;

%%
% Create and add the PCE metamodel to UQLab
fprintf('Training the PCE...')
myPCE = uq_createModel(MetaOpts);
fprintf(' done!\n\n')
%% 5 - EVALUATE THE PCE METAMODEL
% Get some validation samples
Xval = uq_getSample(myFullInput, 5) ;

%%
% Evaluate the original model
Yval = uq_evalModel(myModel, Xval) ;

%%
% Evaluate the PCE model
Ypce = uq_evalModel(myPCE, Xval) ;

%%
% Compare the response: 
%  - true responses: solid lines
%  - PCE predictions: dashed lines
uq_figure;
t = linspace(0,120,RFInput.SPD) ;
h1 = uq_plot(myRFInput.Internal.Mesh,Yval,'linewidth',1);
hold on
h2 = uq_plot(myRFInput.Internal.Mesh,Ypce,'--','linewidth',2);
xlabel ('$x$','interpreter','latex') ;
ylabel('$Y$','interpreter','latex') ;