function Results  = uq_LRA_train_test(U_train, Y_train, U_test, Y_test, Options)
% This function builds LRA using the set (U_train, Y_train) and evaluates
% the error using the set (U_test, Y_test)

%% Get information from function input
Method_corr = Options.CorrStep;
Method_updat = Options.UpdateStep;
UnivBasis = Options.UnivBasis;
N_train = length(Y_train);
N_test = length(Y_test);

% The ranks are constructed one at a time. The 'train_test' procedure
% will find the CV score for all ranks up to Rank. Rank might be a
% vector to satisfy uqlab conventions. In that case, the Rank will be
% the length of the vector. In case the adaptation strategy is
% all_r_adapt_d, we compute for all the ranks up to max(Rank) and allow 
% the final model to acquire ranks in the range determined at the user
% input level.
if length(Options.Rank)>1
    CV_ranks = Options.Rank;
    r_max = max(Options.Rank);
else
    CV_ranks = Options.Rank;
    r_max = Options.Rank;
end

Err_test = zeros(length(Options.Rank),length(Options.Degree)).*nan;

for p = Options.Degree
    %% 
    % Evaluate orthonormal univariate basis (p.ex. polynomials) at U_train 
    % and U_test
    P_train = uq_LRA_evalBasis(U_train, UnivBasis, p);
    P_test  = uq_LRA_evalBasis(U_test, UnivBasis, p);


    %% Sequence of correction-updating steps

    % Initialize variables
    w = zeros(N_train,r_max);
    z = cell(1,r_max);
    b = zeros(r_max,1);

    % Set parameters for the stopping criterion in the correction step
    StopParam.varY = std(Y_train)^2;
    StopParam.stop_Derr = Options.CorrStep.MinDerrStop;
    StopParam.stop_iterNo = Options.CorrStep.MaxIterStop;

    % Set initial residual
    res = Y_train;

    % this loop will give us CV scores for all the ranks in the CV_ranks
    % range:
    for l = 1:max(CV_ranks)

        % Correction step
        ResultsCorr = uq_LRA_CorrStep(P_train, res, StopParam, Method_corr);

        z{l} = ResultsCorr.z_l;
        w(:,l) = ResultsCorr.w_l;

        % Updating step
        ResultsUpdate = uq_LRA_UpdateStep(w(:,1:l), Y_train, Method_updat);
        b(1:l) = ResultsUpdate.b;
        res = ResultsUpdate.res;

        % Error estimate using the testing set if the considered rank is
        % allowed.
        if any(ismember(l,CV_ranks))
            Yhat_test = uq_LRA_evalCurrentModel(P_test, z, b, l);
            % The intended usage is to compute for some specific rank and 
            % degree. However, it is possible to compute for multiple 
            % degrees and up to multiple ranks.
            Err_test(ismember(CV_ranks,l),ismember(Options.Degree,p)) = ...
                sum((Y_test-Yhat_test).^2)/N_test;            
        end
    end
end
% Normalize error
err_test = Err_test/std(Y_test)^2;

%% Set function output
Results.err_test = err_test;
Results.LRA.Coefficients.z = z;
Results.LRA.Coefficients.b = b;

