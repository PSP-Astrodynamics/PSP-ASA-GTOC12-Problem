function [AllTraj, AllSigns, DerIdx] = uq_create_morris_trajectory(M, r, Options)
% [AllTraj, AllSigns, DerIdx] = UQ_CREATE_MORRIS_TRAJECTORY(M,R,OPTIONS):
%     generate R Morris' random trajectories in dimension M, given the
%     options specified in OPTIONS.
%
% See also: UQ_MORRIS_INDICES


% Create a random sample with the starting points of the trajectories,
% trying to make it cover the entire grid as best as possible:
range = Options.Morris.GridLevels - Options.Morris.PerturbationSteps - 1;
% XBase = round(rand(r, M)*range);
XBase = randi([min(0,range),max(0,range)],r,M);

% The total cost of the method is r*(M + 1):
AllTraj = zeros(r*(M + 1), M);
AllSigns = zeros(r, M);

% Some matrix definitions to keep consistent with the notation of Morris (1991)
B = [zeros(1,M) ; zeros(M) + tril(ones(M))];
J =  ones(M + 1, M);
DerIdx = zeros(r, M);
Identitiy_M = eye(M);
for ii = 1:r
    % Select a starting point from the generated sample:
    X = XBase(ii, :);
    
    % Create the diagonal matrix D, starting from a vector:
    Signs = 2*round(rand(1,M)) - 1;
    D = diag(Signs);
    
    % Create P as a permutation of the columns of the identity matrix:
    P = Identitiy_M(:,randperm(M));
    
    % Make the random changes in B:
    Trajectory = (ones(M + 1,1)*X + Options.Morris.PerturbationSteps*(1/2)*((2*B - J)*D + J))*P;
    
    % The variables are randomly permuted. Retrieve the order
    % to be able to set the derivatives appropriately
    TempDerIdx = mod(find(P'),M);
    TempDerIdx(TempDerIdx == 0) = M;
    [~, TempDerIdx] = sort(TempDerIdx);
    DerIdx(ii,:) = TempDerIdx';
    
    % Assign the outputs
    AllTraj((ii - 1)*(M + 1) + 1 : ii*(M + 1), :) = Trajectory;
    AllSigns(ii, :) = Signs;
end


