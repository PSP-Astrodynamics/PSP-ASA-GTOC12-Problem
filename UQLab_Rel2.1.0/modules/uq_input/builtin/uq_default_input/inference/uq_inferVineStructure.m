function [S, SumTauK] = uq_inferVineStructure(U, VineType)
% [S, K] = uq_inferVineStructure(U, VineType)
%     Given multivariate data U in a matrix, where each column stores
%     observations from one variable, finds the optimal structure of a C- 
%     or D-Vine to be fitted on the data, based on maximum Kendall's tau 
%     heuristic criterion.
%
% INPUT: 
% U : array of size n by M
%     n observations of an M-dimensional random vector
%
% OUTPUT:
% S : array of size 1 by M
%     optimal vine structure, i.e order of the variables in X, that 
%     minimize the sum of Kendall's tau between successive variables.
% K : float
%     sum of Kendall's taus for the optimal vine structure

% uq_check_data_in_unit_hypercube(U);
[n, M] = size(U);

AbsTauK = abs(corr(U, 'type', 'Kendall')) - eye(M);

if strcmpi(VineType, 'CVine')
    SumTauK = sum(AbsTauK, 1);
    [~, S] = sort(SumTauK, 2, 'descend');
elseif strcmpi(VineType, 'DVine')
    config = struct('dmat', -AbsTauK, 'fixed', false);
    resultStruct = uq_open_travelling_salesman_problem(config);
    S = resultStruct.bestPath;       % lower node IDs by 1 (the fictional start node)
    SumTauK = -resultStruct.minDist;   % invert sign again
else 
    error('Vine type "%s" not supported or not known', VineType)
end
