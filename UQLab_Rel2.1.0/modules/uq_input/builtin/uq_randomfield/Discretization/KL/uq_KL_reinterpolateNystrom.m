function [eigvect] = uq_KL_reinterpolateNystrom(weights,eigval,eigvect_noninterp,Rho_vV,ExpOrder)
% UQ_KL_REINTERPOLATENYSTROM reinterpolates the eigenvectors over a new
% mesh using the approach described in [2]
% [1] Press, W. H., S. A. Teukolsky, W. T. Vetterling, and
% B. P. Flannery (2007). Numerical recipes: The art of scientific
% computing. Cambridge university press.
% [2] Betz, W., I. Papaioannou, and D. Straub (2014). Numerical methods
% for the discretization of random fields by means of Karhunen-loeve
% expansion. Comput. Methos Appl. Mech. Engrg. 271, 109–129.

% Compute matrix A = W^(1/2) (See [1,2] in uq_KL_Nystrom)
n = size(weights,1) ;
A = spdiags(sqrt(weights),0,n,n) ;

% Get the eigenvector of the original problem ( In [2]: y = W^{-1/2} * ystar )
eigvect_original = A\eigvect_noninterp ;

% Apply Nystrom interpolation
eigvect = (Rho_vV * (repmat(sqrt(weights),1,ExpOrder).*eigvect_noninterp))./repmat(eigval',size(Rho_vV,1),1) ;

% Make sure the eigenvectors are normalized (Not necessary but may help
% avoid some numerical issues) - In [2] this is the normalization with the
% integral computed using the data from the previous Gauss quadrature
normalizing_const = sqrt(sum(repmat(weights,1,ExpOrder).*eigvect_original.*eigvect_original,1)) ;
eigvect = eigvect ./ repmat(normalizing_const,size(eigvect,1),1) ;

end