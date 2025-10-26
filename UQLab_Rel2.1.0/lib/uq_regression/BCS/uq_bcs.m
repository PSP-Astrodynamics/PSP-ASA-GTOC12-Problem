function results = uq_bcs(Psi, Y, sigma2, eta_stop, verbose)
% COEFFS = UQ_BCS(PSI, Y, SIGMA): Sparse regression with Bayesian
% Compressive Sensing as described in Alg. 1 (Fast Laplace) of
% 
% Babacan, S. D., Molina, R., & Katsaggelos, A. K. (2009). Bayesian 
% compressive sensing using Laplace priors. IEEE Transactions on image 
% processing, 19(1), 53-63.
% 
% Update formulas from
% Tipping, M. E., & Faul, A. C. (2003, January). Fast marginal likelihood 
% maximisation for sparse Bayesian models. In AISTATS.
%
% 
% sigma2: noise precision (sigma^2)
% nu fixed to 0

if nargin < 4
    eta_stop = 1e-7; % default
end
if nargin < 5
    verbose = 0;
end

[N, P] = size(Psi);

beta = 1/sigma2;

PsiTPsi = Psi'*Psi; % compute once, doesn't change
PsiTY = Psi'*Y; % compute once, doesn't change

% initialize with the regressor that has the largest correlation with Y
[~, ind_start] = max(PsiTY.^2 ./ diag(PsiTPsi));

ind_global_to_local = zeros(1,P); % index values
ind_global_to_local(ind_start) = 1;
num_active = 1;
active_indices = ind_start;
deleted_indices = [];

bcs_path = [ind_start];

gamma = zeros(1, P);
% for the initial value of gamma(ind_start), use the RVM formula 
%   gamma = (q^2 - s) / (s^2)
% and the fact that initially s = S = beta*Psi_i'*Psi_i and q = Q =
% beta*Psi_i'*Y
gamma(ind_start) = (PsiTY(ind_start)^2 - sigma2 * PsiTPsi(ind_start, ind_start)) ...
    / (PsiTPsi(ind_start, ind_start)^2); 
Sigma = 1 / (beta * PsiTPsi(ind_start, ind_start) + 1/gamma(ind_start));
mu = Sigma * PsiTY(ind_start) * beta; 
tmp1 = beta * PsiTPsi(ind_start,:);
S = beta * diag(PsiTPsi)' - Sigma * (tmp1).^2; 
Q = beta * PsiTY' - mu*(tmp1);
% tmp2 = (1 - gamma.*S);
tmp2 = ones(1,P); % alternative computation for the initial s,q
q0tilde = PsiTY(ind_start);
s0tilde = PsiTPsi(ind_start, ind_start);
tmp2(ind_start) = s0tilde / (q0tilde^2) / beta;
s = S ./ tmp2;
q = Q ./ tmp2;
lambda = 2*(num_active - 1) / sum(gamma); % initialize lambda as well

it_counter = 0; 
max_iterations = 1000;

