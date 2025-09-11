function RF = uq_createRF( current_input )
% UQ_CREATERF: Discretizes a random field using either KL or EOLE methods

% Retrieve the options that were initialized previously
Options = current_input.Internal ;

% Domain of the decomposition
Domain = current_input.Internal.Domain ;

% Mesh used for the representation (sampling) of the RF
Mesh = current_input.Internal.Mesh ;

% Coordinates where the correlation matrix is constructed
Coor = current_input.Internal.CovMesh ;

% Expansion order
ExpOrder = current_input.Internal.ExpOrder ;

% Energy ratio
EnergyRatio = current_input.Internal.EnergyRatio ;

% Properties of the correlation matrix (family, isotropy,
% length)
Corr = current_input.Internal.Corr ;

% Correlation length
CorrLength = Corr.Length ;

% Observations, if any
Data = current_input.Internal.RFData ;

if current_input.Internal.Runtime.isKriging
    myKriging = current_input.Internal.RFModel ;
end

%% 1. Perform the actual discretization
switch lower( Options.DiscScheme )
    case   'kl'
        switch lower(Options.KL.Method)

            case 'analytical'

                % Compute the eigen-values and -vectors analytically
                RF  =  uq_KL_analytical(Domain, Mesh, CorrLength, ExpOrder, EnergyRatio);

            case 'nystrom'

                % Options specific to Nystrom: Quadrature type and
                % levels (number of samples)
                opts = current_input.Internal.KL ;
                if ~current_input.Internal.Runtime.isKriging
                    if isempty(Data)
                        RF = uq_KL_Nystrom(Domain, Mesh, Corr, ExpOrder, EnergyRatio, opts,[]) ;
                    else

                        RF = uq_KL_Nystrom(Domain, Mesh, Corr, ExpOrder, EnergyRatio, opts, Data.X) ;

                    end
                else

                    % Calculate the eigenvalue decomposition of the
                    % covariance using Nystrom approach
                    RF = uq_KL_Nystrom(Domain, Mesh, Corr, ExpOrder, EnergyRatio, opts, [], current_input.Internal.RFModel) ;

                end

            case {'discrete','pca'}
                if ~current_input.Internal.Runtime.isKriging
                    RF = uq_KL_Discrete(Mesh, Corr, ExpOrder, EnergyRatio) ;
                else
                    % Get the posterior covariance on the discretization
                    % mesh points
                    [~,~,postCov] = uq_evalModel(current_input.Internal.RFModel,Coor);

                    % Calculate the eigenvalue decomposition of the covariance using PCA
                    RF = uq_KL_Discrete(postCov, ExpOrder, EnergyRatio) ;
                end



        end



    case 'eole'

        if ~current_input.Internal.Runtime.isKriging
            if isempty(Data)

                RF = uq_EOLE(Coor, Mesh, Corr, ExpOrder, EnergyRatio,[]) ;

            else

                RF = uq_EOLE(Coor, Mesh, Corr, ExpOrder, EnergyRatio,Data.X) ;

            end


        else
            
            % Run EOLE using a Kriging model to calculate the covariance
            RF = uq_EOLE(Coor, Mesh, Corr, ExpOrder, EnergyRatio,[],current_input.Internal.RFModel) ;
        end

end

% post-processing:
% Create a unique variable containing the mesh actually used to compute the
% covariance matrix
if strcmpi(Options.DiscScheme,'kl') && strcmpi(Options.KL.Method, 'nystrom')
    % In case of Nystrom, the eigenvectors are interpolated to the actual
    % mesh
    RF.CovMesh = current_input.Internal.Mesh ;
    % Save the original Mesh as well
    RF.CovMesh_Original = RF.KL.Coor ;
else
    RF.CovMesh = current_input.Internal.CovMesh ;
end

%% 2. Re-interpolate to the discretization mesh, when needed
switch lower( Options.DiscScheme )

    case 'kl'

        if current_input.Internal.Runtime.isKriging
            RF.Phi = uq_KL_reinterpolate(current_input, Mesh, RF,myKriging);
        else
            % Only reinterpolate if we are using Nystrom
            if strcmpi(Options.KL.Method, 'nystrom')
                RF.Phi = uq_KL_reinterpolate(current_input, Mesh, RF);
            end
        end

    case 'eole'
        if current_input.Internal.Runtime.isKriging
            RF.EOLE.RhoPhi = uq_EOLE_reinterpolate(current_input,Mesh,RF,myKriging);
        else
            RF.EOLE.RhoPhi = uq_EOLE_reinterpolate(current_input,Mesh,RF);
        end

end

%% 3. Calculate the discretization error
% The calculation of the discretization error depends on the discretization
% scheme. The general equation is of the form:
% Var[H(x) - Hhat(x)] = sigma^2(x) - sigmahat^2(x) 
% where sigmahat is computed using the eigenvalues and eigenvectors
% obtained from the discretiazion of the random field covariance matrix. 
% Here we consider the normalized variance, so everything is divided by the
% variance of the process: RF.Std^2

% The computation of the first part sigma^2(x) depends on whether we
% consider unconditional or conditional random fields
if current_input.Internal.Runtime.isKriging

    % sigmaSQ is the posterior covariance - there is no normalization
    K = uq_Kriging_calc_PosteriorCovariance(Mesh,Mesh,myKriging) ;
    % Get the diagonal of the posterior correlation matrix - which is the
    % Kriging variance  
    sigmaSQ = diag(K)' ;

else
    if isempty(Data)
        % Unconditional case
        % Since the correlation matrix is discretized, this part is
        % normalized and equal to 1
        sigmaSQ = ones(1,size(Mesh,1));
    else
        % Calculate the posterior correlation matrix on the mesh
        K = uq_eval_PosteriorCorrelationMatrix(Mesh,Mesh,Data.X,CorrLength,Corr,RF.Rinv);
        % Get the diagonal which is the MSE, i.e. 
        % sigma^2(x) = 1 - r * R^-1 * r' 
        sigmaSQ = diag(K)' ;
    end
end

% Now calculate the variance error
switch lower( Options.DiscScheme )
    case 'kl'

        % Normalized variance error
        RF.VarError = ( sigmaSQ - ...
            sum( RF.Phi.^2 * diag(RF.Eigs) , 2 )' ) ;
    case 'eole'
        % Normalized variance error:
        RF.VarError = sigmaSQ - ...
            sum( repmat(1./RF.Eigs,1,size(Mesh,1)) ...
            .* (RF.EOLE.RhoPhi').^2,1 ) ;
end

% In case of Kriging, normalize the variance by dividing by the Kriging
% variance - only to be consistent with the random field
if current_input.Internal.Runtime.isKriging
RF.VarError = RF.VarError / myKriging.Internal.Kriging.GP.sigmaSQ ;
end

%% 4. Post-processing
% Add the expansion order to the RF field, if it was not given
if ~isempty(ExpOrder)
    RF.ExpOrder = ExpOrder ;
end

% Build the standard Gaussian input object corresponding to the reduced
% space
for ii = 1:RF.ExpOrder
    InputOpts.Marginals(ii).Type = 'Gaussian' ;
    InputOpts.Marginals(ii).Name = sprintf('X%02u',ii);
    InputOpts.Marginals(ii).Parameters = [0,1] ;
end
current_input.Internal.UnderlyingGaussian = uq_createInput(InputOpts,'-private') ;

end