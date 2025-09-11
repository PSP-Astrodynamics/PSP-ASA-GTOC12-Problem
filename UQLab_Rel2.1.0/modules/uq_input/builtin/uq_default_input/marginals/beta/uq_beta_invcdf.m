function X_rescaled = uq_beta_invcdf( F, parameters )
% F = UQ_BETA_INVCDF(X, parameters):
%     calculates the Inverse Cummulative Density Function values of samples 
%     X  that follow a Beta distribution with parameters specified in the 
%     vector 'parameters'
%
% Input parameters:
%     'X'             The samples
%     'parameters'    [r s a b] where [a b] are the bounds of the
%                     distribution and r,s the other required parameters.
%
%     NOTE: 
%     Please keep in mind the differences between the MATLAB and UQLab
%     implementation
%     MATLAB : beta distribution always has support [0,1] 
%     UQLab  : generalised case with arbitrary support [a,b] 
% 
% See also: BETAINV, UQ_EVAL_JACOBI

r = parameters(1);
s = parameters(2);

X = betainv(F, r, s);
switch length(parameters)
    case 2 
        % the support is [0,1]
        X_rescaled = X;
    case 4 
        % the support is [a,b]
        a = parameters(3);
        b = parameters(4);
        X_rescaled = (b-a)*X + a;
    otherwise
        error('Error: Beta distribution can only be handled when 2 or 4 parameters are defined!')
end




