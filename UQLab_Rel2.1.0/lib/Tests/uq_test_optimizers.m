function success = uq_test_optimizers(level)
% SUCCESS = UQ_TEST_OPTIMIZERS(LEVEL): test if the optimization algorithms
% run properly and retrun expected results 
%
% See also: UQ_TEST_UQ_UQLIB, UQ_GRADIENT

success = 1;

%% Start the framework:
uqlab('-nosplash');
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |', level,'| uq_test_optimizers...\n']);
%% Input
fun = @(X) X.^2 ;
lb = -1 ;
ub = 1 ;
nonlcon = @(X) 0.5-X ;
options.Display = 'none' ;
%% Test:
% General error that is allowed in the comparisons:
AllowedError = 0.1;

% True solution 
% - for general unconstained case
xtrue = 0 ;
% for gso :
xgso = 0.25 ;
% for constrained case
xcon = 0.5 ;


% GSO algorithm
[xstar,fstar,exitflag,output] = uq_gso(fun,[],1,lb,ub,options) ;
% Allowed error for gso: Ten time the default as the result is sensitive to
% the grid. This solution may change a lot if the default number of grid
% points is modified later for instance
diff = abs(xstar - xgso) ;
success = success & exitflag > 0 & diff <= 10*AllowedError;

% CEO algorithm
[xstar,fstar,exitflag,output] = uq_ceo(fun,[],[],lb,ub,options) ;
diff = abs(xstar - xtrue) ;
success = success & exitflag > 0 & diff <= AllowedError ;

% CMA-ES algorithm
[xstar,fstar,exitflag,output] = uq_cmaes(fun,[],[],lb,ub,options) ;
diff = abs(xstar - xtrue) ;
success = success & exitflag > 0 & diff <= AllowedError ;

% CMA-ES algorithm
[xstar,fstar,exitflag,output] = uq_1p1cmaes(fun,[],[],lb,ub,options) ;
diff = abs(xstar - xtrue) ;
success = success & exitflag > 0 & diff <= AllowedError ;

% CMA-ES algorithm
[xstar,fstar,exitflag,output] = uq_c1p1cmaes(fun,[],[],lb,ub,nonlcon,options) ;
diff = abs(xstar - xcon) ;
success = success & exitflag > 0 & diff <= AllowedError ;

