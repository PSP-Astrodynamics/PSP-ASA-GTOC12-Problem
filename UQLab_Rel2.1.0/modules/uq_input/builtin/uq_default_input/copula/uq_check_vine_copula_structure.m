function uq_check_vine_copula_structure(S)
% UQ_CHECK_VINE_COPULA_STRUCTURE(S)
%     Raises an error if the specified vine copula structure S is not 
%     an array 1:M, or any permutation of it.
%
% INPUT:
% S : array
%     The vine copula structure. Must be any permutation of an array
%     of the type 1:M, where M is the desired vine dimension
%
% OUTPUT:
% none

M = length(S);
if not(isa(S, 'double')) || M <= 1
    error('structure must be an array with M>=2 elements')
end

S_unique = unique(S);
if length(S_unique) < M
    error('structure contains repeated elements.')
elseif not(isempty(setdiff(S_unique, 1:M)))
    msg1 = 'A structure of length';
    msg2 = 'must be any permutation of the array';
    error('%s %d %s 1:%d', msg1, M, msg2, M)
end
