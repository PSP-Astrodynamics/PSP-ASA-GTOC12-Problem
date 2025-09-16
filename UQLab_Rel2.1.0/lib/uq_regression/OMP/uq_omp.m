function results = uq_omp(Psi,Y,options)

% RESULTS = UQ_OMP(PSI, Y, OPTIONS). ORTHOGONAL MATCHING PURSUIT. 

% This code is an implementation of the algorithm proposed in the paper:
% Pati, Y., Rezaiifar, R., Krishnaprasad, P. (1993). Orthogonal matching 
% pursuit: recursive function approximation with application to wavelet 
% decomposition. Proceedings of 27th Asilomar Conference on Signals,
% Systems and Computers, 40-44.
% 
% Function only needs the matrix Psi and the model response Y to perform the
% regression. 
% P:            Cardinality of the basis (number of functions present in
%               the dictionary)
% n:            Amount of samples
% Matrix Psi:   nxP is a matrix containing the evaluation of the basis
%               function evaluated at the input variables X. 
%               Psi is the regressors matrix. 
% Vector Y:     nx1 is a vector containing the model responses to the input
%               variables X.
%
% The OPTIONS structure is optimal and can contain any of the following
% fields: 
%  'precision':    precision defines the value under which the norm of the 
%                  residual is considered acceptable and the iterations are
%                  terminated (default value 0)
%  'early_stop':   0 or 1 (default 1), stop the OMP iterations if the
%                  accuracy starts decreasing
%  'modified_loo': 0 or 1 (default 0), if set to 0 calculates the
%                  un-modified LOO-Error, if set to 1 calculates the modified 
%                  LOO-Error (based on Blatman, 2009 (PhD Thesis), pg. 115-116)
%  'display':      0 or 1 (default 0), controls the verbosity level of the 
%                  output, set to 1 for debugging porpuses
%
% The RESULTS structure contains the results as a structure with the
% following fields: 
%  'coefficients':     the array of coefficients
%  'best_basis_index': the index of the iteration OMP has converged to
%  'max_score':        the maximum score of the best iteration (1-LOO_k)
%  'LOO':              the Leave-One-Out error estimate for the best iteration
%  'normEmpErr':       the estimated normalizedEmpiricalError
%  'nz_idx':           the index of non-zero regressors (w.r.t. the
%                      original PSI matrix)
%  'a_scores':         the vector of scores for each iteration of OMP
%  'coeff_array':      the matrix of the coefficients for each iteration of OMP

%% RETRIEVING INFORMATION ON PROGRAM OPTIONS
% Ininitialization of default options
precision = 0;        % Set precision criterion to precision of program
early_stop = 1;       % Set early_stop option to 1
modified_loo = 1;     % Set modified_loo option to 1
display_level = 0;    % Set display option to 0
keepiterations = 0;   % Set keepiterations option to 0

% Checking for input options 
if exist('options','var')
    % Check for precision option 
    if isfield(options,'precision')
        precision = options.precision; 
    end
    
    % Check for early stop option
    if isfield(options,'early_stop')
        early_stop = options.early_stop;
    end
    
    % Check for modified LOO error option
    if isfield(options,'modified_loo')
        modified_loo = options.modified_loo;
    end
    
    % Check for display option
    if isfield(options,'display')
        display_level = options.display;
    end
    
    % Check for keepiterations options
    if isfield(options,'keepiterations')
        keepiterations = options.keepiterations;
    end
end
%%
if isfield(options,'CY')
    CY = options.CY;
    if size(CY,2)>1
        % For general correlation structures
        CYinv = CY \ eye(size(CY));
        L = chol(CYinv);
        Psi = L*Psi;
        Y = L*Y;
    else
        % For heteroskedasticity
        L = 1./sqrt(CY);
        Psi = bsxfun(@times,L,Psi);
        Y = L.*Y;
    end
end
%% OBTAIN INFORMATION ABOUT MATRIX DIMENSIONS AND CHECK FOR DIMENSIONALITY
% Retrieve dimension of regressors matrix PSI
[n,P] = size(Psi);

% Check that Y is inputted as a vector
if size(Y,1)~=numel(Y)
    Y = Y';         % Transpose Y if inputted as a row vector
end

% Check that Y vector and Psi matrix have the same dimensionality
if n~=numel(Y)
    % Transpose matrix Psi to have samples as rows
    Psi = Psi'; 
    [n,P] = size(Psi);
end

