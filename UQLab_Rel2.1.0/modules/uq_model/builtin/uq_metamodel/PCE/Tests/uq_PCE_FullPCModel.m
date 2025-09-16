function Y = uq_PCE_FullPCModel( X )
% Y = UQ_PCE_FULLPCMODEL(X): internal function used in several PCE
%     selftests. Builds a random PCE predictor that can be used to assess the
%     functionality of several PCE calculation strategies

myModel = uq_getModel('TestPCModel');
pTypes = myModel.Internal.pTypes ;


y_a = myModel.Internal.y_a ;
Alphas = myModel.Internal.Alphas;
p = max(Alphas(:));

P = size(Alphas,1);
M = length(pTypes);
N = size(X,1);

U = X ;
%% ok, now on to calculating the univariate polynomials
univ_p_val = zeros(N,M, p+1);
% evaluating the univariate polynomials in the experimental design
for ii = 1:M
    switch lower(pTypes{ii})
        case 'legendre' 
            univ_p_val(:,ii,:) = uq_eval_legendre(p, U(:,ii));
        case 'hermite'
            univ_p_val(:,ii,:) = uq_eval_hermite (p, U(:,ii));
        case 'laguerre'
            gammapars = myModel.Internal.myInput.Marginals(ii).Parameters;
            univ_p_val(:,ii,:) = uq_eval_laguerre(p, U(:,ii), gammapars);
        case 'jacobi'
            betapars = myModel.Internal.myInput.Marginals(ii).Parameters;
            univ_p_val(:,ii,:) = uq_eval_jacobi(p, U(:,ii ),betapars);
        case 'arbitrary'
            % Get the pdf and the parameters, calculate the recurrence
            % terms, and then calculate the univariate polynomials:
            marginal = myModel.Internal.myInput.Marginals(ii);
            AB = uq_PCE_initialize_basis(marginal,'Stieltjes','polynomials');
            univ_p_val(:,ii,:) = uq_eval_rec_rule(U(:,ii),AB);
    end
end

Y = zeros(N,1);
for aa = 1 : P
    Indices = full(Alphas(aa,:));
    Psi = ones(N,1) ;
    for mm = find(Indices)
        Psi = Psi .* univ_p_val(:,mm,Indices(mm)+1);     
    end
    Y = Y + Psi*y_a(aa);
end

