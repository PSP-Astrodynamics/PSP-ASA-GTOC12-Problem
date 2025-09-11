function success = uq_rbdo_test_Reliability(level)
% SUCCESS = UQ_RBDO_TEST_RELIABILITY(LEVEL):
%     Testing two-level rbdo using all reliability methods available in
%     UQLAb

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
% Service load
Fser = 1.4622e6 ;

%% Reference solution can be computed analytically
% Target faillure 
TargetPf = 0.1 ;
% mean and CoV of random parameters
muk = 0.6 ; dk = 0.1 ;
muE = 1e4 ; dE = 0.05 ;
muL = 3e3; dL = 0.01 ;
% Compute the corresponding lognormal parameters
sk = sqrt(log(1 + dk^2)) ;
lk = log(muk) - 0.5 * sk^2 ;

sE = sqrt(log(1 + dE^2)) ;
lE = log(muE) - 0.5 *sE^2 ;

sL = sqrt(log(1 + dL^2)) ;
lL = log(muL) - 0.5 *sL^2 ;

bstar = ((12 * Fser / pi^2 )* exp (-lk - lE + 2*lL - ...
    icdf('normal',TargetPf,0,1) * sqrt(sk^2 + sE^2 + 4*sL^2) ))^0.25;

hstar = bstar ;

Fstar = bstar * hstar ;
% Get the analytical optimal solution 
%% Set up the RBDO problem
% Set anayslsis method to RBDO
RBDopt.Type = 'rbdo' ;
RBDopt.Method = 'two-level' ;

% % Enable display
RBDopt.Display = 'none' ;

%% 2 - Cost function
RBDopt.Cost.mFile = 'uq_columncompression_cost' ;

%% 3 - Computational model / constraints
% Hard constraint
MOpts.mFile = 'uq_columncompression_constraint' ;
myModel = uq_createModel(MOpts,'-private') ;

% Soft constraint
RBDopt.SoftConstraints.mString = 'X(:,2) - X(:,1)' ;

%% 4 - Probabilistic model
% Input object 
Iopts.Marginals(1).Name = 'k' ;
Iopts.Marginals(1).Type = 'Lognormal' ;
Iopts.Marginals(1).Moments = [0.6 0.06] ;
Iopts.Marginals(2).Name = 'E' ;
Iopts.Marginals(2).Type = 'Lognormal' ;
Iopts.Marginals(2).Moments = [1e4 0.05*1e4] ;
Iopts.Marginals(3).Name = 'L' ;
Iopts.Marginals(3).Type = 'Lognormal' ;
Iopts.Marginals(3).Moments = [3e3 0.01*3e3] ;

myInput = uq_createInput(Iopts, '-private') ;

% Design variables
RBDopt.Input.DesVar(1).Name = 'b' ;
RBDopt.Input.DesVar(1).Type = 'constant' ;
RBDopt.Input.DesVar(2).Name = 'h' ;
RBDopt.Input.DesVar(2).Type = 'constant' ;

% Environmental variables
RBDopt.Input.EnvVar = myInput ;

%% 5 - Optimization problem
% Bounds of the design space
RBDopt.Optim.Bounds = [200 200; 300 300] ;
% Starting point for optimization
RBDopt.Optim.StartingPoint = [250 250] ;
% Target Pf
RBDopt.TargetPf = TargetPf ;
RBDopt.Optim.Method = 'IP' ;
RBDopt.Optim.IP.FDStepSize = 0.1 ;
% Limit-state surface 
RBDopt.LimitState.Model =  myModel ;

%% FORM
RBDopt.Reliability.Method = 'form' ;
myRBDOform = uq_createAnalysis(RBDopt,'-private') ;

%% Inverse FORM
RBDopt.Reliability.Method = 'iform' ;
myRBDOiform = uq_createAnalysis(RBDopt,'-private') ;

%% MC
RBDopt.Reliability.Method = 'mc' ;
myRBDOmc = uq_createAnalysis(RBDopt,'-private') ;

%% SS
RBDopt.Reliability.Method = 'subset' ;
myRBDOss = uq_createAnalysis(RBDopt,'-private') ;

%% IS
RBDopt.Reliability.Method = 'is' ;
myRBDOis = uq_createAnalysis(RBDopt,'-private') ;


success = success & abs((Fstar - myRBDOform.Results.Fstar)/Fstar) < eps ;
success = success & abs((Fstar - myRBDOiform.Results.Fstar)/Fstar) < eps ;
success = success & abs((Fstar - myRBDOmc.Results.Fstar)/Fstar) < eps ;
success = success & abs((Fstar - myRBDOss.Results.Fstar)/Fstar) < eps ;
success = success & abs((Fstar - myRBDOis.Results.Fstar)/Fstar) < eps ;


end