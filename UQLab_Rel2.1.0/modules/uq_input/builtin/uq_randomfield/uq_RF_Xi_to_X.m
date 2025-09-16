function X = uq_RF_Xi_to_X(current_input,xi,varargin)
% UQ_RF_XI_TO_X: transforms the random variables xi into random field
% trajectories
%
% INPUT:
%   - current_input: Random field current_input object
%   - xi: random variables of size N x M, where N is the number of
%   realizations and M is the expansion order of the random field defined
%   in current_input
%   - varargin{1}: (dynamic mesh) Optional input of size 1xm that contains
%   the mesh over which the trajectories are to be sampled on.
% OUTPUT:
%   - X: Random field trajectories of size N x m, where m is the size of
%   the discretization size of the mesh defined in the random field current_input

% Gather the options of the random field
Options = current_input.Internal ;

% Number of samples
N = size(xi,1) ;

%% Eigenvectors reinterpolation
if nargin>2 % Dynamic mesh, i.e., the user is resampling on a mesh submitted at calling time

    X0 = varargin{1} ;

    % Get the Kriging model
    if Options.Runtime.isKriging
        myKriging = Options.RFModel ;
    end

    switch lower( Options.DiscScheme )

        case 'kl'

            if Options.Runtime.isKriging
                Phi = uq_KL_reinterpolate(current_input, X0, current_input.RF, myKriging);
            else
                % Reinterpolate if we are using Nystrom - dynamic mesh is
                % possible only when using Nystrom
                if strcmpi(Options.KL.Method, 'nystrom')
                    Phi = uq_KL_reinterpolate(current_input, X0, current_input.RF);
                end
            end

        case 'eole'
            if current_input.Internal.Runtime.isKriging
                RhoPhi = uq_EOLE_reinterpolate(current_input, X0, current_input.RF,myKriging);
            else
                RhoPhi = uq_EOLE_reinterpolate(current_input, X0, current_input.RF);
            end

    end


else
    % The mesh is already provided by the user when building the random field
    % then all we have to do is to get the RhoPhi and Phi that are needed to
    % generate sample paths

    % X0 is the mesh provided by the user while building the random field
    X0 = current_input.Internal.Mesh ;

    switch lower(Options.DiscScheme)
        case 'eole'
            RhoPhi = Options.RF.EOLE.RhoPhi ;

        case 'kl'
            Phi = Options.RF.Phi ;

    end


end

%% Mean and standard deviation updates
if Options.Runtime.isKriging
    % Update the mean and standard deviation in case Kriging is used
    UpdateMean = uq_evalModel(myKriging, ...
        uq_Kriging_helper_Scaling_UtoX(X0,Options.RFModel))' ;

    % Get the standard deviation, which should be equal to 1 as we have
    % discretized the covariance matrix
    UpdateStd = Options.Std ;
else

    % Update the size of the mean and standard deviation vectors
    if isempty(Options.RFData)
        % Non-Conditional data
        UpdateMean = repmat(Options.Mean, 1, size(X0,1)) ;
        UpdateStd = repmat(Options.Std, 1, size(X0,1)) ;

    else
        Rinv = current_input.RF.Rinv ;
        % Calculate the posterior mean
        r0 =  uq_eval_Kernel(X0, Options.RFData.X, Options.Corr.Length, Options.Corr) ;
        UpdateMean =transpose( Options.Mean + r0 * Rinv * (Options.RFData.Y- Options.Mean)) ;
        % UpdateMean=repmat(Options.Mean, 1, size([X0; Options.RFData.X],1));
        UpdateStd=repmat(Options.Std, 1, size(X0,1));

    end
end


%% Resampling
switch lower(Options.DiscScheme)
    case 'kl'

        X =   repmat(UpdateMean, N, 1) + repmat(UpdateStd, N, 1).* ...
            ( ( Phi * diag( sqrt(Options.RF.Eigs) ) ) * xi' )' ;

    case 'eole'

        Sample = (RhoPhi) ./ repmat(sqrt(Options.RF.Eigs)',size(X0,1),1) ;

        X =  xi * Sample' .* repmat(UpdateStd, N, 1) + repmat(UpdateMean, N, 1) ;


    otherwise

        error('Undefined discretization scheme!');

end
end