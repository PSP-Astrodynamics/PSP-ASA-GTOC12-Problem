function U = uq_Kriging_helper_Scaling_XtoU(X,current_model)
% UQ_KRIGING_HELPER_SCALING_XTOU transforms a vector from the original 
% input space to the scaled input space
%
% U = UQ_KRIGING_HELPER_SCALING_XTOU(X,CURRENT_MODEL) returns a vector of
% size N x M that is a transformation of the N x M vector X from the
% original space to the scaled one, according to the scaling options
% given in the Kriging model in CURRENT_MODEL.
%
%   - When an input object is not provided to Kriging, the transform is a 
%   simple linear one:
%           U = (X - mu_X) / sigma_X 
%   - When an input object is provided to Kriging, an iso-probabilistic
%   transform is carried from the distribution f_X in the provided input 
%   object to a standard Gaussian distribution f_U: 
%           U = F_U^(-1)[F_X(X)]


SCALING = current_model.Internal.Scaling;
SCALING_BOOL = isa(SCALING, 'double') || isa(SCALING, 'logical') || ...
    isa(SCALING, 'int');

if SCALING_BOOL && SCALING
    muX = current_model.Internal.ExpDesign.muX;
    sigmaX = current_model.Internal.ExpDesign.sigmaX;
    U = bsxfun(@rdivide, (bsxfun(@minus, X, muX)), sigmaX);
elseif SCALING_BOOL && ~SCALING
    U = X;
end

if ~SCALING_BOOL
    % In that case, SCALING is an INPUT object.
    % An isoprobabilistic transform is performed
    % from: current_model.Internal.Input
    % to  : current_model.Internal.Scaling
    U = uq_GeneralIsopTransform(X,...
        current_model.Internal.Input.Marginals,...
        current_model.Internal.Input.Copula,...
        SCALING.Marginals, SCALING.Copula);
end


end