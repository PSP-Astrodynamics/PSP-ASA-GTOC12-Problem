function Y = uq_translateRF_FromGaussian(X,RF, TargetDistrib)
% UQ_TRANSLATERF_FROMGAUSSIAN translates a Gaussian random field into an equivalent
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

% Get the marginals of the global distribution
X_Marginals = RF.Internal.GlobalInput.Marginals ;

% Overwrite the X_Marignals and make sure they are Gaussian (this
% function is only for interanl use - transforming Gaussian RF to any other
% marginals
X_Marginals.Type = 'Gaussian' ;

% Update the parameters option: we only want the moments to match 
X_Marginals.Parameters = uq_gaussian_MtoP(X_Marginals.Moments) ;

% Get the same marginals for the target distribution
Y_Marginals = RF.Internal.GlobalInput.Marginals ;

% Remove the parameters option: we only want the moments to match 
Y_Marginals = rmfield(Y_Marginals, 'Parameters') ;

% Create and check the existence of he moments to parameters filename
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

% Estimate the corresponding the parameters option
Y_Marginals.Parameters = MtoPfun(Y_Marginals.Moments);

% Perform the transform
Y = uq_IsopTransform(X(:),X_Marginals,Y_Marginals) ;

% Reshape the output vector to be consistent with the inputs
Y = reshape(Y,size(X)) ;
end