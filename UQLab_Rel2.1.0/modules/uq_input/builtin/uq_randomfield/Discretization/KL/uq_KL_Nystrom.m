function RF = uq_KL_Nystrom(Domain, Mesh, Corr, ExpOrder, EnergyRatio, Options, Data, myKriging)
% UQ_KL_NYSTROM: Solves the Fredholm integral equation for Karhunen-Loève
% using the Nyström method, as described in:
% [1] Press, W. H., S. A. Teukolsky, W. T. Vetterling, and
% B. P. Flannery (2007). Numerical recipes: The art of scientific
% computing. Cambridge university press.
% [2] Betz, W., I. Papaioannou, and D. Straub (2014). Numerical methods
% for the discretization of random fields by means of Karhunen-loeve
% expansion. Comput. Methos Appl. Mech. Engrg. 271, 109–129.
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
%   - regression: Regression options (optional)
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

%% 1. Random field discretization

isKriging = true ;
if nargin < 8
    % If called with 7 inputs, then this means that we are in GP regression
    isKriging = false ;
    if nargin < 7
        error('uq_KL_Nystrom: Insufficient number of inputs!');
    end
end

% Topological space dimension
M = size(Domain,2) ;
% Number of nodes in the quadrature
N = Options.SPD ;
% Polynomials used for quadrature repeated for as many times as there are
% dimensions
QuadPoly = repmat({'Legendre'},M,1) ;

% Get the nodes and weights of the Gauss quadrature rule in [-1,1]
switch lower(Options.Quadrature)
    case 'full'
        [u,w] = uq_quadrature_nodes_weights_gauss(N-1,QuadPoly) ;
    case 'smolyak'
        [u,w] = uq_quadrature_nodes_weights_smolyak(N,QuadPoly) ;
        if any(w<0)
            error('Smolyak returned negative weights, please use a different method!');
        end

end

% Multiple the weights by 2 to get the actual weights: UQLab assumes the
% interval is [0,1] while here it is [-1,1], hence the 2x
w = w*2 ;

% Transform into physical space
Coor = (u+1)/2 .* (Domain(2,:) - Domain(1,:))  + Domain(1,:) ;

% Appropriately scale the weights
w = w .* prod((Domain(2,:) - Domain(1,:))./2 ) ;

% Compute/Get correlation/covariance matrices
if isKriging

    % Now compute the posterior covariance
    [~,~,RF.KL.Corr] = uq_evalModel(myKriging, ...
        uq_Kriging_helper_Scaling_UtoX(Coor,myKriging)) ;

else
    if isempty(Data)
        % Compute the correlation matrix on the coordinates of the expansion (Gramm Matrix)
        RF.KL.Corr = uq_eval_Kernel(Coor, Coor, Corr.Length, Corr) ;

    else
        % Compute the inverse of the correlation matrix on the observations
        R = uq_eval_Kernel(Data, Data, Corr.Length, Corr) ;
        Rinv = inv(R);
        % Save the matrix
        RF.Rinv = Rinv ;
        % Compute the posterior correlation matrix
        RF.KL.Corr = uq_eval_PosteriorCorrelationMatrix(Coor, Coor, Data, ...
            Corr.Length, Corr, Rinv) ;

    end
end

% Compute matrix A = W^(1/2) (See [1,2])
n = size(w,1) ;
A = spdiags(sqrt(w),0,n,n) ;
% Compute the matrix to be eigen-decomposed: B = A * Cov * A ;
B = A * RF.KL.Corr * A ;
B = (B+B')/2 ; % Make B perfectly symmetric

%%
% Perform spectral decomposition
% Define a starting point for the definition of the eigenvalues
MaxOrder = size(B,1) ;

if ~isempty(ExpOrder)

    %  The expansion order is already known
    [V,D,eigflag] = eigs(B, ExpOrder, 'lm');

    % If eigflag is 0 then the eigendecomposition has converged
    if eigflag ~= 0
        error('Spectral decomposition of the correlation matrix did not converge!');
    end
else

    % The expansion order is not known - Compute it according to the
    % truncation ratio
    [Vfull,Dfull,eigflag] = eigs(B, MaxOrder, 'lm');

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

    % Return the full set of eigenvalues
    RF.EigsFull = abs(diag(Dfull)) ;
end

%% Sabe results
%
% Collect the results for the output of the function
RF.Eigs = abs(diag(D)) ;
% Save the eigenvector computed on the discretization mesh
RF.KL.Phi_Original = V ;
% Weights used in Nystrom integral
RF.KL.weights = w ;
% Discretization mesh
RF.KL.Coor = Coor ;
% Return the trace of the correlation matrix (will be used to display the
% cumulated eigenvalue ratio) ;
RF.TraceCorr = trace(B) ;
% Save the expansion order in the calculated RF
RF.ExpOrder = ExpOrder ;
end
