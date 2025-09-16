function varargout = uq_LRA_eval(X,module)

%% session retrieval, argument and consistency checks
if exist('module', 'var')
    current_model = uq_getModel(module);
else
    current_model = uq_getModel;
end

% Initialize variables
% Information on X_eval
N_eval = size(X,1); 
Y_eval = zeros(N_eval,current_model.Internal.Runtime.Nout);



% Currently the basis for each one of the vector outputs is the same.
% Therefore we simply set all the PolyTypes etc for all outputs equal to
% the first one.
for oo = 1:current_model.Internal.Runtime.Nout
    current_model.LRA(oo).Basis.PolyTypes = ...
        current_model.LRA(1).Basis.PolyTypes;
    current_model.LRA(oo).Basis.PolyTypesParams = ...
        current_model.LRA(1).Basis.PolyTypesParams;
    current_model.LRA(oo).Basis.PolyTypesAB = ...
        current_model.LRA(1).Basis.PolyTypesAB;
end


for oo = 1:current_model.Internal.Runtime.Nout
    p = current_model.LRA(oo).Basis.Degree; % polynomial degree
    z = current_model.LRA(oo).Coefficients.z; % polynomial coefficients
    b = current_model.LRA(oo).Coefficients.b; % normalizing constants
    M = length(current_model.Internal.Input.Marginals); % input dimension

    % Information on LRA
    R = current_model.LRA(oo).Basis.Rank; % rank    
    UnivBasis = current_model.LRA(oo).Basis;

    %% Get distributions in the standard space
    [PolyMarginals, PolyCopula] = uq_poly_marginals(UnivBasis.PolyTypes,UnivBasis.PolyTypesParams);

    %% Transform ED to the standard space
    U_eval = uq_GeneralIsopTransform(X, current_model.Internal.Input.Marginals, current_model.Internal.Input.Copula, PolyMarginals, PolyCopula);
    % take care of removing the constant terms
    nonConstIdx = current_model.Internal.Runtime.nonConstIdx;
    U_eval = U_eval(:,nonConstIdx);

    %% Evaluate orthonormal univariate polynomials at given set
    % remove the constants
    FNames = {'PolyTypes','PolyTypesParams','PolyTypesAB'};
    for fn = 1:length(FNames)
        UnivBasis.(FNames{fn}) = UnivBasis.(FNames{fn})(nonConstIdx);
    end

    P = uq_LRA_evalBasis(U_eval, UnivBasis, p);


    %% Evaluate LRA at given set

    w = ones(N_eval, R);

    for l = 1:R
        for i = 1:length(nonConstIdx)
            w(:,l) = (P{i}*z{l}(:,i)).*w(:,l);
        end
        Y_eval(:,oo) = Y_eval(:,oo)+b(l)*w(:,l);
    end
end

varargout{1} = Y_eval;

end
