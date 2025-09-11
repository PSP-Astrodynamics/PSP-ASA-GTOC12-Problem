function Results = uq_LRA_CV(U_ED, Y_ED, SelectionOptions)
% Results = UQ_LRA_CV(U_ED,Y_ED,SelectionOptions)
%
% This function returns the N-fold cross validation errors for LRA of rank
% up to Rank (specified in SelectionOptions) the LRA is built using the
% standardized ED, U_ED, and the respective model responses, Y_ED
% Optionally it skips some pairs of rank-degree if they have already been
% computed from the adaptation strategy that uses it.
%

Options = SelectionOptions.Options;

Options.AdaptationMethod = SelectionOptions.Method;
%%
% Retrieve the information needed from the SelectionOptions object:
nfolds = Options.Parameters.NFolds;
Rank = Options.Rank;
Degree = Options.Degree;

%%
% This is left here in case consistent CV scores are wanted in the future.
% 
% get rng state - set to previous in the end for consistency in rest of
% UQLab:
% r = rng;

%%
% It is useful to skip some r,p pairs for some adaptation strategies:
if isfield(Options,'SkipPairs')
    % If some r,p pairs are to be skipped
    SkipPairs = Options.SkipPairs;
else
    % That is to never skip a r,p pair:
    SkipPairs = [NaN];
end
%%
% Randomly split ED in nfolds parts
N_ED = length(Y_ED);
ind_rand = randperm(N_ED);
N_part = int32(N_ED/nfolds);

%%
% Pre-allocate
err_test = zeros(nfolds,length(Rank),length(Degree)).*nan;
LRA = cell(1,nfolds);

%%
% This propagates other important computational parameters important to the
% meta-model evaluation:
CVOptions = Options;

%%
% For increasing degree and rank, compute the CV error. 
% Stop if the error only increases according to EarlyStop.
for p = 1:length(Degree)
    
    CVOptions.Degree = Degree(p);
    
    for r = 1:length(Rank)
                
        % For the rank-first adaptivity the maximum rank should be passed
        % and the loop over the ranks is stopped at the first rank 
        % iteration!
        % (see end of loop)
        if strcmpi(CVOptions.AdaptationMethod,'all_r_adapt_d')
            CVOptions.Rank = min(Rank):max(Rank);
        else
            % More general adaptivity methods might consider different
            % degrees and different ranks to guide the adaptivity procedure, 
            % therefore a specific rank is looped over.
            CVOptions.Rank = Rank(r);
        end
        
        % The "SkipPairs" is used to avoid computation of rank and degree
        % pairs that were already computed before:
        if any(sum(ismember(SkipPairs,[Rank(r),Degree(p)]),2)==2)
            % Skip this step
            err_test(:,r,p) = NaN;
            continue;
        end
        
        for k = 1:nfolds

            % Get indices of testing and training sets
            if k == nfolds
                ind_test = ind_rand((k-1)*N_part+1:N_ED);
            else
                ind_test = ind_rand((k-1)*N_part+1:k*N_part);
            end
            ind_train = ind_rand(ismember(ind_rand,ind_test) == 0);

            % Training set
            U_train = U_ED(ind_train,:);
            Y_train = Y_ED(ind_train);

            % Testing set
            U_test = U_ED(ind_test,:);
            Y_test = Y_ED(ind_test);

            % For every set of ranks or degrees we compute a score for the
            % current "kth - fold". The uq_LRA_train_test should stop in lower 
            % ranks/degrees if instructed by the options to do so according to
            % EarlyStop.
            %
            % the k-th testing set provides the corresponding error estimates
            Results_train_test = uq_LRA_train_test(...
                U_train, Y_train, U_test,...
                Y_test, CVOptions);

            % Store the error estimates and LRA properties at the k-th step
            if strcmpi(CVOptions.AdaptationMethod,'all_r_adapt_d')
                err_test(k,:,p) = Results_train_test.err_test;
            else
                err_test(k,r,p) = Results_train_test.err_test;
            end
            LRA{k} = Results_train_test.LRA;
            clear Results_train_test
        end
        mean_err = mean(err_test);
        
        if Options.Display > 1
            if strcmpi(CVOptions.AdaptationMethod,'all_r_adapt_d')
                % Report the best rank for the current considered degree 
                % and the corresponding CV score:
                mean_err = mean(err_test(:,:,p));
                mean_err = mean_err(:)';
                [min_cv, idx_min_cv] = min(mean_err);
                stepInfo.Rank = Rank(idx_min_cv);
                stepInfo.CVScore = min_cv;
                stepInfo.p = Degree(p);
            else
                stepInfo.Rank = Rank(r);
                stepInfo.CVScore = mean_err(r);
                stepInfo.p = Degree(p);
            end
            Options.ReportStep(stepInfo);
        end
        
        if Options.EarlyStop && r>2
            if Options.EarlyStopFunction(mean(err_test(:,1:r,p)))
                % output:
                errCV = mean(err_test);
                Results.errCV = errCV;
                Results.LRA = LRA;
                return;
            end
        end
        
        % in the all_r_adapt_d strategy, the CV scores for the ranks are
        % returned all at once, therefore there is no need to loop over
        % the ranks:
        if strcmpi(CVOptions.AdaptationMethod,'all_r_adapt_d')
            break;
        end
    end
    
    % Check if the validation error is increasing with increasing degree:
    if Options.EarlyStop && p>2
        curr_errs=mean(err_test(:,r,1:p));
        if Options.EarlyStopFunction(curr_errs(:))
            % output:
            errCV = mean(err_test);
            Results.errCV = errCV;
            Results.LRA = LRA;
            return
        end
    end
end

%% 
% For future reference:
% In case consistent CV scorring is required in the future, get the rng
% state in the beginning and set it back to the previous state in the end:
% 
% set rng state:
% rng(r);

% output:
errCV = mean(err_test);
Results.errCV = errCV;
Results.LRA = LRA;