function [coefZ,Zdegree] = uq_SPCE_LatentPCECoeff(mySPCE,X,outidx)
%% Compute the coefficients and degree information of the latent PCE
% more precisely, for a given value x of the input, we have the latent PCE
% model of the format $Y = \sum_{d=0}^{D} c_d(x)\phi_d(Z) + \epsilon$
% ----- Input -----
% mySPCE: the overall SPCE model
% X: the point where the coefficients should be evaluated
% outidx: the output index to evaluate the coefficients
% ----- output -----
% coefZ: matrix of size D*N where coefZ(i,j) is the coefficient assciated
% with the degree Zdegree(i) at the point X_j 
% Zdegree: an array of the degrees in the expansion of Z

% Pre-define the options for the auxiliary PCE
AuxMetaOpts.Type = 'Metamodel';
AuxMetaOpts.MetaType = 'PCE';
AuxMetaOpts.Method = 'Custom';
AuxMetaOpts.Input = mySPCE.Internal.Input;

% retrieve the information of the expansion
Coefficients = mySPCE.SPCE(outidx).Coefficients;
indNonZero = Coefficients~=0;
indices = mySPCE.SPCE(outidx).Basis.Indices(indNonZero,:);
Coefficients = Coefficients(indNonZero);

% extract the information about the latent variable
[Zdegree,~,ZdegreeInd] = unique(full(indices(:,end)));
NZdegree = length(Zdegree);

% build auxiliary PCE to evaluate the coefficients
if isfield(AuxMetaOpts,'PCE')
    AuxMetaOpts = rmfield(AuxMetaOpts,'PCE');
end
for iz = 1:NZdegree
    AuxMetaOpts.PCE(iz).Basis.PolyTypes = mySPCE.SPCE(outidx).Basis.PolyTypes(1:end-1);
    AuxMetaOpts.PCE(iz).Basis.PolyTypesParams = mySPCE.SPCE(outidx).Basis.PolyTypesParams(1:end-1);
    indtmp = ZdegreeInd==iz;
    AuxMetaOpts.PCE(iz).Basis.Indices = indices(indtmp,1:end-1);
    AuxMetaOpts.PCE(iz).Coefficients = Coefficients(indtmp);
end
PCECoef = uq_createModel(AuxMetaOpts,'-private');
coefZ = uq_evalModel(PCECoef,X)';
end

