function X = uq_Kriging_helper_Scaling_UtoX(U,current_model)
% UQ_KRIGING_HELPER_SCALING_UTOX transforms a vector from the scaled input
% space to the original input space
%
% X = UQ_KRIGING_HELPER_SCALING_UTOX(U,CURRENT_MODEL) returns a vector of
% size N x M that is a transformation of the N x M vector U from the
% scaled space to the original one, according to the scaling options
% given in the Kriging model in CURRENT_MODEL.
%
%   - When an input object is not provided to Kriging, the transform is a 
%   simple linear one:
%           X = sigma_X * U + mu_X
%   - When an input object is provided to Kriging, an iso-probabilistic
%   transform is carried from a standard Gaussian distribution f_U to the 
%   distribution f_X in the provided input object:
%           X = F_X^(-1)[F_U(U)]


SCALING = current_model.Internal.Scaling;
    SCALING_BOOL = isa(SCALING, 'double') || isa(SCALING, 'logical') || ...
        isa(SCALING, 'int');

    if SCALING_BOOL && SCALING
        muX = current_model.Internal.ExpDesign.muX;
        sigmaX = current_model.Internal.ExpDesign.sigmaX;
        X = U.*sigmaX + muX ;
    elseif SCALING_BOOL && ~SCALING
        X = U;
    end

    if ~SCALING_BOOL
        % In that case, SCALING is an INPUT object.
        % An isoprobabilistic transform is performed
        % from: current_model.Internal.Input
        % to  : current_model.Internal.Scaling
        X = uq_GeneralIsopTransform(U,...
            SCALING.Marginals, SCALING.Copula, ...
            current_model.Internal.Input.Marginals,...
            current_model.Internal.Input.Copula);
    end

end