function [PairCopulas, Indices, Pairs, CondVars] = ...
    uq_PairCopulasInVine(Copula, pairs)
% [PairCopulas, Indices, Pairs, CondVars] = ...
%    UQ_PAIRCOPULASINVINE(Copula, Vars)
%     Produces a list (cell) of pair copulas reconstructed from the given 
%     vine copula. Also returns their index in the vine, the pairs of 
%     r.v.s they couple, and the associated conditioning r.v.s.
%
% INPUT: 
% Copula:
%     a structure describing a vine copula (see UQLab's Input manual)
% (Vars: array k-by-2, or cell of 1-by-2 arrays; optional)
%     Pairs of r.v.s whose pair copula should be returned.
%     Default: all pairs of variables in the vine
%
% OUTPUT:
% PairCopulas: cell
%    a cell of structures, each describing one pair copula in the vine.
% Indices : array of integers
%    an array of indices of each pair copula in the vine. If input Vars is
%    not specified, Indices = 1:M*(M-1)/2, where M is the vine dimension
% Pairs : cell
%    Pairs{kk} is the array [ii,jj] of r.v.s coupled by PairCopulas{kk}.
%    Pairs is equivalent to input argument Vars if the latter is provided
% CondVars : cell
%    CondVars{kk} is the array of conditioning variables of PairCopulas{kk}

% Assign default Vars, or restructure it as a k-by-2 array
[AllPairs, AllCondVars] = uq_vine_copula_edges(Copula);
if nargin == 1, pairs = AllPairs; end

% Transform pairs into a cell Pairs, if it was an array
if isa(pairs, 'double') 
    if size(pairs, 2) ~= 2
        error('As an array, input argument Vars must have 2 columns')
    else
        VarsArray = pairs;
        Pairs = {}; 
        for ii = 1:size(pairs, 1), Pairs{ii} = pairs(ii, :); end
    end
elseif isa(pairs, 'cell')
    Pairs = pairs;
    VarsArray = [];
    for ii = 1:length(pairs), VarsArray(ii,1:2) = pairs{ii}; end
else
    error('Input argumant Vars must be either a cell or a k-by-2 array')
end

% Determine total number of pair copulas and of non-truncated PCs
Nr_Pairs = length(Pairs);
if uq_isnonemptyfield(Copula, 'Truncation')
    M = length(Copula.Structure);
    Nr_Pairs_NoTrunc = sum(M-(1:Copula.Truncation));
else
    Nr_Pairs_NoTrunc = Nr_Pairs;
end

% If the copula is truncated, complete it with independence pair copulas
for kk = Nr_Pairs_NoTrunc+1 : Nr_Pairs
    Copula.Families{kk} = 'Independent';
    Copula.Rotations(kk) = 0;
    Copula.Parameters{kk} = [];
end

PairCopulas = {};
Indices = zeros(1, Nr_Pairs);

AllPairsArray = reshape([AllPairs{:}], 2, [])'; 
Nr_AllPairs = size(AllPairsArray, 1);

% Check that no wrong ids are present in the specified Vars
WrongVars = setdiff(unique(VarsArray), unique(AllPairsArray(:)));
if not(isempty(WrongVars))
    errmsg = 'Input argument Vars contains one or more ids not present';
    error('%s in the specified vine', errmsg);
end

for kk = 1:Nr_Pairs
    Pair = Pairs{kk};
    PairRep = repmat(Pair, Nr_AllPairs, 1);
    PCidx = find(all(AllPairsArray == PairRep, 2));
    if isempty(PCidx)
        errmsg = 'The specified vine contains no pair copula between ';
        error('%s variables [%d, %d]. Try [%d, %d]?', errmsg, ...
            Pair(1), Pair(2), Pair(2), Pair(1))
    end
    fam = Copula.Families{kk};
    rot = Copula.Rotations(kk);
    par = Copula.Parameters{kk};
    PairCopulas{kk} = uq_PairCopula(fam, par, rot);
    Indices(kk) = PCidx;
    CondVars{kk} = AllCondVars{PCidx};
end
