function Y = uq_GBM_MultiOutputs(X,param)
S0 = 1;
T = 1;
Nt = 1e4;
dt = T/Nt;
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

% get paramters
mu = X(:,1);
sigma = X(:,2);

% initialization
N = size(X,1);
if length(S0)==1
    St=S0*ones(N,1);
else
    St = S0;
end
Sm = zeros(N,1);

for i = 1:Nt
    xi = randn(N,1);
    St=St.*exp((mu-sigma.^2)*dt+sigma.*xi*sqrt(dt));
    Sm = Sm + St;
end

Sm=Sm/Nt;
Y = [St,Sm];
end