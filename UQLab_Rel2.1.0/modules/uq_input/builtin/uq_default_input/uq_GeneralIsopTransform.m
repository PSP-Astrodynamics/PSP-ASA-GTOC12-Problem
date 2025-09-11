function Y = uq_GeneralIsopTransform(X, X_Marginals, X_Copula, Y_Marginals, Y_Copula)
% Y = UQ_GENERALISOPTRANSFORM(X, X_Marginals, X_Copula, Y_Marginals, Y_Copula):
%     Maps a set X of samples from a random vector with an arbitrary 
%     distribution to a sample Y in another probability space. Both spaces  
%     need to be specified via the Marginals and Copula formalism, as 
%     described in the UQLab Input module user manual.
%
%     Note: non-constant marginal distributions can be transformed into
%     constant ones, but the converse is not true and will raise an error.
%     Constants can be mapped to different constants though.
%
% See also:  UQ_INVNATAFTRANSFORM, UQ_ROSENBLATTTRANSFORM, UQ_ISOPTRANSFORM

if any(isnan(X(:)))
    error('Requested Generalized probabilistic transformation for array X containing nans.')
end

[n, M] = size(X);
if M~=length(X_Marginals)
    error('The input dimension is inconsistent with the data.')
end
if M~=length(Y_Marginals)
    error('The input dimension do not match the output dimension.')
end

% Identify XX, the sub-vectors of X containing the non-constant variables only, 
% and define the non-constant marginals of X and Y and their copula
idNonConst_X = uq_find_nonconstant_marginals(X_Marginals);
idNonConst_Y = uq_find_nonconstant_marginals(Y_Marginals);
idConst_X = setdiff(1:M, idNonConst_X);
idConst_Y = setdiff(1:M, idNonConst_Y);

% Raise error if constants should be mapped to non-constants
idConst_XnotY = setdiff(idConst_X, idConst_Y);
if ~isempty(idConst_XnotY)
    msg = 'Constant marginal X_i cannot be mapped to non-constant marginal Y_i';
    error('%s, i=%s', msg, mat2str(idConst_XnotY))
end
    
% Initialize Y
Y = nan(n, M);

% Transform constant marginals to new constants
for ii = idConst_Y
    Y(:,ii) = Y_Marginals(ii).Parameters;
end

% If all variables are constant, coupled by a copula other than the 
% independence copula, raise error
if length(idConst_X) == M && length(idConst_Y) == M
    msg='Requested isoprobabilistic transformation between constant variables';
    if ~uq_isIndependenceCopula(X_Copula)
        error('%s X coupled by non-independence copula', msg)
    end
    if ~uq_isIndependenceCopula(Y_Copula)
        error('%s Y coupled by non-independence copula', msg)
    end
end

% Assign X_Copula and Y_Copula the field .Variables, if not existing yet
% and if they have length 1
if length(X_Copula) == 1 && ~uq_isnonemptyfield(X_Copula, 'Variables')
    X_Copula.Variables = 1:M;
end
if length(Y_Copula) == 1 && ~uq_isnonemptyfield(Y_Copula, 'Variables')
    Y_Copula.Variables = 1:M;
end

% pre-define flag to exercute block-wise transform
success = true;
icop = length(Y_Copula)+1;

