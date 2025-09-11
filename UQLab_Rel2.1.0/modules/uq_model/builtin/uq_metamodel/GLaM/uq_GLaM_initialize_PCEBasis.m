function [current_model] = uq_GLaM_initialize_PCEBasis(current_model)
%% use existing function
% [current_model, Options]= uq_initialize_uq_metamodel_univ_basis(current_model, Options);

% cache the auxiliary space info
% [current_model.Internal.ED_Input.Marginals, current_model.Internal.ED_Input.Copula] = ...
%                     uq_poly_marginals(current_model.Internal.Basis.PolyTypes, current_model.Internal.Basis.PolyTypesParams);
%% build a PCE and then retrieve the necessary information
% retrieve the maximum degree
maxDeg = current_model.Internal.Basis.maxDeg;

AuxMetaOpt = current_model.Internal.Lambda(1);
if isfield(AuxMetaOpt,'Transform')
    AuxMetaOpt = rmfield(AuxMetaOpt,'Transform');
end
AuxMetaOpt.Type = 'Metamodel';
AuxMetaOpt.MetaType = 'PCE';
AuxMetaOpt.Method = 'OLS';
AuxMetaOpt.TruncOptions.Custom = [maxDeg,zeros(1,current_model.Internal.Runtime.MnonConst-1)];
AuxMetaOpt.Input = current_model.Internal.Input;
AuxMetaOpt.Display = 'quiet';
AuxMetaOpt.ExpDesign.X = uq_getSample(AuxMetaOpt.Input,1);
AuxMetaOpt.ExpDesign.Y = 0;
AuxPCE = uq_createModel(AuxMetaOpt,'-private');
current_model.Internal.Basis = AuxPCE.PCE.Basis;
current_model.Internal.ED_Input=AuxPCE.Internal.ED_Input;
end


