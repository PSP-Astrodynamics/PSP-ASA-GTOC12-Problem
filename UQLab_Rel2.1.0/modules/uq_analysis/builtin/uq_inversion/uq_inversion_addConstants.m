function xAug = uq_inversion_addConstants(x,ConstInfo)
% UQ_INVERSION_ADDCONSTANTS augments a sample with constant values
%   
%   XAUG = UQ_INVERSION_ADDCONSTANTS(X, CONSTINFO, PMAP)
%   augments the sample in X with the constant values in CONSTINFO
%
%   Additional notes:
%
%   - This function is only required if the prior distribution contains
%     constants and then serves as a wrapper before the forward model is
%     evaluated.

% Initialize
idConst = ConstInfo.idConst;
valConst = ConstInfo.valConst;
idFull = ConstInfo.idFull;
PMap = ConstInfo.PMap;

% Assign to xAug
xAug(:,idFull) = x;      % Variable parameters
xAug(:,idConst) = repmat(valConst,size(x,1),1);  % Constant parameters

% extract relevant from PMap
xAug = xAug(:,PMap);