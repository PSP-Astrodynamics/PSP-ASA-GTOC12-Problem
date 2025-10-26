function Y = uq_translateRF(X,RF, TargetDistrib)
% UQ_TRANSLATERF translates a  random field into an equivalent
% non-Gaussian one, i.e. by isoprobabilistically transforming the marginals
% and keeping the original Gaussian copula
% INPUT:
%   - X: Trajectories of the random field defined using RF
%   - RF: Random field object
%   - TaretDistrib: Target mariginal distributions (char -Should be one of
%   the marginals available in UQLab)
% OUTPUT:
%   - Y: Translated random field with marginals equal to TargetDistrib
%

% Get the marginals of the original random field
X_Marginals = RF.Internal.GlobalInput.Marginals ;

% Get the same marginals for the target distribution
Y_Marginals = RF.Internal.GlobalInput.Marginals ;

% Remove the parameters option: we only want the moments to match 
Y_Marginals = rmfield(Y_Marginals, 'Parameters') ;

% Create and check the existence of the moments to parameters filename
MtoP_identifier = 'MtoP' ;
MtoPfun = sprintf('uq_%s_%s', lower(TargetDistrib), MtoP_identifier) ;
MtoP_EXISTS = exist([MtoPfun, '.m'], 'file') | ...
    exist([MtoPfun, '.p'], 'file') ;
MtoPfun = str2func(MtoPfun);
if ~MtoP_EXISTS
    error('Calculation of parameters from moments is not defined for marginal type: %s!', ...
        marginals(ii).Type )
end

% Overwrite the type to the target dsitribution
Y_Marginals.Type = TargetDistrib ;

% Estimate the corresponding parameters option
Y_Marginals.Parameters = MtoPfun(Y_Marginals.Moments);

% Perform the transform
Y = uq_IsopTransform(X(:),X_Marginals,Y_Marginals) ;

% Reshape the output vector to be consistent with the inputs
Y = reshape(Y,size(X)) ;
end