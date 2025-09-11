function K = uq_eval_Kernel(X1, X2, theta, options)
% UQ_EVAL_KERNEL computes the kernel matrix given two matrices for a specified kernel function.
%
%   K = UQ_EVAL_KERNEL(X1, X2, THETA, OPTIONS) computes the N1-by-N2 kernel
%   matrix K for two inputs (N1-by-M) X1 and (N2-by-M) X2 given the kernel
%   parameters THETA and additional options specified in the structure
%   OPTIONS:
%       .Family    : The kernel family, classified between stationary and
%                    non-stationary families - String or Function Handle.
%                    Supported strings are:
%                      'Linear'      : Linear kernel (stationary).
%                      'Exponential' : Exponential kernel (stationary).
%                      'Gaussian'    : Gaussian (stationary).
%                      'Matern-3_2'  : Matern 3/2 (stationary).
%                      'Matern-5_2'  : Matern 5/2 (stationary).
%                      'Linear-NS'   : Linear (non-stationary).
%                      'Polynomial'  : Polynomial (non-stationary).
%                      'Sigmoid'     : Sigmoid (non-stationary).
%                    Custom user-defined kernel family can be defined for
%                    stationary kernel via a Function Handle.
%       .Type      : Kernel function type, only to the stationary kernel
%                    families - String:
%                      'Ellipsoidal' : Ellipsoidal kernel.
%                      'Separable'   : Separable kernel.
%       .Isotropic : Flag to determine whether the kernel function is
%                    isotropic or anisotropic, only applies to the
%                    stationary kernels - Logical.
%       .Nugget    : Nugget value, only applies when X1 = X2 - Scalar or
%                    1-by-M Double.
%
%   Additional notes:
%
%   - UQ_EVAL_KERNEL is used to evaluate the correlation matrix and vector
%     for Kriging and random field generation, as well as the kernel matrix
%     for support vector machines for regression and classification
%   - If X1 = X2, the kernel matrix is a Gram matrix.

%% Retrieve the correlation/kernel function options
K_type = options.Type;
K_family = options.Family;
K_isIsotropic = options.Isotropic;
nugget = options.Nugget;

%% Check consistency

% Number of points
N1 = size(X1,1);
N2 = size(X2,1);

% Kernel parameters
if K_isIsotropic && length(theta) > 1 ...
        && ~strcmpi(K_family,'polynomial') && ~strcmpi(K_family,'sigmoid')
    error(['Error: For isotropic kernel/correlation function,'...
        'the length scale parameter (theta) is expected to be scalar!'])
elseif strcmpi(K_family,'polynomial') && length(theta) ~=2
    error('Error: The polynomial kernel must have two parameters')
elseif strcmpi(K_family,'sigmoid') && length(theta) ~=2
    error('Error: The sigmoid kernel must have two parameters')
end

% Check input dimension
if size(X1,2) ~= size(X2,2)
    error('Error: Xi s in K(X1,X2) must have the same number of dimensions!')
end
% Size of (non-constant) Marginals:
M = size(X1,2);

if ~K_isIsotropic && (M ~= length(theta))
    error('Error: For anisotropic kernel/correlation function theta vector must have length equal to the number of marginals!')
end
if size(theta,1) == 1 && ~isscalar(theta)
    theta = transpose(theta);
end

%% Calculate K

% Determine if this is a Gram matrix calculation (X1 == X2)
isGram = (N1 == N2) && isequal(X1,X2);

% Check if the kernel is stationary or a handle
% (similar handling in both cases)
isstationary = any(strcmpi(K_family, {'nugget', 'linear','exponential', ...
    'gaussian', 'matern-5_2', 'matern-3_2'})) ...
    || strcmpi(class(K_family),'function_handle');

% The algorithm works as follows: at first two indices are created
% that contain all the possible permutations of indices
% (that reference all of the elements of K)
[idx2,idx1] = meshgrid(uint32(1:N2),uint32(1:N1));

