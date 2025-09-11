function Copula = uq_VineCopula(...
    type, structure, families, parameters, rotations, truncation, verbose)
% Copula = UQ_VINECOPULA(...
%         type, structure, families, thetas, rotations, truncation)
%     Conveniency function to create a data structure that represents an 
%     M-variate vine copula. 
%
% INPUT: 
% type : char
%     either 'CVine' or 'DVine';
% structure : array of M integers from 1 to M (in any order)
%     vine copula structure. It determines, together with the vine type,
%     the pair copulas that enter the vine construction. These can be
%     summarized by uq_CopulaSummary(type, structure)
% families: cell of M*(M-1)/2 chars 
%     the pair copula families (one per pair of random variables). 
% parameters : cell of M*(M-1)/2 arrays
%     parameters of each pair copula; each element is an array of doubles
% (rotations: array of M*(M-1)/2 elements, optional)
%     the rotation of each pair copula density (0, 90, 180, or 270).
%     Default: array of zeros (no rotation; equivalently: []).
% (truncation: integer, optional)
%     Vine copula truncation level. Truncation T sets all conditional pair 
%     copulas with >T conditioning variables to the independence copula: 
%     * 0: all pair copulas are independent; warning raised
%     * 1: the vine has only one tree (unconditional pair copulas)
%     * 2+: the vine has only pair copulas up to conditioning order equal
%       to the truncation level 
%     * M-1 or more: no truncation
%     Default: M (no truncation).
% (verbose: float, optional)
%     If non-zero, warnings are printed when needed.
%     Default: 1
%
% OUTPUT:
% Copula : struct
%     Structure that describes the specified vine copula. 
%
% NOTES: If only one copula family is provided, a structure describing a  
% pair copula is created (see uq_PairCopula).
%
% EXAMPLES:
% >> type = 'CVine'; families = {10, 11, 0}; thetas = {0.2, 1.5, []};
% >> uq_VineCopula(type, families, thetas)
% >> rotations = [0 180 0];
% >> uq_VineCopula(type, families, thetas, rotations)
%
% SEE ALSO: uq_PairCopula, uq_GaussianCopula

M = length(structure);
Nr_Families = length(families);

% Convert family names to standard ones (e.g. "Normal" to "Gaussian")
for ff = 1:Nr_Families
    families{ff} = uq_copula_stdname(families{ff});
end

% Assign defaults
if nargin <= 4 || isempty(rotations), rotations = zeros(1, Nr_Families); end
if nargin <= 5, truncation = M; end
if nargin <= 6, verbose = 1; end

% Make some checks for the arguments
if ~isa(parameters, 'cell')
    error('Parameters thetas must be a cell of parameter arrays')
end

if ~isa(families, 'cell')
    error('Input argument families must be a cell of chars')
end

if truncation == 0 && verbose
        msg = 'vine truncation 0 (all pair copulas independent)';
        warning('%s requested. Independent copula will be returned', msg)
elseif truncation > M
    if verbose
        msg = sprintf('vine truncation %d out of range [0 %d]', truncation, M);
        warning('%s. Set to %d (no truncation) instead', msg, M)
    end
    truncation = M;
elseif truncation < 0
    error('negative vine truncation level provided. Specify an integer between 0 and M')
end

Nr_Pairs_Total = M*(M-1)/2;
Nr_Pairs_NoTrunc = sum(M-(1:truncation));
Nr_ParamArrays = length(parameters);
Nr_Rotations = length(rotations);

% Check that the number of parameter arrays provided is M*(M-1)/2
if Nr_ParamArrays ~= Nr_Families
    msg1 = 'length of input argument thetas';
    msg2 = 'inconsistent with number of pair copula families specified';
    error('%s (%d) %s (%d).\n', msg1, Nr_ParamArrays, msg2, Nr_Families);
end

% Check that the number of rotation values provided is M*(M-1)/2
if Nr_Rotations ~= Nr_Families
    msg1 = 'length of input argument rotations';
    msg2 = 'inconsistent with number of pair copula families specified';
    error('%s (%d) %s (%d).\n', msg1, Nr_Rotations, msg2, Nr_Families);
end

% Check that the number of pair copulas provided is Nr_Pairs_NoTrunc.
% If larger but <=Nr_Pairs_Total, raise warning and ignore the additional 
% ones. If >Nr_Pairs_Total, raise error
if Nr_Families > Nr_Pairs_Total || Nr_Families < Nr_Pairs_NoTrunc
    error('%d pair copula families provided, but %d needed', ...
        Nr_Families, Nr_Pairs_NoTrunc)
elseif Nr_Families > Nr_Pairs_NoTrunc && verbose && ...
        ~all(strcmpi(families(Nr_Pairs_NoTrunc+1:end), 'Independent'))
    msg1 = '%d pair copula families provided, but with the';
    msg2 = ' specified truncation\nonly the first %d families are needed.';
    msg3 = ' The rest will be ignored';
    warning([msg1 msg2 msg3], Nr_Families, Nr_Pairs_NoTrunc);
end

% Set the families from Nr_Pairs_NoTrunc+1 to Nr_Pairs_Total to
% 'Independent', the corresponding parameters to [], the rotations to 0
families = families(1:Nr_Pairs_NoTrunc);
parameters = parameters(1:Nr_Pairs_NoTrunc);
rotations = rotations(1:Nr_Pairs_NoTrunc);
for pc = Nr_Pairs_NoTrunc+1:Nr_Pairs_Total
    families{pc} = 'Independent';
    rotations(pc) = 0;
    parameters{pc} = [];
end

% Create the structure Copula
if M == 2 % Either as a PairCopula, if M = 2
    if isa(families, 'cell'), 
        family = families{1};
    else
        family = families(1);
    end
    Copula = uq_PairCopula(family, parameters{1}, rotations(1));
else      % Or as a VineCopula, if M > 2
    for ii = 1:Nr_Pairs_Total
        family = families{ii};
        theta = parameters{ii};
        uq_check_pair_copula_family_supported(family);
        uq_check_pair_copula_parameters(family, theta);
    end

    Copula = uq_copula_skeleton();
    Copula.Type = type;
    Copula.Dimension = M;
    Copula.Families = families; 
    Copula.Parameters = parameters;
    Copula.Rotations = rotations;
    Copula.Structure = structure;
    Copula.Truncation = truncation;
    [Pairs, CondVars, Trees] = uq_vine_copula_edges(Copula);
    Copula.Pairs = Pairs;
    Copula.CondVars = CondVars;
    Copula.Trees = Trees;
end
