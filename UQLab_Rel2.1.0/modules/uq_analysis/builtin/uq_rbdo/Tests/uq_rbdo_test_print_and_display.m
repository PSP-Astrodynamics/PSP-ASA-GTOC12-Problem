function success = uq_rbdo_test_print_and_display(level)
% SUCCESS = UQ_RBDO_TEST_display_print(LEVEL):
%     Testing the fuctionality of uq_print and uq_display in the context of
%     RBDO analyses
%
% See also UQ_SELFTEST_UQ_RBDO

%% Start test:
uqlab('-nosplash');
close all ; % Dangerous
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);

success = 1;

% Set seed for reproducibility (Shall we actually?)
rng(1) ;


%% Reference solution can be computed analytically
% allowed error
eps = 1e-3;
% Service load
Fser = 1.4622e6 ;
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
% Optimal dimensions - bstar = hstar
bstar = ((12 * Fser / pi^2 )* exp (-lk - lE + 2*lL - ...
    icdf('normal',TargetPf,0,1) * sqrt(sk^2 + sE^2 + 4*sL^2) ))^0.25;
hstar = bstar ;
% Optimal cost
Fstar = bstar * hstar ;

%% Set up the RBDO problem
% Set anayslsis method to RBDO
RBDopt.Type = 'rbdo' ;
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
RBDopt.Optim.Bounds = [150 150; 350 350] ;
% Starting point for optimization
RBDopt.Optim.StartingPoint = [350 300] ;
% Target Pf
RBDopt.TargetPf = TargetPf ;
% Limit-state surface 
RBDopt.LimitState.Model =  myModel ;
% Optimization algorithm - Use SQP which is faster
RBDopt.Optim.Method = 'IP' ;
RBDopt.Optim.IP.FDStepSize = 0.1 ;
RBDopt.Optim.MaxIter = 10; % Probably won't converge but doesn't matter, will be faster

%% RIA
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

% Also  uses CMA-ES and then HCAMES for display
RBDopt.Optim.Method = 'CCMAES' ;
myRBDOccmaes = uq_createAnalysis(RBDopt,'-private') ;
RBDopt.Optim.Method = 'HCCMAES' ;
myRBDOhccmaes = uq_createAnalysis(RBDopt,'-private') ;

% Also  uses GA and HGA for display

% First, make sure that the global optimization toolbox is available
try
    % Make sure that the global optimization toolbox is avaialble
    GAoptions = gaoptimset;
    goptimization_check = true;
catch
    goptimization_check = false;
end
if goptimization_check
    RBDopt.Optim.Method = 'GA' ;
    myRBDOga = uq_createAnalysis(RBDopt,'-private') ;
    RBDopt.Optim.Method = 'HGA' ;
    myRBDOhga = uq_createAnalysis(RBDopt,'-private') ;
end
%% Check up_print for errors
Error_print = {};
% RIA
try
    uq_print(myRBDOria)
catch errorRIAp
    Error_print{end+1} = errorRIAp.message;
end

% PMA
try
    uq_print(myRBDOpma)
catch errorPMAMp
    Error_print{end+1} = errorPMAp.message;
end

% SORA
try
    uq_print(myRBDOsora)
catch errorSORAp
    Error_print{end+1} = errorSORAp.message;
end

% SLA
try
    uq_print(myRBDOsla)
catch errorSLAp
    Error_print{end+1} = errorSLAp.message;
end

% Two-level
try
    uq_print(myRBDOtlmc)
catch errorTLMCp
    Error_print{end+1} = errorLTMCp.message;
end

% Two-level - CCMAES
try
    uq_print(myRBDOccmaes)
catch errorCCMAESp
    Error_print{end+1} = errorCCMAESp.message;
end

% Two-level - HCCMAES
try
    uq_print(myRBDOhccmaes)
catch errorHCCMAESp
    Error_print{end+1} = errorHCCMAESp.message;
end


% Two-level - GA
if goptimization_check
    try
        uq_print(myRBDOga)
    catch errorGAp
        Error_print{end+1} = errorGAp.message;
    end
    
    % Two-level - HGA
    try
        uq_print(myRBDOhga)
    catch errorHGAp
        Error_print{end+1} = errorHGAp.message;
    end
end

%% Check uq_display for errors
Error_display = {};

% RIA 
try
    uq_display(myRBDOria)
catch errorRIAp
    Error_display{end+1} = errorRIAp.message;
end

% PMA
try
    uq_display(myRBDOpma)
catch errorPMAp
    Error_display{end+1} = errorPMAp.message;
end

% SORA
try
    uq_display(myRBDOsora)
catch errorSORAp
    Error_display{end+1} = errorSORAp.message;
end

% SLA
try
    uq_display(myRBDOsla)
catch errorSLAp
    Error_display{end+1} = errorSLAp.message;
end

% Two-level
try
    uq_display(myRBDOtlmc)
catch errorTLMCp
    Error_display{end+1} = errorTLMCp.message;
end

% Two-level - CCMAES
try
    uq_display(myRBDOccmaes)
catch errorCCMAESp
    Error_display{end+1} = errorCCMAESp.message;
end

% Two-level - HCCMAES
try
    uq_display(myRBDOhccmaes)
catch errorHCCMAESp
    Error_display{end+1} = errorHCCMAESp.message;
end

if goptimization_check
    % Two-level - GA
    try
        uq_print(myRBDOga)
    catch errorGAp
        Error_print{end+1} = errorGAp.message;
    end
    
    % Two-level - HGA
    try
        uq_print(myRBDOhga)
    catch errorHGAp
        Error_print{end+1} = errorHGAp.message;
    end
end

close all;
%% Success
if isempty(Error_print) && isempty(Error_display)
    success = 1;
else
    success = 0;
    fprintf('\nError in uq_test_rbdo_print_and_display:\n');
    for ii = 1:length(Error_print)
        fprintf(Error_print{ii});
        fprintf('\n')
    end
    for ii = 1:length(Error_display)
        fprintf(Error_display{ii});
        fprintf('\n')
    end
    ErrStr = 'Errors in uq_test_rbdo_print_and_display';
    error(ErrStr);
end




end