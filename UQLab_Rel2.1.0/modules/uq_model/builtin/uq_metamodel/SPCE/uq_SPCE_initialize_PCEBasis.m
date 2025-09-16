function current_model = uq_SPCE_initialize_PCEBasis(current_model)
%% Initialize the PCE options for both the input and the latent variables


%% build a PCE for the input and then retrieve the necessary information
% retrieve the maximum degree
maxDeg = current_model.Internal.SPCE.Basis.maxInputDeg;

AuxMetaOpt.Type = 'Metamodel';
AuxMetaOpt.MetaType = 'PCE';
AuxMetaOpt.Method = 'OLS';
if uq_isnonemptyfield(current_model.Options,'PolyTypes')
    AuxMetaOpt.PolyTypes = current_model.Options.PolyTypes;
elseif uq_isnonemptyfield(current_model.Internal.SPCE.MeanReg,'PolyTypes')
     AuxMetaOpt.PolyTypes = current_model.Internal.SPCE.MeanReg.PolyTypes;
end
if uq_isnonemptyfield(current_model.Options,'PolyTypesParams')
    AuxMetaOpt.PolyTypesParams = current_model.Options.PolyTypesParams;
elseif uq_isnonemptyfield(current_model.Internal.SPCE.MeanReg,'PolyTypes')
     AuxMetaOpt.PolyTypesParams = current_model.Internal.SPCE.MeanReg.PolyTypesParams;
end
AuxMetaOpt.TruncOptions.Custom = [maxDeg,zeros(1,current_model.Internal.Runtime.MnonConst-1)];
AuxMetaOpt.Input = current_model.Internal.Input;
AuxMetaOpt.Display = 'quiet';
AuxMetaOpt.ExpDesign.X = uq_getSample(AuxMetaOpt.Input,1);
AuxMetaOpt.ExpDesign.Y = 0;
AuxPCE = uq_createModel(AuxMetaOpt,'-private');

current_model.Internal.SPCE.Basis.InputPolyTypes = AuxPCE.PCE.Basis.PolyTypes;
current_model.Internal.SPCE.Basis.InputPolyTypesParams = AuxPCE.PCE.Basis.PolyTypesParams;
current_model.Internal.SPCE.Basis.InputPolyTypesAB = AuxPCE.PCE.Basis.PolyTypesAB;
current_model.Internal.ED_Input=AuxPCE.Internal.ED_Input;

%% build a latent PCE and then retrieve the necessary information
% retrieve the maximum degree
maxDeg = current_model.Internal.SPCE.Basis.maxLatentDeg;
NCandidateLatent = current_model.Internal.SPCE.Latent.NCandidateLatent;

AuxLatentOpt.Type = 'Metamodel';
AuxLatentOpt.MetaType = 'PCE';
AuxLatentOpt.Method = 'OLS';
if isfield(current_model.Options,'Latent')
    if uq_isnonemptyfield(current_model.Options.Latent,'PolyTypes')
        AuxLatentOpt.PolyTypes = current_model.Options.Latent.PolyTypes;
    end
    if uq_isnonemptyfield(current_model.Options.Latent,'PolyTypesParams')
        AuxLatentOpt.PolyTypesParams = current_model.Options.Latent.PolyTypesParams;
    end
end
AuxLatentOpt.Input = current_model.Internal.SPCE.Latent.Dist;
AuxLatentOpt.TruncOptions.Custom = [maxDeg,zeros(1,NCandidateLatent-1)];
AuxLatentOpt.Display = 'quiet';
AuxLatentOpt.ExpDesign.X = uq_getSample(AuxLatentOpt.Input,1);
AuxLatentOpt.ExpDesign.Y = 0;
AuxPCE = uq_createModel(AuxLatentOpt,'-private');

current_model.Internal.SPCE.Basis.LatentPolyTypes = AuxPCE.PCE.Basis.PolyTypes;
current_model.Internal.SPCE.Basis.LatentPolyTypesParams = AuxPCE.PCE.Basis.PolyTypesParams;
current_model.Internal.SPCE.Basis.LatentPolyTypesAB = AuxPCE.PCE.Basis.PolyTypesAB;

current_model.Internal.ED_LatentDist = AuxPCE.Internal.ED_Input;
end


