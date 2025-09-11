function DiagC = uq_Kriging_calc_DiagOfCongruent(A,B)
%UQ_KRIGING_CALC_DIAGOFCONGRUENT computes the diagonal of a congruent matrix.
%
%   DIAGC = UQ_KRIGING_CALC_DIAGOFCONGRUENT(A,B) computes the diagonal
%   elements of a special form congruent matrix, DIAGC = diag(C), where
%   C = A * B^(-1) * transpose(A) and returns it as a row vector. A is
%   assumed to be of size N2-by-N1 and B of N1-by-N1. The computation
%   is from right, so the transpose is always performed.

AT = transpose(A);

% If B is well conditioned, use the backslash operator,
% otherwise use pseudo-inverse
if rcond(B) > eps
    C = B \ AT;  
else
    C = pinv(B) * AT;
end

DiagC = sum(AT.*C,1);

end
