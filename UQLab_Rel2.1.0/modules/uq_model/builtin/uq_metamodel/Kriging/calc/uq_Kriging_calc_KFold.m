function [cvErrors,cvSigma2] = uq_Kriging_calc_KFold(randIdx, Y, F, auxMatrices)
%UQ_KRIGING_CALC_KFOLD computes the K-fold CV errors. 
%
%   UQ_KRIGING_CALC_KFOLD(randIdx, Y, F, auxMatrices) computes the K-fold
%   cross-validation (CV) errors for classes (batches/folds) defined by 
%   the indices of experimental design given in the cell array randIdx;
%   using an N-by-1 observed response vector Y, observation matrix F,
%   and a set of pre-computed auxiliary matrices auxMatrices:
%       auxMatricesFTRinv       : F^T * R^(-1) 
%       auxMatrices.FTRinvF     : F^T * R^(-1) * F
%       auxMatrices.FTRinvF_inv : (F^T * R^(-1) * F)^(-1)
%       auxMatrices.cholR;      : L, such that L^T * L
%   Each element of the cell array randIdx is a fold and contains the
%   indices of the experimental design points that belong to a fold.
%
%   [cvErrors,cvSigma2] = UQ_KRIGING_CALC_KFOLD(...) additionally returns
%   the Kriging predictor variance at the validation points.
%
%   See also UQ_KRIGING_CALCULATE, UQ_KRIGING_OPTIMIZER, 
%   UQ_KRIGING_EVAL_J_OF_THETA_CV.

%% Get the number of observations
N = size(Y,1);

%% Compute the B1 matrix
B1 = calc_B1(auxMatrices, F, N);

%% Compute the K-fold CV errors and the additional error metrics
[cvErrors,cvSigma2] = calc_cvErrors(randIdx, B1, Y);

end

function B1 = calc_B1(auxMatrices, F, N)
%CALC_B1 computes the B1 matrix.
%
%   Matrix B1 is defined as the first N-by-N elements of the inverse of S,
%   divided by the Gaussian process variance
%       S = [C F; F 0]
%       B1(i,j) = S^(-1)(i,j), i,j = 1,...,N
%   where,
%       C: Covariance matrix
%       F: Observation matrix
%
%   The matrix B can be computed as follows 
%       B1 = C^(-1) * [In - F*(F^T*C^(-1)*F)^(-1)*(F^T*C^(-1))]
%   where In is the identity matrix of size N.
%   
%   If the Cholesky decomposition of C exists, such that C = L^T * L, then
%       B1 = L^(-1) * L^(T,-1) * [In - F*(F^T*C^(-1)*F)^(-1)*(F^T*C^(-1))]
%
%   Notes:
%
%   - If R (correlation matrix) is used in the computation of auxMatrices,
%     then B1 is normalized to the Gaussian process variance.
%   - If C (covariance matrix) all the formulas below apply with C's
%     replaced with R's and implied in auxMatrices.
%   - For details about the origin of B1 matrix, refer to Dubourg ().
%   - For details about the computation of B1 matrix, refer to Rasmussen
%     and Williams 
%
%   References:
%
%   - Dubourg, V. (2011). Adaptive surrogate models for reliability
%     analysis and reliability-based design optimization. Ph. D. thesis,
%     Universite Blaise Pascal, Clermont-Ferrand, France.
%   - Rasmussen, C. and C. Williams (2006). Gaussian processes for machine
%     learning. Cambridge, Massachusetts: MIT Press.

FTRinv = auxMatrices.FTRinv;    % F^T * R^(-1)
FTRinvF = auxMatrices.FTRinvF;  % F^T * R^(-1) * F
FTRinvF_inv = auxMatrices.FTRinvF_inv;  % (F^T * R^(-1) * F)^(-1)
L = auxMatrices.cholR;          % R = L^T * L
if ~isnan(L)
    if ~isempty(FTRinvF_inv)
        MM = eye(N) - F*FTRinvF_inv*FTRinv;
    else
        MM = eye(N) - F*(FTRinvF \ FTRinv);
    end
    B1 = L \ (transpose(L) \ MM);
else
    Rinv = auxMatrices.Rinv;    % Pseudo-inverse of R or C
    if ~isempty(FTRinvF_inv)
        MM = eye(N) - F*FTRinvF_inv*FTRinv;
    else
        MM = eye(N) - F*(FTRinvF \ FTRinv);
    end
    B1 = Rinv * MM;
end

end

function [cvErrors,cvSigma2] = calc_cvErrors(randIdx, B1, Y)
%CALC_CVERRORS computes K-fold CV errors given B1 matrix and obs.responses.
%
%   cvErrors = calc_CVErrors(randIdx, B1, Y) returns a cell array of
%   cross-validated (CV) Kriging predictor errors. Each elementary cell
%   contains CV errors for experimental design points specified by the
%   indices in the cell array ranIdx. The computation also requires the
%   matrix B1 and the vector of observed responses Y.
%
%   [cvErrors,cvSigma2] = calc_CVErrors(...) additionally returns a
%   cell array cvSigma2, in which each cell contains the Kriging
%   predictor variance for each of the cross-validation prediction points.
%
%   Notes:
%
%   - If R is used in the computation of B1, then cvSigma2 corresponds
%     to the normalized (with respect to the Gaussian process variance)
%     Kriging predictor variance at the validation points.
%   - If C is used in the computation of B1, then cvSigma2 corresponds to
%     the Kriging predictor variance at the validation points. 
%
%   Reference:
%
%   - Dubrule, O. (1983). Cross validation of Kriging in a unique
%     neighborhood. Journal of the International Association for
%     Mathematical Geology. 15(2). pp. 687-699.

%% Get the number of observations
N = size(B1,1);

%% Compute the number of classes
nClasses = numel(randIdx);

%% Initialize variables
cvErrors = cell(nClasses,1);
cvSigma2 = cell(nClasses,1);

%% Compute the K-fold CV errors
if nClasses == N
    % N-fold (Leave-one-out) CV
    yPredVar = 1./diag(B1);
    yPredMu = -1 * (bsxfun(@times,yPredVar,(B1*Y)) - Y);
    cvErrors = num2cell((yPredMu - Y).^2);
    cvSigma2 = num2cell(yPredVar);
else
    % K-fold CV
    for nClass = 1:nClasses
        % Select the validation points
        idxValidate = randIdx{nClass};
        yValidate = Y(idxValidate);
        % Select the training points
        idxTrain = true(size(1:N));
        idxTrain(idxValidate) = false;
        yTrain = Y(idxTrain);
        % Compute CV prediction and its variance (Dubrule, 1983)
        yPredMu = -(B1(idxValidate,idxValidate) \ B1(idxValidate,idxTrain)) ...
            * yTrain;
        yPredVar = B1(idxValidate,idxValidate) \ eye(numel(idxValidate));
        % Compute CV errors and predictor variance
        cvErrors{nClass} = (yValidate - yPredMu).^2;
        cvSigma2{nClass} = diag(yPredVar);
    end
end

end
