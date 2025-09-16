function [ret_checks, ret_names] = uq_check_toolboxes()
% UQ_CHECK_TOOLBOXES checks the availability of Matlab toolboxes

fun = @(x)100*(x(2)-x(1)^2)^2 + (1-x(1))^2;
x0 = [-1,2];
A = [1,2];
b = 1;

%% check optimization toolbox

try 
    x = fmincon(fun,x0,A,b,[],[],[],[],[], ...
        optimset('Maxiter',1,'Display','none'));
    OPTIM_TOOLBOX_OK = true;
catch
    OPTIM_TOOLBOX_OK = false;
end

%% check global optimisation toolbox
try 
    x = ga(fun,2,A,b,[],[],[],[],[], ...
        gaoptimset('Generations',1,'PopulationSize',1,'Display','none'));
    GOPTIM_TOOLBOX_OK = true;
catch
    GOPTIM_TOOLBOX_OK = false;
end

%% return results
ret_checks = [OPTIM_TOOLBOX_OK, GOPTIM_TOOLBOX_OK];
ret_names = {'Optimization Toolbox', 'Global Optimization Toolbox'};