while true
    it_counter = it_counter + 1;

    if verbose
        fprintf('    lambda = %f\n', lambda); 
    end
    % Calculate the potential updated value of each gamma(i)
    if lambda == 0 % RVM
        gamma_potential = ((q.^2 - s) > lambda) .* ...
            (q.^2 - s) ./ (s.^2);
    else
        a = lambda * s.^2;
        b = s.^2 + 2*lambda*s;
        c = lambda + s - q.^2; % <-- important decision boundary
        gamma_potential = (c < 0) .* ...
            ((- b + sqrt( b.^2 - 4*a.*c )) ./ (2*a));
    end
    l_gamma =  - log(abs(1 + gamma.*s)) ...
        + (q.^2 .* gamma)./(1 + gamma.*s) ...
        - lambda*gamma; % omitted the factor 1/2
    % Contribution of each updated gamma(i) to L(gamma)
    l_gamma_potential = - log(abs(1 + gamma_potential.*s)) ...
        + (q.^2 .* gamma_potential)./(1 + gamma_potential.*s) ...
        - lambda*gamma_potential; % omitted the factor 1/2
    % Check how L(gamma) would change if we replaced gamma(i) by the
    % updated gamma_potential(i), for each i separately
    Delta_L_potential = l_gamma_potential - l_gamma;
    Delta_L_potential(deleted_indices) = -inf; % deleted indices should not be chosen again

    [Delta_L_max(it_counter), ind_L_max] = max(Delta_L_potential);
    
    % in case there is only 1 regressor in the model and it would now be
    % deleted
    if numel(active_indices) == 1 && ind_L_max == active_indices(1) ...
            && gamma_potential(ind_L_max) == 0
        Delta_L_potential(ind_L_max) = -inf;
        [Delta_L_max(it_counter), ind_L_max] = max(Delta_L_potential);
    end
    
    % If L did not change significantly anymore, break
    if Delta_L_max(it_counter) <= 0 || ...
            ( it_counter > 1 && ...
            all(abs(Delta_L_max(it_counter-1:it_counter)) ...
                < sum(Delta_L_max(1:it_counter))*eta_stop ))
        if verbose
            fprintf('Increase in L: %e (eta = %e) -- break\n', Delta_L_max(it_counter), eta_stop);
        
            plot(Delta_L_max, '-o');
            grid on
            set(gca, 'yscale', 'log')
        end
        break;
    end    
    
    if verbose
        fprintf('    Delta L = %e \n', Delta_L_max(it_counter))
    end
    what_changed = (gamma(ind_L_max) == 0) - (gamma_potential(ind_L_max) == 0);
    
    if verbose
        fprintf(2, '%d - ', it_counter);
        if what_changed < 0
            fprintf('Remove regressor')
        elseif what_changed == 0
            fprintf('Recompute regressor')
        else
            fprintf('Add regressor')
        end
        fprintf(' #%d..\n', ind_L_max)
    end
    
    % Update all quantities
    switch what_changed
        case 1 % adding a regressor
            % update gamma
            gamma(ind_L_max) = gamma_potential(ind_L_max);
            
            Sigma_ii = 1 / (1/gamma(ind_L_max) + S(ind_L_max));
            x_i = Sigma * PsiTPsi(active_indices, ind_L_max);
            tmp_1 = - (beta * Sigma_ii) * x_i;
            Sigma = [Sigma + (beta^2 * Sigma_ii) * (x_i * x_i') , tmp_1; ...
                tmp_1' , Sigma_ii];
            mu_i = Sigma_ii * Q(ind_L_max);
            mu = [mu - (beta * mu_i) * x_i; mu_i];
            
            tmp2 = beta * (PsiTPsi(:, ind_L_max) - beta * PsiTPsi(:, active_indices) * x_i)'; % row vector
            S = S - Sigma_ii * tmp2.^2;
            Q = Q - mu_i * tmp2;
            
            num_active = num_active + 1;
            ind_global_to_local(ind_L_max) = num_active; % local index
            active_indices = [active_indices, ind_L_max];
            bcs_path = [bcs_path ind_L_max];
            
        case 0
            % recomputation
            if ~ind_global_to_local(ind_L_max) % zero if regressor has not been chosen yet
                error('cannot recompute index %d -- not yet part of the model!', ind_L_max)
            end
            gamma_i_new = gamma_potential(ind_L_max);
            gamma_i_old = gamma(ind_L_max);
            % update gamma
            gamma(ind_L_max) = gamma_potential(ind_L_max);
            
            local_ind = ind_global_to_local(ind_L_max); % index of regressor in Sigma
            
            kappa_i = 1 / (Sigma(local_ind, local_ind) + 1/(1/gamma_i_new - 1/gamma_i_old));
            Sigma_i_col = Sigma(:, local_ind); % column of interest in Sigma
            
            Sigma = Sigma - kappa_i * (Sigma_i_col * Sigma_i_col');
            mu_i = mu(local_ind);
            mu = mu - (kappa_i * mu_i) * Sigma_i_col;
            
            tmp1 = beta * (Sigma_i_col' * PsiTPsi(active_indices,:)); % row vector
            S = S + kappa_i * tmp1.^2;
            Q = Q + (kappa_i * mu_i) * tmp1;
                        
            % no change in active_indices or ind_global_to_local
            bcs_path = [bcs_path ind_L_max + 0.1];
        case -1
            gamma(ind_L_max) = 0; % gamma_potential(ind_L_max);
            
            local_ind = ind_global_to_local(ind_L_max); % index of regressor in Sigma
            
            Sigma_ii_inv = 1 / Sigma(local_ind, local_ind); 
            Sigma_i_col = Sigma(:, local_ind); % column to be deleted in Sigma
            
            Sigma = Sigma - Sigma_ii_inv * (Sigma_i_col * Sigma_i_col');
            Sigma(:, local_ind) = [];
            Sigma(local_ind, :) = [];
            
            mu_i = mu(local_ind);
            mu = mu - (mu_i * Sigma_ii_inv) * Sigma_i_col;
            mu(local_ind) = [];
            
            tmp1 = beta * Sigma_i_col' * PsiTPsi(active_indices,:); % row vector
            S = S + Sigma_ii_inv * tmp1.^2;
            Q = Q + (mu_i * Sigma_ii_inv) * tmp1;
            
            num_active = num_active - 1;
            ind_global_to_local(ind_L_max) = 0;
            ind_global_to_local(ind_global_to_local > local_ind) = ind_global_to_local(ind_global_to_local > local_ind) - 1;
            active_indices(local_ind) = [];
            deleted_indices = [deleted_indices, ind_L_max]; % mark this index as deleted
            % and therefore ineligible
            bcs_path = [bcs_path -ind_L_max];
    end
    % same for all three cases 
    tmp3 = (1 - gamma .* S);
    s = S ./ tmp3;
    
    q = Q ./ tmp3;

    % Update lambda
    lambda = 2*(num_active - 1) / sum(gamma);
    
    % nu = 0 and beta = 1/sigma2 stay the same
    
    if it_counter > max_iterations
        break;
    end
    
end
if verbose; fprintf('it_counter = %d\n', it_counter); end

coeffs = zeros(P,1);
coeffs(active_indices) = mu;

results.coeffs = coeffs;
results.active_indices = active_indices;
results.gamma = gamma;
results.lambda = lambda;
results.it_counter = it_counter;
results.bcs_path = bcs_path;

end
