function YCov = uq_Kriging_calc_PosteriorCovariance(U1,U2,current_model)
%UQ_KRIGING_CALC_POSTERIORCOVARIANCE computes the posterior covariance of a
% Gaussian process model
%
% Ycov = UQ_KRIGING_CALC_POSTERIORCOVARIANCE(U1,U2,CURRENT_MODEL) returns
% the posterior cross-covariance of size N1 x N2 between the (N1-by-M) U1
% and (N2-by-M) U2 vectors given the Kriging model in CURRENT_MODEL.
%
% For simple Kriging
% YCOv(U1,U2) = C(U1,U2) - C(U1,U) . C^-1 . C(U,U2)
% For universal Kriging
% YCov(U1,U2) = C(U1,U2) - C(U1,U) . C^-1 . C(U,U2) + u(U1) F'R^(-1)F u(U2)

% Number of outputs
Nout = current_model.Internal.Runtime.Nout;

% Size of the inputs
N1 = size(U1,1);
N2 = size(U2,1) ;
isGram = (N1 == N2) && isequal(U1,U2);

% Experimental design sampled in the scaled space
U = current_model.ExpDesign.U;

%% Retrieve the necessary matrices

F = current_model.Internal.Kriging(1).Trend.F;  % Information matrix

%% Calculate f0 (the trend basis functions value for the input U1 and U2)
evalF_handle = current_model.Internal.Kriging(1).Trend.Handle;
f_U1 = evalF_handle(U1,current_model);
if isGram
    f_U2 = f_U1 ;
else
    f_U2 = evalF_handle(U2,current_model);
end

for oo = 1:Nout
    %% Retrieve necessary quantities as local variables
    Y = current_model.ExpDesign.Y(:,oo);
    theta = current_model.Internal.Kriging(oo).Optim.Theta;
    evalR_handle = current_model.Internal.Kriging(oo).GP.Corr.Handle;
    R = current_model.Internal.Kriging(oo).GP.R;
    sigmaSQ = current_model.Internal.Kriging(oo).GP.sigmaSQ;
    GPCorrOptions = current_model.Internal.Kriging(oo).GP.Corr;

    %% Retrieve quantities for Kriging regression
    if isfield(current_model.Internal,'Regression')
        sigmaNSQ = current_model.Internal.Regression(oo).SigmaNSQ;
        if current_model.Internal.Regression(oo).IsRegression
            if current_model.Internal.Regression(oo).IsHomoscedastic
                % If sigmaNSQ is known to be constant everywhere, work with tau
                % NOTE: R is already adjusted with tau
                sigmaTotSQ = sigmaNSQ + sigmaSQ;
                tau = sigmaNSQ/sigmaTotSQ;
            else
                % If sigmaNSQ are known at different points, work with cov.
                % NOTE: For compatibility, keep the name 'R' instead of 'C'
                R = sigmaSQ * R;
                if iscolumn(sigmaNSQ)
                    R = R + diag(sigmaNSQ);
                else
                    R = R + sigmaNSQ;
                end
            end
        end
    end


    %% Retrieve auxiliary matrices; If the cache is empty, calculate them
    if isempty(current_model.Internal.Kriging(oo).Cached)
        auxMatrices = uq_Kriging_calc_auxMatrices(R, F, Y, 'default');
    else
        auxMatrices = current_model.Internal.Kriging(oo).Cached;
    end
    % Retrieve some auxiliary matrices
    FTRinv = auxMatrices.FTRinv;   % F^T * R^(-1)
    FTRinvF = auxMatrices.FTRinvF; % F^T * R^(-1) * F


    %% Compute the cross-correlation between the given inputs U1,U2 and 
    % the training points U
    % This is the cross correlation matrix, nugget should not be applied.
    CrossCorOpts = GPCorrOptions;
    CrossCorOpts.Nugget = 0;  % force nugget to 0
    r_U1 = evalR_handle(U1, U, theta, CrossCorOpts);
    if isGram
        r_U2 = r_U1;
    else
        r_U2 = evalR_handle(U2, U, theta, CrossCorOpts);
    end

    %% Adjust the cross-correlation/covariance for regression model
    if isfield(current_model.Internal,'Regression')
        if current_model.Internal.Regression(oo).IsRegression
            if current_model.Internal.Regression(oo).IsHomoscedastic
                % Homogeneous noise case with tau
                r_U1 = (1-tau) * r_U1;
                r_U2 = (1-tau) * r_U2;

            else
                % Heterogenous noise casee
                r_U1 = sigmaSQ * r_U1;
                r_U2 = sigmaSQ * r_U2;

            end
        end
    end

    if any(isnan(auxMatrices.cholR(:)))
        Rinv = auxMatrices.Rinv;  % pseudo-inverse of R
    else
        L = auxMatrices.cholR;
        Rinv = L \ (transpose(L) \ eye(size(L)));
    end

    % Compute the part: D1 = r(U1) * R^(-1) * transpose(r(U2))
    D1 = r_U1 * Rinv * transpose(r_U2);

    % Compute the part: u0^T * (F^T*R^(-1)*F)^(-1) * u0
    if strcmpi(current_model.Internal.Kriging(oo).Trend.Type,'simple')
        % In case of simple Kriging this component is 0
        D2 = zeros(size(D1));
    else

        u_U1 =  FTRinv * r_U1.' - f_U1.';
        if isGram
            u_U2 = u_U1 ;
        else
            u_U2 =  FTRinv * r_U2.' - f_U2.';
        end
        D2 = transpose(u_U1) * (FTRinvF \ u_U2);
    end

    % Cross-correlation/Cross-covariance
    CorrU1U2 =  evalR_handle(U1, U2, theta, GPCorrOptions);


    if isfield(current_model.Internal,'Regression') && ...
            current_model.Internal.Regression(oo).IsRegression
        if current_model.Internal.Regression(oo).IsHomoscedastic
            % Homoscedastic case, tau is available
            CorrU1U2 = (1-tau) * CorrU1U2;  % Adjusted correlation
            YCovOO = sigmaTotSQ * (CorrU1U2-D1+D2);

        else
            % Heteroscedastic case
            % NOTE: D1 and D2 are not multiplied with variance;
            % variance information is already embedded in
            % D1 and D2 as they are computed using covariance.
            YCovOO = sigmaSQ*CorrU1U2 - D1 + D2;
        end
    else
        % Interpolation case
        YCovOO = sigmaSQ * (CorrU1U2-D1+D2);
    end

end
YCov(:,:,oo) = YCovOO;

end