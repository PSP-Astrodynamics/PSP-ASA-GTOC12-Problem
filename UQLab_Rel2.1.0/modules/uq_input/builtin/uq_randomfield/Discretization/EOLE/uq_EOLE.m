function RF = uq_EOLE(Coor, Mesh, Corr, ExpOrder, EnergyRatio, Data, myKriging)
% UQ_EOLE_METHOD: Carries out spectral decomposition for the EOLE
% (Expansion optimal linear estimation) method.
% INPUT:
%   - Coor: Coordinates/ Points where the correlation matrix is to be
%   computed
%   - Mesh: Discretization mesh where the random field is represented (i.e.
%   when sampling from it)
%   - Corr: Options for the correlation matrix (family, length, etc.)
%   - ExpOrder: expansion order (Keep it empty if it is to be estimated
%   here)
%   - Energyratio: Threshold of the energy ratio to derive the expansion
%   order
%   - Data: Observations (struct: Data.X = locations & Data.Y = Responses)
%   - regression: Regression options (optional)
%
% OUTPUT:
% Struct RF with the followin fields:
%   - Eigs: Eigenvalues of the correlation matrixc
%   - Phi: Corresponding eigenvectors
%   - ExpOrder: Expansion order (when it is calculated within this
%   function)
%   - EOLE: Internal properties of EOLE (Corr_HX: cross-correlation matrix,
%   Corr_XX: Observation correlation matrix, CondWeight: Conditional
%   weight)
%   - TraceCorr: Trace of the correlation matrix - used to compute the sum
%   of eigenvalues.
%

isKriging = true ;
if nargin < 7
    % If called with 7 inputs, then this means that we are resampling from
    % a Kriging model
    isKriging = false ;
    if nargin < 6
        error('uq_EOLE: Insufficient number of inputs!');
    end
end

%% Definition of correlation matrices
% Compute/Get the correlation/covariance matrix on the coordinates of the 
% expansion (Gramm Matrix)

if isKriging

    % Compute the posterior covariance
    [~,~,RF.EOLE.Corr] = uq_evalModel(myKriging, ...
        uq_Kriging_helper_Scaling_UtoX(Coor,myKriging)) ;

else
    if isempty(Data)
        % Compute the correlation matrix on the coordinates of the expansion (Gramm Matrix)
        RF.EOLE.Corr = uq_eval_Kernel(Coor, Coor, Corr.Length, Corr) ;

    else

        % Compute the inverse of the correlation matrix on the observations
        R = uq_eval_Kernel(Data, Data, Corr.Length, Corr) ;
        Rinv = inv(R);
        RF.Rinv = Rinv ; % Save it for further use

        % Compute the posterior correlation matrix
        RF.EOLE.Corr = uq_eval_PosteriorCorrelationMatrix(Coor, Coor, Data, ...
            Corr.Length, Corr, Rinv) ;
    end
end

%% Perform spectral decomposition
% Set the maximum expansion order to the size of the correlation matrix
MaxOrder = size(RF.EOLE.Corr,1) ;

if ~isempty(ExpOrder)

    %  The expansion order is already known, use it
    [V,D,eigflag] = eigs(RF.EOLE.Corr, ExpOrder, 'lm');

    % If eigflag is 0 then the eigendecomposition has converged
    if eigflag ~= 0
        error('Spectral decomposition of the correlation matrix did not converge!');
    end
else

    % The expansion order is not known - Compute it according to the
    % target energy ratio

    % Eigenvalue decomposition with maximum possible order
    [Vfull,Dfull,eigflag] = eigs(RF.EOLE.Corr, MaxOrder, 'lm');

    % If eigflag is 0 then the eigendecomposition has converged
    if eigflag ~= 0
        error('Spectral decomposition of the correlation matrix did not converge!');
    end

    % Calculate the cumulated energy ratio
    cumulated_eigs = cumsum(diag(Dfull))/sum(diag(Dfull)) ;

    % Find the order from which the energy ratio is larger than the
    % threshold
    tmp = find(cumulated_eigs >= EnergyRatio,1) ;
    if isempty(tmp)
        warning('The energy ratio threshold of %.2f could not be reached with the current covariance mesh!', EnergyRatio);
        fprintf('The expansion order is set at %u!\n', MaxOrder);
        ExpOrder = MaxOrder ;
    else
        ExpOrder = tmp(1) ;
    end

    % Get the retained eigenvalues and vectors
    V = Vfull(:,1:ExpOrder) ;
    D = Dfull(1:ExpOrder,1:ExpOrder) ;

    % Return also the expansion order in case it is calculated here
    RF.ExpOrder = ExpOrder ;

    % Return the full set of eigenvalues
    RF.EigsFull = abs(diag(Dfull)) ;
end

% Save the eigenvalues and eigenvectors of the correlation matrix
RF.Phi = V;                % eigenvectors
RF.Eigs = abs(diag(D));    % eigenvalues

% Return the trace of the correlation matrix (will be used to display the
% cumulated energy ratio) ;
RF.TraceCorr = trace(RF.EOLE.Corr) ;
end