function Y = uq_SteelBeamCorrosion(X,P)

% Recover the parameter of the function which is the random field
myRandomField = P ;
% Split the random vector into its components
% Yield stress
fy = X(:,1) ;
% Beam breadth
b0 = X(:,2) ;
%Beam height
h0 = X(:,3) ;
% Get the load from the standard Gaussian variables
F = uq_RF_Xi_to_X(myRandomField,X(:,4:end)) ;

% Constant parameters
kappa = 8.3333e-06 ; % = in m/month
rho = 78.5 ; % in kN/m^3 ;
L = 5 ; % in m

% Time discretization
t = linspace(0,120,size(F,2));
N = size(b0,1) ;
M = size(F,2) ;

% Limit-state
Y = ((repmat(b0,1,M) - 2 * kappa .* repmat(t,N,1)) .* (repmat(h0,1,M) - 2 * kappa .* repmat(t,N,1)).^2 .* repmat(fy,1,M))/4 - ...
    (F * L / 4 + rho * repmat(b0 .* h0,1,M) * L^2 / 8 ) ;

end
