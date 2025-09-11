function [SelectionResults] = uq_LRA_adaptive_all_d_adapt_r(ComputationalOptions,U_ED,Y_ED_oo)
% [SelectionResults] = UQ_LRA_ADAPTIVE_ALL_D_ADAPT_R(ComputationalOptions,U_ED,Y_ED_oo)
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
%  An adaptive strategy for rank and degree selection of LRA where for each
%  degree the best rank is selected. If the CV score is only getting larger
%  according to DegSelectionOptions.Options.EarlyStopFunction the
%  procedure stops.
%  
%  f_r: RankSelectionOptions.Options.EarlyStopFunction(cvscores)   
%  f_p: DegSelectionOptions.Options.EarlyStopFunction(cvscores) 
%
%  Pseudo-code:
% 
%    for each rank p in p_min:p_max
%      for each degree r - r_min:r_max
%        the CV score is computed
%        if Early stop for rank & CV score increasing according to f_r
%          next p
%        end
%      end
%      if EarlyStop for degree & CV score is increasing according to f_p
%        set opt. rank and degree estimation and exit loop.
%      end
%    end
%  

RankSelectionOptions = ComputationalOptions.RankSelectionOpts;
DegSelectionOptions = ComputationalOptions.DegSelectionOpts;

NRanks = length(RankSelectionOptions.Options.Rank);
NDegrees = length(DegSelectionOptions.Options.Degree);

err_deg_best_for_r = zeros(1,NRanks);

best_r = 0;
best_p = 0;
best_cv = inf;
Scores = struct('R',[],'p',[],'Score',[]);

for p = 1:NDegrees
    
    curr_degree = DegSelectionOptions.Options.Degree(p);
    
    % The loop for the degrees is internal to the degree selection
    % function. It also takes care of the early stopping
    RankSelectionOptions = ComputationalOptions.RankSelectionOpts;
    
    % Set the degree to what it is from the outer loop:
    RankSelectionOptions.Options.Degree = curr_degree;
    RankSelectionOptions.Method = 'all_d_adapt_r';
    RankSelectionResults = ...
        ComputationalOptions.RankSelectionOpts.ScoreFunction(...
        U_ED, Y_ED_oo, RankSelectionOptions);
    
    % Save the results of the rank selection:
    
    % We have to index the ranks since the rank selection might have
    % early-stopped.
    res_inds = 1:length(RankSelectionResults.errCV);
    r_vals = RankSelectionOptions.Options.Rank(res_inds);
    Scores.R = [Scores.R,r_vals];
    Scores.p = [Scores.p,repmat(curr_degree,1,length(r_vals))];
    Scores.Score = [Scores.Score RankSelectionResults.errCV];
    
	% "early stop" and update best_r, best_p

    % If the best CV error for the ranks we considered for the current
    % degree, is better than the best for the previous ones update the
    % best_r, best_p.
    err_allRanks = RankSelectionResults.errCV;
	[err_rank, idx_min] = min(err_allRanks);
    
    err_deg_best_for_r(p) = err_rank;
    
    if err_rank<best_cv
        best_cv = err_rank;
        best_r = RankSelectionOptions.Options.Rank(idx_min);
        best_p = curr_degree;
        
        if RankSelectionOptions.Options.Display
            % Report when a better degree and rank are encountered:
            disp_rank.Degree = best_p;
            disp_rank.Rank = best_r;
            disp_rank.CVScore = err_rank;
            disp_rank.isSelected = 'Selected';
            RankSelectionOptions.Options.ReportResults(disp_rank);
        end
    end
    
    % Early Stop for degree:
	% If the best_r, best_p only increases for n-consecutive ranks, stop 
    % looking at higher degrees (early stop)
    if DegSelectionOptions.Options.EarlyStop && ...
        DegSelectionOptions.Options.EarlyStopFunction(err_deg_best_for_r(1:p))
        break;
    end
end

if RankSelectionOptions.Options.Display
    % Report the rank and degree selection results:
    disp_results.Rank = best_r;
    disp_results.CVScore = best_cv;
    disp_results.Degree = best_p;
    disp_results.isSelected = 'Selected';
    DegSelectionOptions.Options.ReportResults(disp_results);
end

SelectionResults.R = best_r;
SelectionResults.Degree = best_p;

% In this strategy the degree is the final CV score for the selection:
SelectionResults.CVScore = best_cv;
SelectionResults.Strategy = 'All Degrees - Adapt Ranks';
SelectionResults.Scores = Scores;
