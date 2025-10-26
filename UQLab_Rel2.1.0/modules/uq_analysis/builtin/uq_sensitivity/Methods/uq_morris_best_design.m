function Sample = uq_morris_best_design(M, r, GridLevels, PerturbationSteps, Trials, Depth)
% SAMPLE = UQ_MORRIS_BEST_DESIGN(M,R,GL,PS,NT,DEPTH): create a set of R
%     Morris' sampling trajectories as a function of the input dimension M,
%     grid levels GL, number of perturbation steps PS. The set is chosen as
%     the most space filling one out of NT trials, with a maximin distance
%     criterion based on DEPTH nearest neighbors.
%
% See also: UQ_CREATE_MORRIS_TRAJECTORY

if nargin < 6
    Depth = min(r, 3);
end

XBase = round(rand(M,r)*(GridLevels - PerturbationSteps - 1));
Sample = XBase;

% If there is only one point on the grid, there is nothing to do:
if r == 1
    return
end

AllScores = zeros(1, Depth);
CurrentBestScores = zeros(1, Depth);

for ii = 1:Trials
    
    % knnsearch works with the transpose of the sample:
    CompX = transpose(XBase);
    
    % Search the nearest neighbor distances:
    [~, NearestDist] = ...
        knnsearch(CompX, CompX, 'k', Depth + 1, 'distance', 'cityblock');
    
    for jj = 1:Depth
        ThisScore = min(NearestDist(:,jj + 1));
        if ThisScore >= AllScores(jj);
            BetterDesign = true;
            CurrentBestScores(jj) = ThisScore;
        else
            BetterDesign = false;
            break;
        end
    end
        if BetterDesign
            AllScores = CurrentBestScores;
            Sample = XBase;
        end
        XBase = round(rand(M,r)*(GridLevels - PerturbationSteps - 1));
end