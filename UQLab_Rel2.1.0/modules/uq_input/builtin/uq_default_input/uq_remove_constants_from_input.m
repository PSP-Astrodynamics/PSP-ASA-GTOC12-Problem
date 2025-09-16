function [newInput, oldIDs, constInput, idConst] = ...
    uq_remove_constants_from_input(varargin)
% [newInput, oldIDs, constInput, oldIDsConst] = ...
%         uq_remove_constants_from_input(Input, isprivate)
%    Creates a copy of an UQLab input model stripped of the constant variables.
%    The new input can be optionally specified to be private.
%
%    Additionally, the function can return a second input object comprising all
%    constant marginals of the original input.
%
% INPUT:
% Input : uqlab input object
%     A copy of the given input without constant marginals.
% isprivate: bool, optional
%     Whether the input should be private.
%     Default: false
%
% OUTPUT :
% newInput: uqlab input object
%    the input without constant variables
% oldIDs : array of integers
%    the IDs of the non-constant variables in the original input. In the
%    example above, the array [1 3];
% constInput: uqlab input object or []
%    an input among the constant variables of the original inputs only,
%    coupled by the independence copula. (or [] is no constants existed).
% oldConstIDs : array of integers
%    the IDs of the non-constant variables in the original input. In the
%    example above, the array [1 3].

% check if private flag was provided
if strcmpi(varargin{end},'-private')
    % privateflag true
    isprivate = true;
else
    % privateflag false
    isprivate = false;
end

Input = varargin{1};
Marginals = Input.Marginals;
Copula = Input.Copula;

% Distinguish the constant and non-constant input variables
isNonConst = ~ismember(lower({Marginals.Type}),{'constant'});
idNonConst = find(isNonConst);
idConst = find(~isNonConst);
constInput = [];

if isempty(idConst)
    newInput = Input;
    oldIDs = 1:length(Marginals);
else
    oldIDs = [];
    newOpts = struct;
    nrCopulas = 0;
    nrMargs = 0;
    for cc = 1:length(Copula)
        Cop = Copula(cc);
        Vars = Cop.Variables;

        % Determine the random (i.e. non constant) variables coupled by copula
        % Cop
        if any(ismember(Vars, idConst))
            if uq_isIndependenceCopula(Cop)
                RandVars = intersect(Vars, idNonConst);
                % Assign random marginals and copula to the input options
                % of the new input
                if ~isempty(RandVars)
                    K = length(RandVars);
                    for kk = 1:K
                        rv = RandVars(kk);
                        oldIDs = [oldIDs, rv];
                        newOpts.Marginals(nrMargs+kk).Type = ...
                            Marginals(rv).Type;
                        newOpts.Marginals(nrMargs+kk).Parameters = ...
                            Marginals(rv).Parameters;
                        if isfield(Marginals(rv), 'Name')
                            newOpts.Marginals(nrMargs+kk).Name = ...
                                Marginals(rv).Name;
                        end
                        if isfield(Marginals(rv), 'Bounds')
                            newOpts.Marginals(nrMargs+kk).Bounds= Marginals(rv).Bounds;
                        end
                    end
                    newOpts.Copula(nrCopulas+1).Type = 'Independent';
                    newOpts.Copula(nrCopulas+1).Parameters = eye(K);
                    newOpts.Copula(nrCopulas+1).Variables = nrMargs+1:nrMargs+K;
                    nrMargs = nrMargs+K;
                    nrCopulas = nrCopulas+1;
                end
            else
                error('constant variables coupled by a non-constant copula!')
            end
        else
            RandVars = Vars;
            K = length(RandVars);
            for kk = 1:K
                rv = RandVars(kk);
                oldIDs = [oldIDs, rv];
                newOpts.Marginals(nrMargs+kk).Type = Marginals(rv).Type;
                newOpts.Marginals(nrMargs+kk).Parameters = Marginals(rv).Parameters;
                if isfield(Marginals(rv), 'Name')
                    newOpts.Marginals(nrMargs+kk).Name = Marginals(rv).Name;
                end
                if isfield(Marginals(rv), 'Bounds')
                    newOpts.Marginals(nrMargs+kk).Bounds= Marginals(rv).Bounds;
                end
            end
            % If the copulais Gaussian, empty the Parameters option as it cannot be
            % given at the same time as RankCorr to build a new Input
            for jj = 1:length(Cop)
                if strcmpi(Cop(jj).Type,'gaussian')
                    if isfield(Cop,'RankCorr') && ~isempty(Cop.RankCorr)
                        current_copula(jj).Parameters = [] ;
                    end
                    Cop(jj).Parameters = [] ;
                end
            end
            newOpts = uq_add_copula(newOpts, Cop);
            newOpts.Copula(end).Variables = nrMargs+1:nrMargs+K;
            nrMargs = nrMargs+K;
            nrCopulas = nrCopulas+1;
        end
    end

    % create input object
    if isprivate
        newInput = uq_createInput(newOpts,'-private');
    else
        newInput = uq_createInput(newOpts);
    end

    % create constant Input object, if requested
    if nargout > 2
        if ~isempty(idConst)
            constOpts.Marginals = rmfield(Input.Marginals(idConst),'Moments');
            constOpts.Copula = uq_IndepCopula(length(idConst));
            if isprivate
                constInput = uq_createInput(constOpts,'-private');
            else
                constInput = uq_createInput(constOpts);
            end
        end
    end
end
