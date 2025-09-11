function uq_lra_metamodel = uq_PCE_to_LRA(uq_pce_metamodel,nranks,als_params)
% Takes as input a PCE model and returns an admissible 
% equivalent LRA model. The solution might not be unique and it also might
% not be very accurate.
% 
% Depends on functionality from:
%-----------------------------------------------------------------%
% Tensor Toolbox (Sandia National Labs)                           %
% Version 2.6 06-FEB-2015                                         %
% Tensor Toolbox for dense, sparse, and decomposed n-way arrays.  %
%-----------------------------------------------------------------%

if ~exist('nranks','var')
    nranks=2;
end

if ~exist('als_params','var')
    niters_als = 1e3;
    tol_als = 1e-15;
else
    niters_als = als_params.niters;
    tol_als = als_params.tol;
end

pce_model = uq_pce_metamodel.PCE;

% I have the coefficients from 
pce_coeffs = pce_model.Coefficients;
pce_idx          = pce_model.Basis.Indices;
max_deg = max(pce_model.Basis.MaxCompDeg);
M = length(pce_model.Basis.MaxCompDeg);

% The LRA (CP decomposition) tensor will constain M^(max_degree) elements
LRAcoeffs_kroned = sptensor(full(pce_idx)+1,pce_coeffs,repmat(max_deg+2,1,M));

% Now calculate the LRA of the PCE. Maybe we can perform CV for ranks.
LRA_coefficients_raw = cp_als(LRAcoeffs_kroned,nranks,'tol',tol_als,'maxiters',niters_als);

% Manage options:
lraopts.Degree = max_deg;
lraopts.Type = 'metamodel';
lraopts.MetaType = 'lra';

% Normally here I should loop over LRA output dimensions.
lraopts.LRA.Basis.PolyTypes      = pce_model.Basis.PolyTypes;
lraopts.LRA.Basis.PolyTypesParams = pce_model.Basis.PolyTypesParams;
lraopts.LRA.Basis.PolyTypesAB    = pce_model.Basis.PolyTypesAB;
lraopts.LRA.Coefficients.z = cell(nranks,1);
lraopts.LRA.Coefficients.b = LRA_coefficients_raw.lambda;
lraopts.LRA.Rank = nranks;
lraopts.LRA.Degree = max_deg+1;

lraopts.Input = uq_pce_metamodel.Internal.Input;
lraopts.Method = 'custom';

for r = 1:nranks
    for m = 1:M
        lraopts.LRA.Coefficients.z{r} = [lraopts.LRA.Coefficients.z{r}, LRA_coefficients_raw.u{m}(:,r)];
    end
end

uq_lra_metamodel = uq_createModel(lraopts);