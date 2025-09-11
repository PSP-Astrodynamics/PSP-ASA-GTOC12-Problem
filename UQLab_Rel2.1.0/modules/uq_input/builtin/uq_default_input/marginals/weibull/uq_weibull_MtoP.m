function Parameters = uq_weibull_MtoP( Moments )
% Parameters = UQ_WEIBULL_MTOP(Moments) returns the 
% parameters of a Weibull distribution based on 
% its mean and standard deviation

mu = Moments(1);
sigma = Moments(2);

% the objective function that will be minimized to obtain the parameters
obj_fun = @ (X) uq_obj_wblstat(X, [mu, sigma]);

% parguess = Moments(1)/Moments(2);
parguess = 1;

[Pars, Fval]= fminsearch(obj_fun, parguess, ...
    optimset('TolFun', 1e-10));

Pars = [Moments(1)/gamma(1+1/Pars)  Pars];

if Fval > 1
    fprintf('Warning: Parameter estimation for the Weibull distribution was not accurate, repeating the process...\n');
    parguess = 0.1/1e+08;
    [NewPars, NewFval]= fminsearch(obj_fun, parguess, ...
        optimset('TolFun', 1e-10));
    if NewFval < Fval
        if NewFval < 1
            fprintf('Parameter estimation finished successfully.\n');
        else
            fprintf('Warning: Parameter estimation was not successful.\nAbs. error (mu + sigma) = %f\n',  NewFval);
        end
        Pars = NewPars;
    else
        fprintf('Warning: Parameter estimation was not successful.\nAbs. error (mu + sigma) = %f\n',  Fval);
    end
end
Parameters = [Pars(1), Pars(2)];


function Error = uq_obj_wblstat(Parameters, Moments)
% Error = UQ_OBJ_WBLSTAT(Parameters, Moments) checks the absolute error
% of wblstat(Parameters(1), Parameters(2)) vs Moments

cov_est = gamma(1+1/Parameters)/sqrt(gamma(1+2/Parameters) - gamma(1+1/Parameters)^2);
cov_rel = Moments(1)/Moments(2);

Error = abs(cov_est-cov_rel);