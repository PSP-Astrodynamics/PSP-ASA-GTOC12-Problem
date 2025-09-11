function [AB] = uq_arbitrary_ml_integrator(maxdeg, Wx, bounds, CDFquantiles)
% AB = UQ_ARBITRARY_ML_INTEGRATOR(MAXDEG,WX,BOUNDS,CDFQUANTILES):
%   Compute recurrence terms up to a certain degree for polynomials 
%   orthonormal w.r.t. an arbitrary PDF. Implementation of the 'Stieltjes' 
%   procedure.
%
%   Numerical integration is performed using the matlab adaptive integrator
%   (2) for recurrence terms up to degree 'maxdeg' for the weighted inner 
%   product defined by 'WX' for the range defined by 'bounds'. Optionally,
%   in order to guide the integrator, CDFquantiles may be provided to be
%   used as way-points for the numerical integrator. The algorithm
%   was adapted from (1), where it refered as the "Stieltjes" procedure.
%
% Input Parameters:
%
%   'maxdeg'        The maximum degree of the polynomials implied by the
%                   recurrence terms computed.
%
%   'Wx'            A weight function (a PDF) as a function handle.
%
%   'bounds'        A 1x2 or 2x1 vector of doubles or inf, to set the bounds
%                   for the integrator
%
% Optional Input Parameters:
%
%   'CDFquantiles'  a vector of waypoints for the integrator. For example 
%                   They can be quantiles of the distribution considered.
%
% Return Values:
%
%   'AB'            A 2 x maxdeg matrix that contains the recurrence
%                   coefficients (elements of the Jacobi matrix for the
%                   arbitrary polynomials).
%
% References:
%
%   1) Gautschi, W. (2004). Orthogonal polynomials: computation and approximation.
%
%   2) L.F. Shampine, "Vectorized Adaptive Quadrature in Matlab",
%      Journal of Computational and Applied Mathematics 211, 2008, pp.131-140
%   
% See also INTEGRAL, UQ_POLY_REC_COEFFS, UQ_POLY_REC_COEFFS,
% UQ_PCE_INITIALIZE_PROCESS_BASIS, UQ_EVAL_REC_RULE

if ~exist('CDFquantiles','var')
    integral_fun = @(fun,bounddown,boundup) integral(fun,bounddown,boundup);
else
    integral_fun = @(fun,bounddown,boundup) integral(fun,bounddown,boundup,'Waypoints',CDFquantiles);
end

%% The AB matrix:
% No preallocation of AB is necessary since the function that uses it to
% calculate the polynomials (uq_eval_rec_rule) uses the size of the matrix
% to infer the requested degree. The matrix is not huge anyway so this is
% not a significant performance hit.
b0 = integral_fun(@(x) Wx(x')' , bounds(1),bounds(2));
AB = [0 1./sqrt(b0)];



%% calculate recurrence coefficients up to the requested degree:
for ii=1:maxdeg
    % Evaluate the polynomials with the recurrence rule
    a_num_new = @(x) Wx(x')' .* x .* uq_eval_rec_rule(x', AB, 1)'.^2 ;
    a_num_int_new = integral_fun(a_num_new,bounds(1),bounds(2));

    an_new = a_num_int_new ;
    
    AB(ii,1) = an_new;
    
    %% Please insert clearer comments
    % I need to increment AB here.
    % I need a non-normalized b_n for 
    % <p_{n+1},p_{n+1}> 
    AB = [AB ; 0 1];
    
    %% Computation of the P_k+1 non normalized polynomial
    P_k_plus_one= @(x) uq_eval_rec_rule(x',AB(1:(end),:),1)';
    
    %% Find b_k+1 for the next iteration from the normalization
    bn_plus_one_new = integral_fun(@(x) Wx(x')' .* P_k_plus_one(x).^2, ...
        bounds(1),bounds(2));
    
    % Store the recursion coefficient:
    AB(end,2) = sqrt(bn_plus_one_new);
    
end

% Remove the last row because it contains useless (incomplete) info
AB = AB(1:end-1,:);
if any(any(isnan(AB)))
    deg =     find(isnan(AB(:,1)));
    error(sprintf('The integration for the recurrence coefficients returned NaN for degree %d!\n',deg));
end
% And because we integrate for a PDF:
AB(1,2) = 1;