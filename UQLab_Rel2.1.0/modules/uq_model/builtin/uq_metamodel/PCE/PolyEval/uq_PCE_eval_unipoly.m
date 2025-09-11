function univ_p_val = uq_PCE_eval_unipoly(current_model, U)
% UNIV_P_VAL = UQ_PCE_EVAL_UNIPOLY(CURRENT_MODEL,U) evaluate the univariate
%     polynomials defined in CURRENT_MODEL on the sample of the reduced
%     space U.
%
% See also: UQ_PCE_EVAL,UQ_PCE_CREATE_PSI

%% Retrieve the necessary information
%  get the current ouput from runtime infoP,M;U
current_output = current_model.Internal.Runtime.current_output;
% Retrieve the corresponding polynomial types
PolyTypes = current_model.PCE(current_output).Basis.PolyTypes(current_model.Internal.Runtime.nonConstIdx);
% Maximum degree
P = full(max(current_model.PCE(current_output).Basis.Indices(:)));
% Number of components
M = current_model.Internal.Runtime.MnonConst;

% if called with a 'U' argument, evaluate the polynomials on the specified values
if exist('U', 'var')
    N = size(U,1);
else
    N = current_model.ExpDesign.NSamples;
    % Get the relevant components only
    U = current_model.ExpDesign.U(:,current_model.Internal.Runtime.nonConstIdx);
end

nonConstIdx = current_model.Internal.Runtime.nonConstIdx;
% Collect the 'BasisParameters':
BasisParameters(1).PolyTypes = current_model.PCE(1).Basis.PolyTypes(nonConstIdx);
BasisParameters(1).PolyTypesParams = current_model.PCE(1).Basis.PolyTypesParams(nonConstIdx);
BasisParameters(1).PolyTypesAB     = current_model.PCE(1).Basis.PolyTypesAB(nonConstIdx);
BasisParameters(1).MaxDegrees      = P;
univ_p_val = uq_eval_univ_basis(U, BasisParameters);
