function [Pairs, CondVars, Trees] = uq_vine_copula_edges(Copula, varargin)
% [Pairs, CondVars, Trees] = UQ_VINE_COPULA_EDGES(Vine), OR
% [Pairs, CondVars, Trees] = UQ_VINE_COPULA_EDGES(VineType, Structure)
%     Returns the pairs of variable ids linked by a pair copula in the 
%     specified vine copula (or simply vine copula structure), the 
%     corresponding conditioning variables, and the vine tree which each 
%     pair copula in the graphical representation belongs to.
%
%     For instance, a CVine with structure [2 4 1 3] has pair copulas 
%     C_{2,4}, C_{2,1}, C_{2,3}, C_{4,1|2}, C_{4,3|2}, C_{1,3|2,4}. Thus:
%         * Pairs    = {[2 4], [2 1], [2 3], [4 1], [4 3], [1 3]},
%         * CondVars = {[],    [],    [],    [2],   [2],   [2 4]},
%         * Trees = [1, 1, 1, 2, 2, 3].
%     Instead, a DVine with same structure [2 4 1 3] has pair copulas 
%     C_{2,4}, C_{4,1}, C_{1,3}, C_{2,1|4}, C_{4,3|1}, C_{2,3|4,1}. Thus:
%         * Pairs    = {[2 4], [4 1], [1 3], [2 1], [4 3], [2 3]},
%         * CondVars = {[],    [],    [],    [4],   [1],   [4 1]},
%         * Trees = [1, 1, 1, 2, 2, 3].
%
% INPUT:
% Vine : struct
%     A structure describing a vine copula (see uq_VineCopula)
% *OR*
% VineType: char 
%     array containing the vine's type (e.g., 'CVine')
% Structure: array
%     the vine structure (order of its variables)
%
% OUTPUT:
% Pairs : cell of M*(M-1)/2 arrays 
%     Pairs{kk} contains the ids of the two (possibly conditional) 
%     variables coupled by a pair copula in the given vine representation.
% CondVars : cell of M*(M-1)/2 arrays 
%     CondVars{kk} contains the ids of the conditioning variables associated
%     to Pairs{kk}, if any
% Trees : array 1-by-M*(M-1)/2
%     The tree each pair copula in the specified representation belongs to.

if isempty(varargin)
    type = Copula.Type;
    structure = Copula.Structure;
else
    type = Copula;
    structure = varargin{1};
end

uq_check_vine_copula_structure(structure);

M = length(structure);
Nr_Pairs = M*(M-1)/2;
Pairs = cell(1,Nr_Pairs); 
CondVars = cell(1,Nr_Pairs); 
Trees = zeros(1, Nr_Pairs);

if strcmpi(type, 'CVine')
    kk = 0;
    for ii = 1:M-1 % tree level
        for jj = ii+1:M
            kk = kk+1;
            Pairs{kk} = structure([ii, jj]);
            if ii >= 2, CondVars{kk} = structure(1:ii-1); end
            Trees(kk) = ii;
        end
    end
elseif strcmpi(type, 'DVine')
    kk = 0;
    for jj = 1:M-1  % tree level
        for ii = 1:M-jj 
            kk = kk+1;
            Pairs{kk} = structure([ii, jj+ii]);
            if jj >= 2, CondVars{kk} = structure(ii+1:ii+jj-1); end
            Trees(kk) = jj;
        end
    end
end


