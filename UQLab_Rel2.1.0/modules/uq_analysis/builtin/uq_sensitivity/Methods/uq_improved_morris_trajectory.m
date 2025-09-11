function [AllTraj, AllSigns, DerIdx] = uq_improved_morris_trajectory(M, r, R, Options)
% [ALLTRAJ, ALLSIGNS, DERIDX] = UQ_IMPROVED_MORRIS_TRAJECTORY(M, r, R, OPTIONS):
%      generate R improved morris trajectories according to the options in
%      OPTIONS.
%
% See also: UQ_CREATE_MORRIS_TRAJECTORY,UQ_MORRIS

% Create standard trajectories
[AllTraj, AllSigns, DerIdx] = uq_create_morris_trajectory(M, R, Options);

% Reshape the outputs to 3d matrices:
AllTraj = reshape(AllTraj, M, M+1, R);

% Possible combinations of trajectories:
PossibleTrajs = nchoosek(1:R, r);

% Number of possible trajectories:
NPTrajs = size(PossibleTrajs, 1);

% Initialize the scores of each trajectory (sum of the distances with the
% others)
Scores = zeros(NPTrajs, 1);

% All the combinations between trajectories that we must check:
InnerCombinations = nchoosek(1:r, 2);

% Number of combinations:
NCombs = size(InnerCombinations, 1);

% Prepare an auxiliar matrix that will speed up the norm computation:
OnesVec = ones(1, (M+1)^2);
AuxVec = OnesVec;
for ii = 2:M + 1
    AuxVec((M+1)*(ii - 1) + 1:(M+1)*ii) = ii;
end
AuxMat = sparse(AuxVec, 1:(M+1)^2, OnesVec); 

for tr = 1:NPTrajs
    for ii = 1 : NCombs
        id1 = InnerCombinations(ii, 1);
        id2 = InnerCombinations(ii, 2);

        Norm = ...
            sum(sum((AllTraj(:, :, PossibleTrajs(tr, id1))*AuxMat - ...
            repmat(AllTraj(:, :, PossibleTrajs(tr, id2)), 1, M + 1)).^2));
        
        % Increase the score of this trajectory:
        Scores(tr) = Scores(tr) + Norm^2;      
    end
    Scores(tr) = sqrt(Scores(tr));
end
% Select the r trajectories with maximum distances:
[~, MaxDis] = sort(Scores, 'descend');

% Get rid of the other values:
AllTraj = AllTraj(:, :, PossibleTrajs(MaxDis(1), :));
AllSigns = AllSigns(PossibleTrajs(MaxDis(1), :), :);
DerIdx = DerIdx(PossibleTrajs(MaxDis(1), :), :);

% Reshape back to 2d matrices:
AllTraj = reshape(AllTraj, M, r*(M+1));


