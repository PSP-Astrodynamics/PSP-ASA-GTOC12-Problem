function varargout = uq_PCE_eval(current_model,X)
% Y = UQ_PCE_EVAL(CURRENT_MODEL,X): evaluates the response of the PCE
%     metamodel CURRENT_MODEL onto the vector of inputs X
%
% See also: UQ_EVAL_UQ_METAMODEL,UQ_KRIGING_EVAL,UQ_PCE_EVAL_UNIPOLY,UQ_PCE_CREATE_PSI

%% Command line check
% do nothing if X is empty and correspondingly return all empty values.
if isempty(X)
    for ii = 1:nargout
        varargout{ii} = [];
    end
    return;
end

% Get the number of requested model evaluations
N = size(X, 1);

% make sure that we only use the non-constant variables in the evaluation
nonConstIdx = current_model.Internal.Runtime.nonConstIdx;

%% Polynomial evaluation
% Multivariate orthonormal polynomials are assembled from the values of the
% univariate ones. They need to be evaluated in a suitable reduced space.

% Retrieve the probabilistic input model
Input = current_model.Internal.Input;

% Number of output components to be evaluated
Nout = current_model.Internal.Runtime.Nout;
% Preallocate the outputs
Y = zeros(N, Nout);

% Initialize any residual structure that may be needed
% Bootstrap is to be evaluated if more than one output is requested
if nargout > 1
    if ~isfield(current_model.Internal.PCE, 'Bootstrap')
        warning('Bootstrap requested for non-bootstrap-enabled model!');
    end
    stdY = zeros(N,Nout);
end

if nargout > 2
    YB = zeros(N,current_model.Internal.Bootstrap(1).Replications, Nout);
end


% preinitialize the Psi matrix (faster to copy again rather than
% re-instance every time)
Psi0 = ones(N, 1);

% Retrieval of the reduced space input and use the necessary
% isoprobabilistic transforms of X to U
ED_Input = current_model.Internal.ED_Input;
U = uq_GeneralIsopTransform(X, Input.Marginals, Input.Copula, ED_Input.Marginals, ED_Input.Copula);

% get the PCE info once
PCE = current_model.PCE;


% Initialize the PCE basis. The univariate polynomials are evaluated only
% once up to the maximum degree

if strcmpi(current_model.Options.MetaType,'PCE') && isfield(current_model.Options,'Method') && ...
        strcmpi(current_model.Options.Method,'quadrature') && length(PCE)>1
    % in order to ignore fields of the first struct that do not appear in the others
    for fn = fieldnames(PCE(2).Basis)'
        bb_tmp.(fn{1}) = PCE(1).Basis.(fn{1});
    end
    BB = [bb_tmp PCE(2:end).Basis];
    
else
    BB = [PCE.Basis];
end
% Get the maxima of the basis elements componentwise
maxDegrees = max(vertcat(BB.MaxCompDeg),[],2);
[~, mDegComp] = max(maxDegrees);

% To get the univariate polynomials, set temporarily the current output to
% the component with highest degree
current_model.Internal.Runtime.current_output = mDegComp;

% Calculate and store the univariate polynomial evaluations
univ_p_val = uq_PCE_eval_unipoly(current_model, U(:,nonConstIdx));


%% Assembly of the Psi matrix.

% Loop over the output components (the evaluation is done independently for
% each
for oo = 1:Nout
    % Retrieve the PCE coefficients for the current output
    y_a = PCE(oo).Coefficients;
    
    % get the index of non zero coefficients only
    nnz_idx = (y_a ~= 0);
    % reduce the coefficients array to the useful ones
    y_a = y_a(nnz_idx);
    
    % Also use only the indices of the non-zero coefficients
    FullIndices = PCE(oo).Basis.Indices(nnz_idx,:);
    
    % Loop over the coefficients to calculate the sum of basis elements
    for aa = 1:length(y_a)
        % Full-componentwise matrix evaluation is faster than using the
        % original sparse format
        Indices = full(FullIndices(aa,:));
        % reinitialize the Psi submatrix for each coefficient
                Psi = Psi0;
                % only loop over the non-trivial components when building the
                % tensor product of univariate polynomials
                for mm = find(Indices)
                    Psi = Psi .* univ_p_val(:,mm, Indices(mm)+1);
                end
        
       % Sum up to the output for the current coordinate
        Y(:,oo) = Y(:,oo) + Psi*y_a(aa);
    end
    
    % now also evaluate the Bootstrap model, if any (recursive call)
    if nargout > 1
        YB(:,:,oo) = uq_evalModel(current_model.Internal.Bootstrap(oo).BPCE,X);
        stdY(:,oo) = std(squeeze(YB(:,:,oo)),[],2);
    end
end

%% Assign the outputs
% Main predictor
varargout{1} = Y;

% If requested, return the standard deviation of the Bootstrap sample as
% the second argument
if nargout > 1
    varargout{2} = stdY.^2;
end

% If requested, also return the full 3D matrix of bootstrap model
% evaluations
if nargout > 2
    varargout{3} = YB;
end