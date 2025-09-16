function K = uq_MixedSVRKernel(X1,X2,theta,Options)

N1 = size(X1,1) ;
N2 = size(X2,1) ;

if size(X1,2) ~= size(X2,2)
    error('Error: Xi s  in K(X1,X2) must have the same number of marginals!')
end
M = size(X1,2);
if size(theta,1) == 1 && ~isscalar(theta)
    theta = transpose(theta) ;
end

isGramm = (N1 == N2) && isequal(X1,X2);   % Similar to Kriging consider whther K is the Gramm matrix

K1 = ones(N1*N2,1);

[idx2, idx1] = meshgrid(1:N2,1:N1);
if isGramm % if it is a Gramm matrix, we don't need to calculate anything from the diagonal up
    zidx = idx1 > idx2 ;
    idx1 = idx1(zidx) ;
    idx2 = idx2(zidx) ;
else
    zidx = idx1 > 0 ;
end

K1(zidx(:)) = prod(exp(-0.5* (bsxfun(@rdivide,X1(idx1(:),:) - X2(idx2(:),:), theta(1))).^2 ), 2) ;
    %% Reshape K to the original size
    K1 = reshape(K1, N1, N2);
    K1(~zidx) = 0;
    % if it is a covariance, check if we need to add the nugget, as well as add
    % back the upper triangular elements, as well as the main diagonal
    if isGramm
        
        K1 = K1 + transpose(K1) + eye(size(K1));
        
    end
K2 = (X1*X2' + theta(2)).^5 ;
K = theta(3)* K1 + (1-theta(3)) * K2 ;

end

