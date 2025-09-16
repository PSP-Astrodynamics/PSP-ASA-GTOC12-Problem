function [SelectionResults] = uq_LRA_adaptive_grad(ComputationalOptions,U_ED,Y_ED_oo)
% [SelectionResults] = UQ_LRA_ADAPTIVE_GRAD(ComputationalOptions,U_ED,Y_ED_oo)
% 
% Inputs:
%
%   ComputationalOptions: The rank and degree selection options
%   U_ED : The ED input
%   Y_ED_oo : The full model response
%
% Outputs:
% 
%   SelectionResults: Contains the selected 'R' and 'Degree'. 
%                     Also contains the 'CVerr'.
%
% summary:
%
%  An adaptive strategy for rank and degree selection of LRA where 
%  finite difference gradients of the error w.r.t. rank and degree are 
%  computed.
%  
%  f_r: RankSelectionOptions.Options.EarlyStopFunction(cvscores)   
%  f_p: DegSelectionOptions.Options.EarlyStopFunction(cvscores) 
%

% this might be changed later:
max_allowed_steps = 200;

RankSelectionOptions = ComputationalOptions.RankSelectionOpts;
DegSelectionOptions = ComputationalOptions.DegSelectionOpts;

NRanks = length(RankSelectionOptions.Options.Rank);
NDegrees = length(DegSelectionOptions.Options.Degree);

err_deg_best_for_r = zeros(1,NRanks);

best_r = 0;
best_p = 0;
best_cv = inf;
Scores = struct('R',[],'p',[],'Score',[]);

p_current = 1;
r_current = 1;
if length(DegSelectionOptions.Options.Degree) == 1
    error('There is no need to use the adapt_r_d method - you have prescribed the degree!');
end
if length(RankSelectionOptions.Options.Rank) == 1
    error('There is no need to use the adapt_r_d method - you have prescribed the degree!');
end

max_degree = max(DegSelectionOptions.Options.Degree);
max_rank   = max(RankSelectionOptions.Options.Rank);

curr_degree = DegSelectionOptions.Options.Degree(p_current);
curr_rank = RankSelectionOptions.Options.Rank(r_current);

curr_cv =[];
all_R = [];all_p = [];
scores = [];
SkipPairs = [NaN NaN];

for kk = 1:max_allowed_steps
    
    % start with the first degree and rank and  compute a numerical
    % estimate for the CV gradient:
    curr_degree_p1 = curr_degree+1;
    curr_rank_p1 = curr_rank+1;
    
    % now compute the CV errors for all 4 possible setups:
    Rank = [curr_rank, curr_rank_p1];
    Degree = [curr_degree, curr_degree_p1];
    
    cvopts = RankSelectionOptions;
    cvopts.Options.Rank  = Rank;
    cvopts.Options.Degree   = Degree;
    cvopts.Options.SkipPairs = SkipPairs;
    cvopts.Method = 'adapt_r_d';
    cv_results = uq_LRA_CV(U_ED,Y_ED_oo,cvopts);
    all_R = [all_R,curr_rank, curr_rank_p1,curr_rank, curr_rank_p1];
    all_p = [all_p, curr_degree, curr_degree, curr_degree_p1, curr_degree_p1];
    
    if any(isnan(cv_results.errCV(:)))
        cv_results.errCV(isnan(cv_results.errCV)) = curr_best;
    end
    
    scores = [scores, cv_results.errCV(:,1,1), cv_results.errCV(:,2,1),...
        cv_results.errCV(:,1,2), cv_results.errCV(:,2,2)];
    
    if min(cv_results.errCV(:) == cv_results.errCV(:,1,1))
        % That means that the rank and degree should not be changed:
        curr_best = cv_results(:,1,1);
        continue;
    end
    % If best LRA is R <- R+1 and p <- p+1
    % and maximum degree and rank criteria are not violated:
    if min(cv_results.errCV(:)) == cv_results.errCV(:,2,2) && (curr_degree+1)<max_degree && (curr_rank+1)<max_rank
        
        curr_degree = curr_degree+1;
        curr_rank = curr_rank +1 ;
        SkipPairs = [SkipPairs;curr_rank,curr_degree];
        curr_best = cv_results.errCV(:,2,2);
        curr_cv = [curr_cv,curr_best];
        continue;
    end
    
    % If best LRA is p <- p+1 and degree criterion is not violated:
    if min(cv_results.errCV(:)) == cv_results.errCV(:,1,2) && (curr_degree+1)<max_degree
        
        curr_degree = curr_degree+1;
        SkipPairs = [SkipPairs;curr_rank,curr_degree];
        curr_best = cv_results.errCV(:,1,2);
        curr_cv = [curr_cv , curr_best];
        continue;
    end
    
    % If best LRA is R<- R+1 and maximum rank criterion is not violated:
    if min(cv_results.errCV(:)) == cv_results.errCV(:,2,1) && (curr_rank+1)<max_rank
        curr_rank = curr_rank+1;
        SkipPairs = [SkipPairs;curr_rank,curr_degree];
        curr_best = cv_results.errCV(:,2,1);
        curr_cv = [curr_cv, curr_best];
        continue;
    end
    
    if kk == 1 && min(cv_results.errCV(:)) == cv_results.errCV(:,1,1)
        curr_best =  cv_results.errCV(:,1,1);
    end
        
    % If none of the above cases was satified, the algorithm converged.
    % Therefore terminate and return best:
    best_cv = min(curr_best);
    R = curr_rank;
    p = curr_degree;
    break;
    % terminate if for a certain number of consequtive steps the CV does
    % not increase at all.
end
    
% In this strategy the degree is the final CV score for the selection:
SelectionResults.CVScore = best_cv;
SelectionResults.Strategy = 'basic 1st order gradient descent';
SelectionResults.Scores.Score = scores;
SelectionResults.Scores.R = all_R;
SelectionResults.Scores.p = all_p;
SelectionResults.Degree = p;
SelectionResults.R = R;
