function Y = uq_Heston(X,param)
% Simulation of the Heston pricing model: two coupled SDE
% dSt = mu*St*dt + sqrt(vt)*St*dW1t
% dvt = kappa(theta-vt)*dt + sigma*sqrt(vt)*dW2t

% S0: initial price
% v0: initial volatility
% mu: expected return
% kappa mean reversion speed of the volatility
% sigma: volatility of the volatility
% rho: correlation coefficient between the two Wiener processes W1t and W2t
% T: total time span
% N: number of discretizations in the simulation
% Asian: whether to return int St*dt

% set default values
S0 = 1;
T = 1;
Nt = 1e4;
dt = T/Nt;

% update model parameters if defined
if nargin>1
    % value at 0
    if isfield(param,'S0')
        S0 = param.S0;
    end
    % total time span
    if isfield(param,'T')
        T = param.T;
    end
    % number of steps or step size  
    if isfield(param,'Nt')        
        Nt = param.N;
        dt = T/Nt;
    elseif isfield(param,'dt')
        dt = param.dt;
        Nt = ceil(T/dt);
        dt = T/Nt;
    end
end

% retrieve the model parameters
mu = X(:,1);
kappa = X(:,2);
theta = X(:,3);
sigma = X(:,4);
rho = X(:,5);
v0 = X(:,6);

% initialization
N = size(X,1);
if length(S0)==1
    St=S0*ones(N,1);
else
    St = S0;
end
vt=v0;
Sm = zeros(N,1);

for i=1:Nt
    e1=randn(N,1);
    e2_temp=randn(N,1);
    e2=e1.*rho+e2_temp.*sqrt(1-rho.^2);
    St=St.*exp((mu-0.5*max(vt,0))*dt+sqrt(max(vt,0))*sqrt(dt).*e1);
    vt=vt+kappa.*(theta-max(vt,0))*dt+sigma.*sqrt(max(vt,0))*sqrt(dt).*e2;
    Sm = Sm + St;
end
Sm = Sm/Nt;

Y = St;
end

