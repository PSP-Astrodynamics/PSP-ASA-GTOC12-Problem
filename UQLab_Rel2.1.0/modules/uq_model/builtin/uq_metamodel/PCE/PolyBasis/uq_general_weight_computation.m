function [Ui, Wi] = uq_general_weight_computation(AB)
% UQ_GENERAL_WEIGHT_COMPUTATION(AB): Compute Gaussian quadrature
%   weigths and nodes using the Golub-Welsch algorithm. The order of the 
%   quadrature is implied by the size of the AB matrix.
%
% Input Parameters:
% 
%   'AB'   A 2x(max_degree) matrix that contains the recurrence terms used 
%          for the computation of polynomials of order 'max_degree'. They
%          are used to define the so-called 'Jacobi Matrix'.
%
% Return Values:
%
%   'Ui'   The quadrature nodes for the requested degree (implied by 'AB')
%
%   'Wi'   The quadrature weights for the requested degree (implied by 'AB')
%
% References:
%
%   Gautschi, W. (2004). Orthogonal polynomials: computation and approximation.
%   
% See also UQ_POLY_REC_COEFFS,UQ_QUADRATURE_NODES_WEIGHTS_GAUSS

jacmatr = diag(AB(1:end,1),0) + diag(AB(2:(end),2),1) + diag(AB(2:(end),2),-1);
[V, U] = eig(jacmatr);

Ui = diag(U)';
Wi = V(1,:)'.^2;
