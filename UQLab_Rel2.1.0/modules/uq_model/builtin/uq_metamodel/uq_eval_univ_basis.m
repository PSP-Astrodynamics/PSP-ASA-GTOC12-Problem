function univ_basis_vals = uq_eval_univ_basis(U, BasisParameters)
% A function to evaluate univariate regressors along input directions. It
% should be used by all modules with some module specific wrappers.

if isfield(BasisParameters, 'PolyTypes') && isfield(BasisParameters,'PolyTypesParams')
    PolyTypes = BasisParameters.PolyTypes;
    PolyTypesParams = BasisParameters.PolyTypesParams;
    MaxDegrees = BasisParameters.MaxDegrees;
end

if isfield(BasisParameters, 'PolyTypes') && ~isfield(BasisParameters,'PolyTypesParams')
    warning('The uq_eval_univ_basis did not find polynomial parameters. If you used Laguerre Jacobi or Arbitrary basis this will result to an error.');
    PolyTypes = BasisParameters.PolyTypes;
    MaxDegrees = BasisParameters.MaxDegrees;
end

    

% The number of samples for pre-allocation is deduced from the 
% number of rows in U:
N = size(U,1);
M = size(U,2);
P = MaxDegrees;

%% ok, now on to calculating the univariate polynomials
% allocate the output matrix
univ_vals = zeros(N,M, P+1);
for i = 1:M
    switch lower(PolyTypes{i})
        case 'legendre' 
            univ_vals(:,i,:) = uq_eval_legendre(P, U(:,i));
        case 'hermite'
            univ_vals(:,i,:) = uq_eval_hermite (P, U(:,i));
        case 'laguerre'
            parms = PolyTypesParams{i};
            univ_vals(:,i,:) = uq_eval_laguerre(P,U(:,i),[parms(1) parms(2)]);
        case 'jacobi'
            parms = PolyTypesParams{i};
            univ_vals(:,i,:) = uq_eval_jacobi(P,U(:,i),[parms(1) parms(2) 0 1]);
        case {'arbitrary','arbitraryprecomp'}
            % Since the 'arbitrary' case will need directly the recurrence
            % rules, and one might not have already computed them while
            % using this function, they are taken directly from the field
            % where they are supposed to be computed.
            AB = BasisParameters.PolyTypesAB{i}{1};
            AB = AB(1:(P+1),:);
            univ_vals(:,i,:) = uq_eval_rec_rule(U(:,i),AB);
        case 'fourier'
            % of course not polynomials but sines and cosines.
            univ_vals(:,i,:) = uq_eval_spectral(P+1,U(:,i),...
                BasisParameters.PolyTypesParams{i});
    end
end

% Return the evaluations of U along each univariate basis:
univ_basis_vals = univ_vals;