function results = uq_LRA_OLS(Psi, Y, ~)
% UQ_LRA_OLS_REGRESSION(PSI, Y): calculates the Ordinary Least Squares regression on the
% design matrix Psi for a set of observations Y. 

% Information matrix
PsiTPsi = Psi.'*Psi;

if rcond(PsiTPsi) > 1e-12
    % more accuarte and faster
    results.coefficients = PsiTPsi\(Psi.'*Y);
else
    % less accurate, stabler
    results.coefficients = pinv(PsiTPsi) * transpose(Psi) * Y;
end

