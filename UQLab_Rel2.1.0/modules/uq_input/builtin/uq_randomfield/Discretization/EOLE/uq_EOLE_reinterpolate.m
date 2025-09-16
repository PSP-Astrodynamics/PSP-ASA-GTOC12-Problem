function RhoPhi = uq_EOLE_reinterpolate(current_input,X,RF,myKriging)
% UQ_EOLE_REINTERPOLATE reinterpolates the eigenvectors of the
% eigen-decomposition of the correlation matrix on a new mesh
%
% INPUT
%   - current_input: current random field input object
%   - X: New mesh on which to reinterpolate the eigenvectors
%   - RF: Calculated options of the current random field
%   - myKriging (optional): Gaussian process model we are resampling from

% Get the options of the current input object
Options = current_input.Internal ;

% Discretization mesh
CovMesh = RF.CovMesh ;

% Check if a GP model has been provided or not
isKriging = true ;
if nargin < 4
    isKriging = false ;
    if nargin < 3
        error('EOLE: Insufficient number of inputs');
    end
end

% Calculate the cross-correlation/cross-covariance between the new points X
% and the discretization mesh CovMesh
if isKriging
    % Posterior cross-covariance
    Rho_vV = uq_Kriging_calc_PosteriorCovariance(X,CovMesh,myKriging) ;

else

    if isempty(Options.RFData) % Unconditional random field

        % Cross-correlation
        Rho_vV = uq_eval_Kernel(X, CovMesh, Options.Corr.Length, Options.Corr) ;

    else % Conditional random field

        % Get the inverse correlation matrix on the observation points 
        Rinv = RF.Rinv ;

        % Compute the posterior cross-correlation matrix
        % Rho_vV = R(v,V) - R(v,X) * Rinv * R(X,V), with X being the
        % locations of the observation points
        Rho_vV = uq_eval_PosteriorCorrelationMatrix(X, CovMesh, ...
            Options.RFData.X, Options.Corr.Length, Options.Corr, Rinv) ;

    end
end

% Get the re-interpolated eigenvectors. 
RhoPhi = Rho_vV*RF.Phi ;

end

