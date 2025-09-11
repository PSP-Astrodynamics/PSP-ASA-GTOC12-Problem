function Phi = uq_KL_reinterpolate(current_input, X, RF, myKriging)

Options = current_input.Internal ;
% The mesh is the one from the discretization one
CovMesh = RF.KL.Coor ;
% Eigenvectors are also the ones from the original discretization
Phi = RF.KL.Phi_Original ;

% Check whether a GP model has been provided or not
isKriging = true ;
if nargin < 4
    isKriging = false ;
    if nargin < 3
        error('EOLE: Insufficient number of inputs');
    end
end

%% 
% Calculate the cross-correlation/cross-covariance between the new points X
% and the discretization mesh CovMesh
if isKriging
    % Posterior cross-covariance
    Rho_vV = uq_Kriging_calc_PosteriorCovariance(X,CovMesh,myKriging) ;

else

    if isempty(Options.RFData)
        % Calculate the cross-correlation matrix on mesh
        Rho_vV = uq_eval_Kernel(X, CovMesh, Options.Corr.Length, Options.Corr) ;

    else
        % Get the inverse correlation matrix on the observation points
        Rinv = RF.Rinv ;

        % Is it Coor or CovMesh - find the right way to do this!
        % Compute the posterior cross-correlation matrix
        % Rho_vV = R(v,V) - R(v,X) * Rinv * R(X,V), with X being the
        % locations of the observation points
        Rho_vV = uq_eval_PosteriorCorrelationMatrix(X, CovMesh, ...
            Options.RFData.X, Options.Corr.Length, Options.Corr, Rinv) ;
    end


end

%% Re-interpolate the eigenvectors

ExpOrder = RF.ExpOrder ;

switch lower(Options.KL.Method)
    case {'pca','discrete'} % not recommended!
        % Re-interpolate the eigenvectors on the new mesh
        % using spline interpolation
        Phi = spline(CovMesh',Phi', X')' ;


    case {'nystrom'}
        % Re-interpolate eigenvectors on the new mesh
        Phi = uq_KL_reinterpolateNystrom(RF.KL.weights, ...
            RF.Eigs,Phi,Rho_vV, ExpOrder) ;

    otherwise

        error('Unknown KL discretization method!')
end

end