% Perform the transform
for cc = 1:length(X_Copula)
    CopX = X_Copula(cc);
    VarsX = CopX.Variables;
    % If some variables couples by Cop are constant, take them out; also
    % raise errors if they were coupled by non-independence copula
    if any(ismember(VarsX, idConst_X))
        if uq_isIndependenceCopula(CopX)
            VarsX = VarsX(ismember(VarsX, idNonConst_X)); % take non-constant only
            CopX = uq_IndepCopula(length(VarsX)); % redefine Cop in lower dim
            CopX.Variables = 1:length(VarsX);
        else
            error('X variables %s are constant but coupled by %s copula', ...
                mat2str(VarsX), CopX.Type)
        end
    end
    
    
    % if the previous blockwise transforms succeed, continue in this
    % direction
    if success && cc<=length(Y_Copula)
        CopY = Y_Copula(cc);
        VarsY = CopY.Variables;
        % If some variables coupled by Cop are constant, take them out; also
        % raise errors if they were coupled by non-independence copula
        if any(ismember(VarsY, idConst_Y))
            if uq_isIndependenceCopula(CopY)
                VarsY = VarsY(ismember(VarsY, idNonConst_Y));
                CopY = uq_IndepCopula(length(VarsY)); % redefine Cop in lower dim
                CopY.Variables = 1:length(VarsY);
            else
                error('Constant variables Y_%s cannot be coupled by %s copula', ...
                    mat2str(VarsY), CopY.Type)
            end
        end
        % Check if the x copula and y copula contain the same number of variables
        if length(VarsX)==length(VarsY)
            % if the variables are defined in the same order or both
            % copulas are independent involving the same variables, we
            % perform a blockwise transform.
            if sum(abs(VarsX-VarsY))==0 || ...
                    (uq_isIndependenceCopula(CopX)&&uq_isIndependenceCopula(CopY)&&isempty(setdiff(VarsX,VarsY)))
                if ~isempty(VarsX)
                    CopX.Variables = 1:length(VarsX);
                    CopY.Variables = 1:length(VarsY);
                    [Y(:,VarsX),success] = uq_BlockGeneralIsopTransform(X(:, VarsX), X_Marginals(VarsX), CopX, Y_Marginals(VarsX), CopY);
                end
            else
                success = false;
            end
        else
            success = false;
        end
        % Record the copula index from which we we need to run the
        % Rosenblatt transform
        if ~success
            icop = cc;
        end
    end
    % if the blockwise transform fails: VarsX and VarsY contains different
    % elements or the structure does not allow for an efficient
    % transform, we perform the Rosenblatt transform instead
    if ~success && ~isempty(VarsX)
        Y(:, VarsX) = uq_RosenblattTransform(X(:, VarsX), X_Marginals(VarsX), CopX);
    end
end

% Perform the inverse Roseblatt transform for the variables in Y that 
% were not successfully transformed by the blockwise transform
for cc = icop:length(Y_Copula)
    CopY = Y_Copula(cc);
    VarsY = CopY.Variables;
    % If some variables coupled by Cop are constant, take them out; also
    % raise errors if they were coupled by non-independence copula
    if any(ismember(VarsY, idConst_Y))
        if uq_isIndependenceCopula(CopY)
            VarsY = VarsY(ismember(VarsY, idNonConst_Y));
            CopY = uq_IndepCopula(length(VarsY)); % redefine Cop in lower dim
            CopY.Variables = 1:length(VarsY);
        else
            error('Constant variables Y_%s cannot be coupled by %s copula', ...
                mat2str(VarsY), CopY.Type)
        end
    end
    if ~isempty(VarsY)
        Y(:, VarsY) = uq_invRosenblattTransform(Y(:, VarsY), Y_Marginals(VarsY), CopY);
    end
end

% Final check that all columns of Y have been dealt with (raise error
% otherwise)
if any(isnan(Y(:)))
    error('Generalized Isoprobabilistic Transform Y of X contains nans')
end
end

% Perform general isoprobabilistic transform by block
function [Y, success] = uq_BlockGeneralIsopTransform(X, X_Marginals, X_Copula, Y_Marginals, Y_Copula)

% if independent copula, run standard isoprobabilitstic transform
if uq_isIndependenceCopula(X_Copula)&&uq_isIndependenceCopula(Y_Copula)
    Y = uq_IsopTransform(X, X_Marginals, Y_Marginals);
    success = true;
else
    % function to check the type of copula
    checkCop = @(cop,typ) (strcmpi(cop.Type, typ))||...
        (strcmpi(cop.Type, 'Pair') && isfield(cop, 'Family') && strcmpi(cop.Family,typ));
    
    % function to check marginals
    checkMarg = @(marg,typ) ~any(~ismember(lower({marg.Type}),typ)) && ~isfield(marg,'Bounds');
    
    % if the copulas are Gaussian and the marginals are all Gaussian, use
    % Nataf transform which always stays in the Gaussian space
    if checkCop(X_Copula,'gaussian')&&checkMarg(X_Marginals,'gaussian')&&...
            checkCop(Y_Copula,'gaussian')&&checkMarg(Y_Marginals,'gaussian')
        
        Xstd = uq_NatafTransform(X, X_Marginals, X_Copula);
        Y = uq_invNatafTransform( Xstd, Y_Marginals, Y_Copula );
        success = true;
        
    % if the copulas are Student t and the marginals are all Student t, use
    % Nataf transform which always stays in the Student t space
    elseif checkCop(X_Copula,'student')&&checkMarg(X_Marginals,'student')&&...
            checkCop(Y_Copula,'student')&&checkMarg(Y_Marginals,'student')
        
        Xstd = uq_NatafTransform(X, X_Marginals, X_Copula);
        Y = uq_invNatafTransform(Xstd, Y_Marginals, Y_Copula );
        success = false;
        
    % The block cannot be transformed efficiently
    else
        Y = nan(size(X));
        success = false;
    end
end

end