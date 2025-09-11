function newInput = uq_extractInputs(myInput, idx, varargin)
% newInput = uq_extractInputs(myInput, idx)
%     Extracts the marginals specified by idx from myInput. The resulting 
%     newInput has the marginals of myInput given in idx. Does not
%     currently support dependence.
%
% INPUT:
% myInput: uq_input objects
%     the first argument is an input object.
% idx: index vector of the marginals that are to be extracted
% isprivate : bool, optional
%     Whether the input should be created as a private uqlab object.
%     Default: false.
%
% OUTPUT:
% newInput: uq_input
%    the merged Input object
%
% EXAMPLES:
%  >> newInput = uq_mergeInputs(myInput, [1 3]) 
%     Extracts the marginals 1 and 3 from myInput.

% Check whether private flag was provided
if nargin > 2 && strcmpi(varargin{end}, '-private')
    % privateflag true
    isprivate = true;
    % remove flag from input
    varargin = varargin(1:end-1);
else
    isprivate = false;
end

% Check inputs
assert(isa(myInput, 'uq_input'), 'Provide a uq_input object as the first argument')
assert(isnumeric(idx), 'Provide a uq_input object as the first argument')

% make sure that input is independent
for ii = 1:length(myInput.Copula)
    if ~strcmpi(myInput.Copula(ii).Type,'independent')
        error('Only independent copulas supported at the moment')
        % ToDo: Add support for dependent copulas (at least Gaussians)
    end
end

%% Extract input objects
for ii = 1:length(idx)
    dd = idx(ii);
    iOpts.Marginals(ii) = rmfield(myInput.Marginals(dd),'Moments');
end

% Create the merged input object
if isprivate
    newInput = uq_createInput(iOpts,'-private');
else
    newInput = uq_createInput(iOpts);
end