if isstationary
    if isGram
        % if K is a Gram matrix,
        % no need to calculate anything from the diagonal up
        zidx = idx1 > idx2;
        idx1 = idx1(zidx);
        idx2 = idx2(zidx);
    else
        zidx = idx1 > 0;
    end
    switch lower(K_type)
        case 'separable'
            if isa(K_family,'function_handle')
                % Keep in mind to give the correct shape to K,
                % otherwise we are in trouble (sic)
                K = zeros(N1*N2,1);
                K(zidx(:)) = 1;
                if K_isIsotropic
                    for jj = 1:M
                        K(zidx(:),1) = K(zidx(:),1) .* K_family(X1(idx1(:),jj), X2(idx2(:),jj), theta);
                    end
                else
                    for jj = 1:M
                        K(zidx(:),1) = K(zidx(:),1) .* K_family(X1(idx1(:),jj), X2(idx2(:),jj), theta(jj));
                    end
                end
            else
                switch lower(K_family)
                    case 'nugget'
                        h = double(X1(idx1(:),:) == X2(idx2(:),:));
                    case {'linear','exponential','gaussian','matern-5_2','matern-3_2'}
                        h = abs(bsxfun(@rdivide,X1(idx1(:),:) - X2(idx2(:),:), theta'));
                    otherwise
                        error('Error: Unknown kernel/correlation function family!')
                end
            end
            
            if ~isa(K_family,'function_handle')
                if isGram
                    K = zeros(N1*N2,1);
                    K(zidx(:)) = uq_assemble_Kernel(h,K_family,K_type);
                    %clear h;
                else
                    K = uq_assemble_Kernel(h,K_family,K_type);
                    %clear h;
                end
            end

        case 'ellipsoidal'
            % This is just one case of ellipsoidal kernel function
            % where the distance is calculated as:
            % h = sqrt((x1-x2)'*K*(x1-x2)) with K = diag(M)*theta
            % in the general case K can be any PSD matrix
            % (to become available in later version)

            % When Isotropic correlation function is used,
            % theta needs to be replicated to match the dimension M
            % in order to use the efficient way of calculating
            % the standardized euclidean distance (h)
            if isscalar(theta) && K_isIsotropic
                theta = repmat(theta,M,1);
            end
            h = pdist2(X1, X2, 'seuclidean', theta');
            
            % handle custom kernel
            if isa(K_family,'function_handle')
                K = zeros(N1*N2,1);
                K(zidx(:),1) = K_family(h(zidx(:)));
            else
                if isGram
                    K = zeros(N1*N2,1);
                    K(zidx(:)) = uq_assemble_Kernel(h(zidx(:)),K_family,K_type);
                    %clear h;
                else
                    K = uq_assemble_Kernel(h,K_family,K_type);
                    %clear h;
                end
            end

        otherwise
            error('Unknown type of correlation function:"%s"',K_type)
    end


else
    % Non-stationary kernel
    if isGram
        % if K is a Gram matrix,
        % no need to calculate anything from the diagonal up, but here
        % compute
        zidx = idx1 >= idx2;
        idx1 = idx1(zidx);
        idx2 = idx2(zidx);
    else
        zidx = idx1 > 0;
    end
    K = zeros(N1*N2,1);
    switch lower(K_family)
        case 'linear_ns'
            K(zidx(:),1) = sum(X1(idx1(:),:) .* X2(idx2(:),:), 2) ;
        case 'polynomial'
            K(zidx(:),1) = (sum(X1(idx1(:),:) .* X2(idx2(:),:), 2) ...
                + theta(1)).^theta(2);
        case 'sigmoid'
            K(zidx(:),1) = tanh(sum(X1(idx1(:),:) .* X2(idx2(:),:), 2)./theta(1) ...
                + theta(2));
        otherwise
            error('Error: Unknown correlation function family!')
    end
end

%% Reshape K to the original size

K = reshape(K, N1, N2);

% if it is a Gram matrix, check if we need to add the nugget,
% as well as add back the upper triangular elements,
% as well as the main diagonal
if isGram
    if isstationary
        K = K + transpose(K) + eye(size(K));
    else
        % Since the diagonal elements were already calculated,
        % remove the extra diag term due to K + transpose(K)
        K = K + transpose(K) - diag(diag(K));
    end
    if exist('nugget','var')
        if isscalar(nugget) && nugget
            K = K  + eye(N1)*nugget;
        elseif ~isscalar(nugget)
            K = K  + diag(nugget) ;
        end
    end
end
