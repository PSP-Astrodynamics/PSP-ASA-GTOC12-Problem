%% *_Dubourg's Oscillator Function_*
%
% Syntax:
% Y = UQ_DUBOURGS_OSCILLATOR(X)
% Y = UQ_DUBOURGS_OSCILLATOR(X,P)
%
% The model contains M=8 (independent) random variables
% (X=[m_p,m_s,k_p,k_s,zeta_p,zeta_s,S_0,F_s])
% and 1 scalar parameter of type double (P=[p]).
%
% Input:
% X     N x M matrix including N samples of M stochastic parameters
% P     vector including parameters
%       by default: p = 3;
%
% Output/Return:
% Y     column vector of length N including evaluations using Dubourg's
%       Oscillator function
%
% See also: UQ_EXAMPLE_RELIABILITY_03_OSCILLATOR


%%%
function g = uq_DampedOscillator(X,P)


%% Check
%
narginchk(1,2)

assert(size(X,2)==8,'exactly 8 input variables needed')


%% Constants
%
if nargin==1
    p = 3;
end


if nargin==2
    p = P;
end


%% Random variables

% primary mass
m_p = X(:,1);
% secondary mass
m_s = X(:,2);
% stiffness of the primary spring
k_p = X(:,3);
% stiffness of the secondary spring
k_s = X(:,4);
% damping ratio of the primary damper
zeta_p = X(:,5);
% damping ratio of the secondary damper
zeta_s = X(:,6);
% Intensity of the white noise base acceleration (excitation)
S_0 = X(:,7);
% Force capacity of the secondary spring
F_s = X(:,8);


%% Abbreviations and ratios
% natural frequency of the primary partial system / oscillator
omega_p = sqrt(k_p./m_p);

% natural frequency of the secondary partial system / oscillator
omega_s = sqrt(k_s./m_s);

% relative mass
gamma = m_s./m_p;

% average natural frequency
omega_a = (omega_p+omega_s)/2;

% average damping ratio
zeta_a = (zeta_p+zeta_s)/2;

% tuning parameter
theta = (omega_p-omega_s)./omega_a;


%% Mean-square relative displacement
meanSquareRelativeDisplacement = pi*S_0./(4*zeta_s.*omega_s.^3) .* ...
    zeta_a.*zeta_s ./ ( zeta_p.*zeta_s.*(4*zeta_a.^2+theta.^2) + gamma.*zeta_a.^2 ) .* ...
    ( zeta_p.*omega_p.^3 + zeta_s.*omega_s.^3 ).*omega_p ./ ( 4*zeta_a.*omega_a.^4);


%% Evaluation
% performance function
g = F_s - p*k_s.*sqrt(meanSquareRelativeDisplacement);


end