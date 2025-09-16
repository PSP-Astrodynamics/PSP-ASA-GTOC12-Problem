function coeffs = uq_sp(Psi, Y, K, Options)
% COEFFS = UQ_SP(PSI, Y, K, OPTIONS): Sparse regression with subspace pursuit
% with a given number of nonzeros K
%
% This implementation follows the pseudocode for subspace pursuit published
% in Alg. 1 of
% P. Diaz, A. Doostan & J. Hampton (2018): Sparse polynomial chaos 
% expansions via compressed sensing and D-optimal design. Computer Methods 
% in Applied Mechanics and Engineering, 336, p. 640-666.
% https://doi.org/10.1016/j.cma.2018.03.020
% 
% The argument OPTIONS is checked for the following fields:
%     .Hybrid = 0 / 1 --- If a constant regressor exists in the candidate
%                         set of regressors, it is always included in the
%                         final expansion (same idea as for hybrid-LARS).
%                         The remaining regressors are centered.
%                          
%     .Normalize = 0 / 1 --- Normalize the columns of Psi to have unit norm
%                         before the SP algorithm is applied.

[N, P] = size(Psi);
if K > floor(min(N/2, P/2))
    warning('UQ_SP: the specified K = %d is too large, set to %d', K, floor(min(N/2, P/2)));
    K = floor(min(N/2, P/2));
end

bool_hybrid = 0;
bool_normalize = 0;
if nargin > 3
    if isfield(Options, 'Hybrid')
        % special treatment of constant regressor
        bool_hybrid = Options.Hybrid;
    end
    if isfield(Options, 'Normalize')
        bool_normalize = Options.Normalize;
    end
end

% Look for constant regressors
const_idx_logicals = ~any(diff(Psi, 1));
bool_const = any(const_idx_logicals);
const_indices = find(const_idx_logicals);
if ~bool_const 
    bool_hybrid = 0;
    % cannot add constant regressor if it is not part of the basis
end

if bool_hybrid
    mu_Psi = mean(Psi, 1);
    Psi = Psi - mean(Psi);

    mu_Y = mean(Y);
    Y = Y - mu_Y;
    K = K - 1; % one of the selected regressors will be the constant one
end

if bool_normalize
    % Normalize columns of Psi (each basis function should have norm = 1)
    normPsi = sqrt(sum(Psi.^2, 1) / N);
    nznorm_indices = (normPsi~=0); % indices with nonzero norm
    Psi(:, nznorm_indices) = Psi(:, nznorm_indices)./repmat(normPsi(nznorm_indices), N, 1);
end

max_num_iterations = P;
it_counter = 0;

%[~, S_prev] = maxk(Psi'*Y, K, 'ComparisonMethod', 'abs'); % most correlated set
[~, S_prev] = sort(abs(Psi'*Y),'descend');
S_prev = S_prev(1:K);

c_prev = mldivide(Psi(:, S_prev), Y); % solution
r_prev = Psi(:, S_prev) * c_prev - Y; % residual vector


while true
    it_counter = it_counter + 1;
    % augment set of candidate indices by K 
    %[~, S_add] = maxk(Psi'*r_prev, K, 'ComparisonMethod', 'abs'); % K additional regressors
    [~, S_add] = sort(abs(Psi'*r_prev),'descend');
    S_add = S_add(1:K);
    c_large = zeros(P, 1);
    c_large([S_prev; S_add]) = mldivide(Psi(:, [S_prev; S_add]), Y); % solution with 2K regressors
    
    %[~, S_new] = maxk(c_large, K, 'ComparisonMethod', 'abs'); % largest-in-magnitude coeffs
    [~, S_new] = sort(abs(c_large),'descend');
    S_new = S_new(1:K);
    c_new = mldivide(Psi(:, S_new), Y); % solution with current regressors
    r_new = Psi(:, S_new) * c_new - Y; % residual vector
    
    
    if it_counter == max_num_iterations
        break;
    end
    if all(sort(S_new) == sort(S_prev))
        % set of selected regressors converged (no change)
        break;
    end
    if norm(r_new) > norm(r_prev)
        % last iteration deteriorated the solution -- restore the previous
        % values
        S_new = S_prev;
        c_new = c_prev;
        break;
    end
    
    % If we didn't break from the while loop, execution continues.
    % For the next iteration, the new values become the old ones
    S_prev = S_new;
    r_prev = r_new;
    c_prev = c_new;
    
end

if bool_hybrid && ~ismember(const_indices(1), S_new)
    % add the constant regressor to the selected set
    S_new = [S_new; const_indices(1)];
%     K = K+1;
end

if bool_normalize
    % Scale the whole Psi back to original vecnorms
    Psi(:, nznorm_indices) = Psi(:, nznorm_indices).*repmat(normPsi(nznorm_indices), N, 1);
end

if bool_hybrid
    Y = Y + mu_Y;
    Psi = Psi + repmat(mu_Psi,N,1);
end

if bool_normalize || bool_hybrid
    % Psi changed, recompute the solution
    c_new = mldivide(Psi(:, S_new), Y);
end

coeffs = zeros(P, 1);
coeffs(S_new) = c_new;

end

