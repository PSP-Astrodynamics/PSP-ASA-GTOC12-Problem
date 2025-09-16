function [SelectionResults] = uq_LRA_adaptive_all_r_adapt_d(ComputationalOptions,U_ED,Y_ED_oo)
% [SelectionResults] = UQ_LRA_ADAPTIVE_ALL_R_ADAPT_D(ComputationalOptions,U_ED,Y_ED_oo)
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
%  rank the best degree is selected. If the CV score is only getting larger
%  for two succesive ranks the procedure stops.
%
%  Pseudo-code:
% 
%    for each rank R  in r_min:r_max
%      for each degree p - p_min:p_max
%        the CV score is computed
%        if Early stop for degree & CV score increasing - 
%          next R
%        end
%      end
%      if EarlyStop for rank & CV score is increasing for two succesive ranks
%        set opt. rank and degree estimation and exit loop.
%      end
%    end
%  

RankSelectionOptions = ComputationalOptions.RankSelectionOpts;
DegSelectionOptions = ComputationalOptions.DegSelectionOpts;

NRanks = length(RankSelectionOptions.Options.Rank);
NDegrees = length(DegSelectionOptions.Options.Degree);

err_deg_best_for_r = zeros(1,NRanks);

Scores = struct('R',[],'p',[],'Score',[]);

% The loop over the ranks is not needed, it is performed in the
% uq_LRA_CV function directly during the construction of the LRA. This is a
% computational advantage due to the algorithm described in 
% 
% "Uncertainty quantification in high-dimensional spaces with low-rank 
% tensor approximations"
% K Konakli, B Sudret
%

curr_rank = RankSelectionOptions.Options.Rank;
% The loop for the degrees is internal to the degree selection
% function. It also takes care of the early stopping
DegSelectionOptions = ComputationalOptions.DegSelectionOpts;

% The selection options contain the adaptivity method in order to skip 
% the explicit computation of the CV score for LRA with lower ranks 
% since it is readilly available through the algorithm proposed in:
%
% "Uncertainty quantification in high-dimensional spaces with low-rank 
% tensor approximations"
% K Konakli, B Sudret
DegSelectionOptions.Method = ComputationalOptions.Method;

% Set the rank to what it is from the outer loop:
DegSelectionOptions.Options.Rank = curr_rank;
DegSelectionResults = ...
    ComputationalOptions.DegSelectionOpts.ScoreFunction(...
    U_ED, Y_ED_oo, DegSelectionOptions);

% Here the CV results are flattened for further processing:
p_vals = repmat(DegSelectionOptions.Options.Degree,size(DegSelectionResults.errCV,2),1);
Scores.p = [Scores.p,p_vals(:)'];    
r_vals = repmat(DegSelectionOptions.Options.Rank,1,size(DegSelectionResults.errCV,3));
Scores.R = [Scores.R,r_vals];
Scores.Score = DegSelectionResults.errCV(:)';

err_all = Scores.Score;
[best_cv, idx_min] = min(err_all);

% The adaptation procedure should have early-stopped internally in the 
% CV error computation (to take advantage of the LRA determination
% procedure).
% Therefore now we only need to report the model with the best
% degree/rank pair:
best_r = Scores.R(idx_min);
best_p = Scores.p(idx_min);
if DegSelectionOptions.Options.Display
    % Report when a better degree and rank are encountered:
    disp_degree.Degree = best_p;
    disp_degree.Rank = best_r;
    disp_degree.CVScore = best_cv;
    disp_degree.isSelected = 'Selected';
    DegSelectionOptions.Options.ReportResults(disp_degree);
end


if RankSelectionOptions.Options.Display
    % Report the rank and degree selection results:
    disp_results.Rank = best_r;
    disp_results.CVScore = best_cv;
    disp_results.isSelected = 'Selected';
    RankSelectionOptions.Options.ReportResults(disp_results);
end

SelectionResults.R = best_r;
SelectionResults.Degree = best_p;

% In this strategy the degree is the final CV score for the selection:
SelectionResults.CVScore = best_cv;
SelectionResults.Strategy = 'All Ranks - Adapt Degrees';
SelectionResults.Scores = Scores;