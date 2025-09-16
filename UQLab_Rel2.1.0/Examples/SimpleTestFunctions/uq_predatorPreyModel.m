function population = uq_predatorPreyModel(X,time)
% implementation of the Lotka-Volterra predator-prey model with multiple
% parameter realizations and the time
firstTime = time(1);
lastTime = time(end);    % Duration time of simulation.

nSteps = numel(time); % Number of timesteps
%% Initialize
nReal = size(X,1); 

% Parameters
alpha = X(:,1);
beta =  X(:,2);
gamma = X(:,3);
delta = X(:,4);

% Initial conditions
initialPrey = X(:,5);
initialPred = X(:,6);

%% Solve equation

% solver options (smaller tolerance)
odeOpts = odeset('RelTol',1e-4,'AbsTol',1e-7);
%odeOpts = odeset('RelTol',2e-3,'AbsTol',2e-6);

% for loop to solve equations with multiple initial values and parameters
population = zeros(nReal,2*nSteps);
for ii = 1:nReal
    % setup diff equations 
    diffEq=@(t,x) [  x(1)*(alpha(ii) - beta(ii)*x(2));...
                    -x(2)*(gamma(ii) - delta(ii)*x(1))];
    % solve using numerical ODE solver 45
    [t,sol] = ode45(diffEq,[firstTime lastTime],[initialPrey(ii); initialPred(ii)],odeOpts);
    % interpolate solution to specified timesteps
    interpSolPrey = interp1(t,sol(:,1),time);
    interpSolPred = interp1(t,sol(:,2),time);
    % assign solution
    population(ii,:) = [interpSolPrey',interpSolPred'];
end

