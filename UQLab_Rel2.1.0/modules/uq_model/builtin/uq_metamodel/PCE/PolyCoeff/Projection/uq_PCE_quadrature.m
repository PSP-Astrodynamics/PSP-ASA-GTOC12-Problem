function [Coefficients, Error] = uq_PCE_quadrature(Psi, Y, W)
% [COEFFICIENTS, ERROREST] = UQ_PCE_QUADRATURE(PSI,Y,W): calculate the
%     quadrature-based estimation of the polynomial coefficients given the
%     polynomial basis Psi, the experimental design evaluation Y and the
%     set of quadrature weights W.
%
% See also: uq_quadrature_nodes_weights_gauss, uq_quadrature_nodes_weights_smolyak

Coefficients = full(transpose(Psi)*spdiags(W,0,length(W), length(W))*Y);

% now calculate the error, it id done the exact same way, but using the
% expectation value of Y-coefficients*Psi instead (just an expectation value)
Error = abs(sum((Y - Psi*Coefficients).^2.*W)/var(Y));