%% INITIALIZATION OF THE ALGORITHM (Normalization and prepping)
% Normalize columns of Psi, so that each column has norm = 1
normPsi = sqrt(sum(Psi.*Psi,1));       % Same as: sqrt(diag(Psi'*Psi));
PsiNorm = Psi./repmat(normPsi,n,1);    % Same as: Psi./(ones(n,1)*normPsi);

% Initialize residue vector to full model response and normalize
R = Y;
normY = sqrt(Y'*Y);
r = Y/normY;

%% Check for constant regressors
constindices = find( ~any(diff(Psi, 1)) ); % indices of constant regressors
bool_const = ~isempty(constindices); % true iff constant regressor exists

%% PERFORM REGRESSION USING THE OMP-ALGORITHM
ind = [];                   % index of selected columns
indtot = 1:1:P;             % Full index set for remaining columns
M = [];                     % Initial information matrix
kmax = min(n,P);            % Maximum number of iterations
LOO = Inf(kmax,1);          % Store LOO error at each iteration
normEmpErr = Inf(kmax,1);   % Store normEmpErr at each iteration
LOOmin = Inf;               % Initialize minimum value of LOO
coeff = zeros(P,kmax);      % Store coefficients at each iteration
indit = zeros(kmax,kmax);   % Store selected indexes at each iteration
count = 1;                  % Initialize counter
k = 0.1;                    % Percentage of iteration history for early stop
cond_early = 1;             % Initialize condition for early stop
refscore = inf;

% Begin iteration over regressors set (Matrix PSI)
while (norm(R)>precision) && (count<=kmax) ...
      && xor((cond_early | early_stop),~cond_early)
    
    % Update index set of columns yet to select (Computationally faster)
    if count~=1
       indtot(iindx) = [];       % Same as: setdiff(indtot,indx);
    end
    
    % Find column of Psi matrix that is most correlated with residual
    h = abs(r'*PsiNorm);
    [~,iindx]=max(h(indtot));           % Same as: max(abs(PsiNorm(:,indtot)'*r)) 
    indx = indtot(iindx);
    
    % initialize with the constant regressor, if it exists in the basis
    if (count == 1) && bool_const
        % overwrite values for iindx and indx
        iindx = constindices(1);
        indx = indtot(iindx);
    end
    
    % Invert the information matrix at the first iteration, later only
    % update its value on the basis of the previously inverted one
    if count==1
        M = 1/(Psi(:,indx)'*Psi(:,indx));
    else
        x = Psi(:,ind)'*Psi(:,indx);
        r = Psi(:,indx)'*Psi(:,indx);
        M = uq_blockwise_inverse(M,x,x',r); % Update information matrix
    end
    
    % Add newly found index to the selected indexes set
    ind = [ind;indx];
    indit(1:count,count) = ind;     % Store selected indexes at each iteration
    
    % Select regressors subset (Projection subspace)
    Xpro = Psi(:,ind);
    
    % Obtain coefficient by performing OLS
    TT = Xpro'*Y;
    beta = M*TT;
    coeff(ind,count) = beta;    % Store coefficients for later
    
    % Compute LOO error
    [Loo_out, normEmpErr_out, temp] = uq_PCE_loo_error(Xpro, M, Y, beta, modified_loo);
    LOO(count) = Loo_out;
    normEmpErr(count) = normEmpErr_out;
    if Loo_out<refscore
        refscore = Loo_out;
        optErrorParams = temp;
    end
    
    % Compute new residual due to new projection
    R = Y - Xpro*beta;          % Same as:  Y - Xpro*M*Xpro'*Y;
    
    % Normalize residual
    normR = sqrt(R'*R);
    r = R/normR;
    
    % Update counters and early-stop criterions
    countinf = max(1,floor(count-k*kmax));          
    LOOmin = min(LOOmin,LOO(count));
    cond_early = (min(LOO(countinf:count))<=LOOmin);
    
    % Update counter
    count = count + 1;
    
    % Displays variables for debugging purposes
    if display_level > 3
        % Show iteration count on console
        fprintf('OMP Iteration Nr. %.0f \n',count-1);
        
        % Check for doubly selected columns
        doubles = (size(unique(ind),1)==size(ind));
        if ~doubles
            disp('There are double selected columns in the regressors');
        end
    end
    
end

%% POST-PROCESSING OF THE OBTAINED RESULTS
% Cut LOO vector, to avoid counts that have not been reached
LOO = LOO(1:count-1);   % Explore only LOO of counts that have been reached

% Select projection with smallest cross-validation error
countmin = find(LOO==min(LOO),1);    % When multiple minima, choose sparsest

% Retrieve indexes and coefficients from the projection with smallest CV error
coefficients = coeff(:,countmin);
LOOmin = LOO(countmin);
normEmpErrmin = normEmpErr(countmin);

%% STORE RESULTS FOR OUTPUT
results.coefficients = coefficients;
results.best_basis_index = countmin;
results.max_score = (1-LOOmin);
results.LOO = LOOmin;
results.normEmpErr = normEmpErrmin;
results.nz_idx = indit(1:countmin,countmin)';
if ~keepiterations
    results.a_scores = 1-LOO(1:countmin)';
    results.coeff_array = coeff(:,1:countmin);
else
    results.a_scores = 1 - LOO';
    results.coeff_array = coeff;
end
results.optErrorParams = optErrorParams;
end