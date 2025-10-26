function [Mu1, Mu2, Sigma12, Sigma22, Cov] = uq_bayesianlinesampling_correlation(current_model, X1, X2)
% [Mu1, Mu2, Sigma12, Sigma22, Cov] = uq_bayesianlinesampling_correlation(current_model, X1, X2)
%      evaluates the correlation between the input matrices X1 and X2 in a
%      format that is needed for bayesianlinesampling. Additionally the
%      mean and std of the model output corresponding to X1 and X2 are
%      given.
% 
% See also: uq_bayesianlinesampling, uq_Kriging_eval

%% Map X0 to the appropriate space to get U0‚
SCALING = current_model.Internal.Scaling;
SCALING_BOOL = isa(SCALING, 'double') || isa(SCALING, 'logical') || ...
    isa(SCALING, 'int');
        
if SCALING_BOOL && SCALING
    muX = current_model.Internal.ExpDesign.muX;
    sigmaX = current_model.Internal.ExpDesign.sigmaX;
    U1 = bsxfun(@rdivide, (bsxfun(@minus, X1, muX)), sigmaX);
    U2 = bsxfun(@rdivide, (bsxfun(@minus, X2, muX)), sigmaX);
elseif SCALING_BOOL && ~SCALING
    U1 = X1;
    U2 = X2;
end

if ~SCALING_BOOL
    % In that case, SCALING is an INPUT object.
    % An isoprobabilistic transform is performed
    % from: current_model.Internal.Input
    % to  : current_model.Internal.Scaling
    U1 = uq_GeneralIsopTransform(X1,...
        current_model.Internal.Input.Marginals,...
        current_model.Internal.Input.Copula,...
        SCALING.Marginals, SCALING.Copula);

    U2 = uq_GeneralIsopTransform(X2,...
        current_model.Internal.Input.Marginals,...
        current_model.Internal.Input.Copula,...
        SCALING.Marginals, SCALING.Copula);
end


% Extract the correlation function and parameters from the model
evalR_handle = current_model.Internal.Kriging(1).GP.Corr.Handle;
evalF_handle = current_model.Internal.Kriging(1).Trend.Handle;
theta = current_model.Internal.Kriging(1).Optim.Theta;
GPCorrOptions = current_model.Internal.Kriging(1).GP.Corr;
sigmaSQ = current_model.Internal.Kriging(1).GP.sigmaSQ;
R = current_model.Internal.Kriging(1).GP.R;
beta = current_model.Internal.Kriging(1).Trend.beta;
Y = current_model.ExpDesign.Y(:);

F = current_model.Internal.Kriging(1).Trend.F;  % Information matrix
U = current_model.ExpDesign.U;  % Scaled training inputs

if isempty(current_model.Internal.Kriging(1).Cached)
    auxMatrices = uq_Kriging_calc_auxMatrices(R, F, Y, 'default');
else
    auxMatrices = current_model.Internal.Kriging(1).Cached;
end
% Retrieve some auxiliary matrices
FTRinv = auxMatrices.FTRinv;   % F^T * R^(-1)
FTRinvF = auxMatrices.FTRinvF; % F^T * R^(-1) * F

if any(isnan(auxMatrices.cholR(:)))
    Rinv = auxMatrices.Rinv;  % pseudo-inverse of R
else
    L = auxMatrices.cholR;
    Rinv = L \ (transpose(L) \ eye(size(L)));
end

CrossCorOpts = GPCorrOptions;
CrossCorOpts.Nugget = 0;  % force nugget to 0

%% Mean
r1 = evalR_handle(U1, U, theta, CrossCorOpts);
f1 = evalF_handle(U1,current_model);
Mu1 = f1*beta + r1 * (Rinv * (Y - F*beta));

r2 = evalR_handle(U2, U, theta, CrossCorOpts);
f2 = evalF_handle(U2,current_model);
Mu2 = f2*beta + r2 * (Rinv * (Y - F*beta));

%% Variance
u1 = FTRinv * r1.' - f1.';
u2 = FTRinv * r2.' - f2.';

D11 = uq_Kriging_calc_DiagOfCongruent(r1,R);
D21 = uq_Kriging_calc_DiagOfCongruent(transpose(u1),FTRinvF);
Sigma12 = sigmaSQ * (ones(size(D11))-D11+D21);

D12 = uq_Kriging_calc_DiagOfCongruent(r2,R);
D22 = uq_Kriging_calc_DiagOfCongruent(transpose(u2),FTRinvF);
Sigma22 = sigmaSQ * (ones(size(D12))-D12+D22);

%% Covariance
N = size(U1,1);
Cov = zeros(N,1);

U0 = [U1(1,:); U2(1,:)];
f0 = evalF_handle(U0,current_model);

for i = 1:N
    U0 = [U1(i,:); U2(i,:)];
    r0 = evalR_handle(U0, U, theta, CrossCorOpts);
    u0 = FTRinv * r0.' - f0.';
    D1 = r0 * Rinv * transpose(r0);
    D2 = transpose(u0) * (FTRinvF \ u0);
    CorrU0 = evalR_handle(U0, U0, theta, GPCorrOptions);
    YCovOO = sigmaSQ * (CorrU0-D1+D2);
    Cov(i) = YCovOO(3);
end

end
