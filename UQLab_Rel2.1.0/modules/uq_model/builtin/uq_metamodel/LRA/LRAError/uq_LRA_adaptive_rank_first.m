function [SelectionResults] = uq_LRA_adaptive_rank_first(ComputationalOptions,U_ED,Y_ED_oo)
% UQ_LRA_ADAPTIVE_RANK_FIRST(COMPUTATIONALOPTIONS,XY_ED)
%
% summary:
%
%  An adaptive strategy for LRA where the rank is chosen before the optimal
%  degree. The relevant options for the scoring function and the early-stop
%  criteria is internal to the DegSelectionOptions and
%  RankSelectionOptions.
%

% The ComputationalOptions includes the options proccessed during in
% initialization and the function to perform the selection. The same
% function can be used to perform CV based degree selection.
RankSelectionOptions = ComputationalOptions.RankSelectionOptions;
DegSelectionOptions = ComputationalOptions.DegSelectionOptions;

RankSelectionResults  = ...
    ComputationalOptions.RankSelectionOptions.ScoreFunction(...
    U_ED, Y_ED_oo, ComputationalOptions.RankSelectionOptions);

%R = Options.Rank;
err_allRanks = RankSelectionResults.errCV;

% The array of ranks considered for selection:
Rank = ComputationalOptions.RankSelectionOptions.Options.Rank;

% If the rank is to be selected:
if length(Rank)>1
    % Get error estimates for LRA of rank up to Rank
    
    [err_R, R_idx] = min(err_allRanks);        
    % Select the rank with the lowest store:
    R = Rank(R_idx);
    RankSelectionResults.isSelected = 'Selected';
else
    % The maximum rank was prescribed - it was not selected. 
    % The n-fold CV score is available and returned only for that rank.
    R = Rank;
    RankSelectionResults.isSelected = 'Prescribed';
    err_R = err_allRanks;
end
RankSelectionResults.Rank    = R;
RankSelectionResults.CVScore = err_R;

%% Reporting
DisplayLevel = RankSelectionOptions.Options.Display;
if DisplayLevel
    fprintf('%s\r',ComputationalOptions.RankSelectionOptions.Options.ReportResults(RankSelectionResults));
end

%% Degree Selection for determined rank:

% Retrieve the DegSelectionOptions:
DegSelectionOptions = ComputationalOptions.DegSelectionOptions;
% Now set the rank that was just selected:
DegSelectionOptions.Options.Rank = R;

if length(DegSelectionOptions.Options.Degree)>1
    DegSelectionResults  = ...
        ComputationalOptions.DegSelectionOptions.ScoreFunction(...
        U_ED, Y_ED_oo, DegSelectionOptions);

    err_allDegrees = DegSelectionResults.errCV;
    [err_deg, idx_min] = min(err_allDegrees);
    DegSelectionResults.isSelected = 'Selected';
    FinalDegree = DegSelectionOptions.Options.Degree(idx_min);

else
    % There was only one Degree given to consider - Degree selection is
    % not performed.
    FinalDegree = DegSelectionOptions.Options.Degree;
    DegSelectionResults.isSelected = 'Prescribed';
    err_deg = err_R;
end

DegSelectionResults.CVScore = err_deg;
DegSelectionResults.Rank  = R;

if DisplayLevel
    DegSelectionResults.Degree = FinalDegree;
    fprintf('%s\r',DegSelectionOptions.Options.ReportResults(DegSelectionResults));
end

SelectionResults.DegSelectionResults = DegSelectionResults;
SelectionResults.RankSelectionResults = RankSelectionResults;
SelectionResults.R = R;
SelectionResults.Degree = FinalDegree;
% In this strategy the degree is the final CV score for the selection:
SelectionResults.CVScore = err_deg;
SelectionResults.Strategy = 'Rank first strategy';
