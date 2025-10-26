function Copula = uq_GaussianCopula(C, corrType)
% Copula = UQ_GAUSSIANCOPULA(C, corrType)
%     Creates a structure that describes a Gaussian copula with matrix C of
%     correlation coefficients. The parameters can be specified as 
%     linear (= Pearson; default), Spearman's rho, or Kendall's tau  
%     correlation coefficients.
%
% INPUT:
% C : M-by-M array
%     matrix of correlation coefficients of the M-variate Gaussian copula. 
% paramType : char, optional 
%     type of correlation parameters specified. Either 'Linear' 
%     (equivalently 'Pearson'), 'Spearman', or 'Kendall'.
%     Default: 'Linear'
%
% OUTPUT:
% Copula : struct
%     Structure describing a Gaussian copula
%
% SEE ALSO: uq_PairCopula, uq_VineCopula, uq_IndepCopula

if nargin == 1, corrType = 'Linear'; end

% Standard checks for matrix theta (valid when theta is a matrix of 
% Pearson's, Spearman's Rho, or Kendall's tau correlation coefficients)
uq_check_correlation_matrix(C);

[d1, d2] = size(C);
Copula = uq_copula_skeleton(); 
Copula.Type = 'Gaussian'; 
% Copula.Dimension = d1;

if any(strcmpi(corrType, {'Pearson', 'Linear'}))
    Copula.Parameters = C;
elseif strcmpi(corrType, 'Spearman')
    Copula.RankCorr = C;
elseif strcmpi(corrType, 'Kendall')
    Copula.TauK = C;
end

% Check that the correlation matrix is positive definite; if so, store its
% Choleski factor as a field
try
    Copula.cholR = chol(Copula.Parameters);
catch
    error(['Error: The copula correlation matrix is not positive' ...
           ' definite or is incorrectly defined!']);
end

% Remove machine errors on main diag
pos_plus1 = find(C == 1);
pos_minus1 = find(C == -1);
pos_zeros = find(C == 0);

if uq_isnonemptyfield(Copula, 'Parameters')
    Copula.Parameters(pos_plus1) = 1; 
    Copula.Parameters(pos_minus1) = -1; 
    Copula.Parameters(pos_zeros) = 0; 
end

if uq_isnonemptyfield(Copula, 'TauK')
    Copula.TauK(pos_plus1) = 1;
    Copula.TauK(pos_minus1) = -1;
    Copula.TauK(pos_zeros) = 0;
end

if uq_isnonemptyfield(Copula, 'RankCorr')
    Copula.RankCorr(pos_plus1) = 1;
    Copula.RankCorr(pos_minus1) = -1;
    Copula.RankCorr(pos_zeros) = 0;
end
