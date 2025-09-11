function RF = uq_KL_Discrete(varargin)
% UQ_KL_DISCRETE: Calculate the eigenvalues and eigenvectors of a given
% covariance matrix or of a correlation matrix that is defined by
% user-defined correlation options (a kernel and its parameters)
%
% INPUT:
%   - Domain: Domain of definition of the random field
%   - Mesh: Discretization mesh where the random field is represented (i.e.
%   when sampling from it)
%   - Corr: Options for the correlation matrix (family, length, etc.)
%   - ExpOrder: expansion order (Keep it empty if it is to be estimated
%   here)
%   - Energyratio: Threshold of the energy ratio to derive the expansion
%   order
%   - options: Quadrature options
%
% OUTPUT:
% Struct RF with the followin fields:
%   - Eigs: Eigenvalues of the correlation matrixc
%   - Phi: Corresponding eigenvectors
%   - ExpOrder: Expansion order (when it is calculated within this
%   function)
%   - TraceCorr: Trace of the correlation matrix - used to compute the sum
%   of eigenvalues.
%

if nargin < 4
    % Covariance matrix is provided
    Cov = varargin{1} ;
    ExpOrder = varargin{2} ;
    EnergyRatio = varargin{3} ;

else
    % Covariance/Correlation matrix needs to be calculated
    Mesh = varargin{1} ;
    Corr = varargin{2} ;
    ExpOrder = varargin{3} ;
    EnergyRatio = varargin{4} ;

    % Compute the correlation matrix on the coordinates of the expansion (Gramm Matrix)
    Cov = uq_eval_Kernel(Mesh, Mesh, Corr.Length, Corr) ;
end

RF.KL.Corr = Cov ;

%% Perform spectral decomposition
% Define a starting point for the definition of the eigenvalues
MaxOrder = size(RF.KL.Corr, 1) ;

if ~isempty(ExpOrder)

    %  The expansion order is already known
    [V,D,eigflag] = eigs(RF.KL.Corr , ExpOrder, 'lm');

    % If eigflag is 0 then the eigendecomposition has converged
    if eigflag ~= 0
        error('Spectral decomposition of the correlation matrix did not converge!');
    end

else

    % The expansion order is not known - Compute it according to the
    % truncation ratio
    [Vfull,Dfull,eigflag] = eigs(RF.KL.Corr , MaxOrder, 'lm');

    % If eigflag is 0 then the eigendecomposition has converged
    if eigflag ~= 0
        error('Spectral decomposition of the correlation matrix did not converge!');
    end

    % Calculate the cumulated energy ratio
    cumulated_eigs = cumsum(abs(diag(Dfull)))/sum(abs(diag(Dfull))) ;

    % Find the order from which the energy ratio is larger than the
    % threshold
    tmp = find(cumulated_eigs >= EnergyRatio) ;
    if isempty(tmp)
        warning('The eigenvalue ratio threshold of %.2f could not be reached with the current covariance mesh!', EnergyRatio);
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

%% Post-processeing : Re-interpolation on the discretization mesh ( See
%% Eq. 18 in [2])

% Get the eigenvalues
eigval = abs(diag(D)) ;

% Get the eigenvector of the original problem ( In [2]: y = W^{-1/2} *
% ystar )
eigvect = V ;


% Collect the results for the output of the function
RF.Eigs = eigval ;
RF.Phi = eigvect ;

% Return the trace of the correlation matrix (will be used to display the
% cumulated eigenvalue ratio) ;
RF.TraceCorr = trace(RF.KL.Corr) ;

end