function newInput = uq_mergeInputs(varargin)
% newInput = uq_mergeInputs(varargin)
%     Merge any number of uq_input objects, each representing a random vector,
%     into a single input. The resulting input has all the marginals of the
%     original inputs, and its copula is the tensor product of the original
%     copulas (that is, the original inputs are mutually independent).
%
% INPUT:
% Input1, ..., InputK: uq_input objects
%     the first K arguments are Input objects, for any K>=2.
% Vars1, Vars2,...,VarsK : arrays of float, optional
%     the next K arguments, if provided, are the IDs of each input's
%     marginals into the merged Input. For instance, if Input1 has
%     dimension 2 and Input2 has dimension 3, the command:
%             newInput = uq_mergeInputs(Input1, Input2, [2,3], [1,4,5])
%     assigns the marginals of Input1 to the marginals 2 and 3 of newInput,
%     and the marginals of Input2 to the marginals 1, 4 and 5 of newInput.
%     Default: the marginals are appended in order, from Input1 to InputK.
% isprivate : bool, optional
%     Whether the input should be created as a private uqlab object.
%     Default: false.
%
% OUTPUT:
% newInput: uq_input
%    the merged Input object
%
% EXAMPLES:
%  >> newInput = uq_mergeInputs(Input1, Input2, Input3)
%     Merges 3 inputs. Their marginals are appended one after the other.
%  >> newInput = uq_mergeInputs(Input1, ..., InputK, Vars1, ..., VarsK)
%     Makes the marginals of input J the VarsJ marginals of newInput.
%  >> newInput = uq_mergeInputs(Input1, Input2, ..., '-private')
%     Makes newInput a private uq_input object

% Check whether private flag was provided
if strcmpi(varargin{end}, '-private')
    % privateflag true
    isprivate = true;
    % remove flag from input
    varargin = varargin(1:end-1);
else
    isprivate = false;
end

newIDs = {};
% Iteratively remove all input arguments that are not uq_inputs from
% varargin, and add them to newIDs. After this, varargin contains only
% uq_inputs.
while ~isa(varargin{end}, 'uq_input')
    newIDs = [varargin{end}, newIDs];
    varargin = varargin(1:end-1);
end

Nin = length(varargin); % Number of inputs
assert(Nin >= 2, 'Provide at least two Inputs to merge')

% If newIDs is empty, it means that optional newIDs were not given. Assign
% defaults
if isempty(newIDs)
    cumul_dim = 0;
    for ii = 1:Nin
        nrVars_ii = length([varargin{ii}.Copula.Variables]);
        newIDs = [newIDs, (1:nrVars_ii)+cumul_dim];
        cumul_dim = cumul_dim + nrVars_ii;
    end
end

% Check input length
% Check that as many inputs as variable IDs have been provided
if Nin ~= length(newIDs)
    error('%d Inputs provided to merge, but %d arrays of their variable IDs',...
        Nin, length(newIDs))
end

% Combine input objects
newMarginals = [];
newCopula = [];
for ii = 1:Nin
    current_input = varargin{ii};
    new_ids = newIDs{ii};
    assert(isa(current_input, 'uq_input'))
    current_marginals = current_input.Marginals;
    current_marginals = rmfield(current_marginals, 'Moments');
    current_copula = current_input.Copula;
    % If the copulais Gaussian, empty the Parameters option as it cannot be
    % given at the same time as RankCorr to build a new Input
    for jj = 1:length(current_copula)
        if strcmpi(current_copula(jj).Type,'gaussian')
            if isfield(current_copula(jj),'RankCorr') && ~isempty(current_copula(jj).RankCorr)
                current_copula(jj).Parameters = [] ;
            end
        end
    end
    current_copula = uq_complete_copula(current_copula);
    for cc = 1:length(current_copula)
        current_copula(cc).Variables = new_ids(current_copula(cc).Variables);
    end

    % concatenate the marginals (may have different fields, ues uq_concStructs)
    newMarginals = uq_concStructs(newMarginals, current_marginals);

    % concatenate Copula struct (same)
    newCopula = uq_concStructs(newCopula, current_copula);
end

iOpts = struct;
iOpts.Marginals = newMarginals;
iOpts.Copula = newCopula;

% Create the merged input object
if isprivate
    newInput = uq_createInput(iOpts,'-private');
else
    newInput = uq_createInput(iOpts);
end
