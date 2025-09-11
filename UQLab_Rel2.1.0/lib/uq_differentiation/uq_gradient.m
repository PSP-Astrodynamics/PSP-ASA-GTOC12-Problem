function [G,M_X,Cost,ExpDesign] = uq_gradient(X, fun, GradientMethod, FDStep, GivenH, KnownX, Marginals)
% UQ_GRADIENT computes the gradient of a multi-dimensional function at given points.
%
%   G = UQ_GRADIENT(X, FUN) returns the gradient G of the function FUN
%   evaluated at the points X given as (N-by-M) matrix, where N is
%   the number of points and M is the number of input dimensions.
%   It uses the 'forward' method and step size of 1e-3.
%
%   G = UQ_GRADIENT(X, FUN, GRADIENTMETHOD) uses the approximation method
%   specified in GRADIENTMETHOD, a String:
%       'forward'     : forward difference approximation (default).
%       'backward'    : backward difference approximation.
%       'centered' or : centered difference approximation.
%         'centred'
%
%   G = UQ_GRADIENT(X, FUN, GRADIENTMETHOD, FDSTEP) allows for selecting
%   the type of step size by specifying FDSTEP, a String:
%       'absolute' or   : Absolute step size, GivenH * 1 (default).
%         'abs' or
%         'fixed' or
%         'standardized'
%       'relative' or   : Relative step size, proportional 
%         'rel'           to the standard deviation.
%
%   G = UQ_GRADIENT(X, FUN, GRADIENTMETHOD, FDSTEP, GIVENH) allows for
%   adjusting the step size by specifying GIVENH, a scalar Double.
%   The actual effect of GIVENH on the step size depends
%   on the selected FDSTEP:
%       'absolute' : GIVENH for all input dimensions.
%                    default: 1e-3.
%       'relative' : GIVENH * standard deviation of each variable.
%                    Only if MARGINALS is provided (see below).
%
%   G = UQ_GRADIENT(X, FUN, GRADIENTMETHOD, FDSTEP, GIVENH, KNOWNX) uses
%   uses KNOWNX, a set of precalculated values of FUN at X, instead of
%   evaluating the function directly on X.
%
%   G = UQ_GRADIENT(X, FUN, GRADIENTMETHOD, FDSTEP, GIVENH, KNOWNX, MARGINALS)
%   looks for the standard deviation of the input variables
%   in MARGINALS, a structure that is part of a UQLab input object.
%
%   [G,M_X] = UQ_GRADIENT(...) additionally returns the values of FUN at 
%   the points X.
%
%   [G,M_X,COST] = UQ_GRADIENT(...) additionally returns the cost of
%   the approximation in terms of the number of model evaluations.
%
%   [G,M_X,COST,EXPDESIGN] = UQ_GRADIENT(...) additionally returns
%   a (1-by-N) structure array containing the experimental designs used
%   in the approximation of the gradient for each given point in X.
%
%   See also: UQ_FORM, UQ_SORM

%% Input processing
% Handle some basic defaults:
if ~exist('GradientMethod', 'var')
    GradientMethod = 'forward';
end
if ~exist('FDStep', 'var')
    FDStep = 'fixed';
end
if ~exist('GivenH', 'var')
    GivenH = 1e-3;
end

% If the function is already evaluated in the point, we can provide the
% results in knownX and avoid its computation.
NeedX = false;
if nargin < 6  % There are not evaluated points nor Marginals
    if strcmpi(GradientMethod,'forward') || strcmpi(GradientMethod,'backward') || nargout > 1
        %         KnownX = fun(X);
        NeedX = true;
    end
    Marginals = [];
else
    if ~isnumeric(KnownX)
        % Then the arguments are switched
        if nargin == 7
            temp = KnownX;
            KnownX = Marginals;
            Marginals = temp;
        else
            Marginals = KnownX;
            clear KnownX
            if nargout > 1 || ...
                    strcmpi(GradientMethod,'forward') || ...
                    strcmpi(GradientMethod,'backward')
                
                % KnownX = fun(X);
                % We don't calculate M(X) right now, lets do it in the
                % vectorized way, together with the gradient
                
                NeedX = true;
                
            else
                
                NeedX = false;
            end
        end
    end
end

[N, M] = size(X);


% We need to compute evaluation points only for the non-constant
% marginals. Other treatments would be more intrusive.
if exist('Marginals','var') && isfield(Marginals,'Type')
    nonConst = ~ismember(lower({Marginals.Type}),'constant');
else % assume they're all variable
    nonConst = ones(1,M);
end
nonConstIdx = find(nonConst);
constIdx    = find(~nonConst);

switch lower(FDStep)
    
    % Standardized is a particular case for structural reliability,
    % here it behaves as the fixed case.
    case {'absolute','abs','fixed','standardized'}
        % Difference used for the approximation
        h = GivenH*ones(1, length(nonConst));
        
    case {'relative', 'rel'}
        % h is for each point a percentage of the standard deviation
        h = zeros(1, length(nonConst));
        if isempty(Marginals) % check if marginals are provided
            fprintf('For FDStep "%s" the marginals must be provided. They are missing. Continue with FDStep "fixed"',FDStep)
            FDStep = 'standardized';
            h = GivenH*ones(1, length(nonConst));
        else
            for pp = 1:length(nonConstIdx)
                ii = nonConstIdx(pp);
                if Marginals(ii).Moments(2) == 0
                    fprintf(...
                        '\nWarning: "%s" has variance 0. Gradient cannot be computed using a step size depending on it.\nUsing a fixed step size of h = %g for this variable...\n',...
                        Marginals(ii).Name,...
                        GivenH);
                    h(ii) = GivenH;
                else
                    h(ii) = GivenH*Marginals(ii).Moments(2);
                end
            end
        end
    otherwise
        fprintf('\nWarning: The method provided for computing the finite differences on the gradient, "%s", was not recognized.\nSetting it to "fixed" instead.\n', FDStep);
        FDStep = 'standardized';
        
        % Difference used for the approximation
        h = GivenH*ones(1,M);
end

h = h(nonConstIdx);

% Storage preallocation
Cost = zeros(N,1);
ExpDesign = struct;

% Preallocate output matrix
G = cell(N,1);

for ii = 1:N
    % Is a method rather than a function
    if ischar(GradientMethod)
        switch lower(GradientMethod)
            case 'forward'
                % Forward finite differences
                X_nonConst = X(ii,nonConstIdx);
                
                XplusH = bsxfun(@plus, X_nonConst, diag(h));
                
                % This is to treat the case when we don't want to compute some
                % of the gradients (marginals are constant):
                XplusHTmp = zeros(size(XplusH,1),size(X,2));
                XplusHTmp(:,nonConstIdx) = XplusH;
                XplusHTmp(:,constIdx) = repmat(X(ii,constIdx),size(XplusH,1),1);
                XplusH = XplusHTmp;
                if NeedX
                    ExpDesign(ii).X = [X(ii,:); XplusH];
                    ExpDesign(ii).Y = fun(ExpDesign(ii).X);
                    Cost(ii) = size(ExpDesign(ii).Y, 1);
                    KnownX(ii,:) = ExpDesign(ii).Y(1, :);
                    fXplusH = ExpDesign(ii).Y(2:end, :);
                else
                    
                    ExpDesign(ii).X = XplusH;
                    ExpDesign(ii).Y = fun(ExpDesign(ii).X);
                    Cost = size(ExpDesign(ii).Y, 1);
                    fXplusH = ExpDesign(ii).Y;
                end
                Difference = bsxfun(@minus, fXplusH, KnownX(ii,:))';
                G{ii} = bsxfun(@rdivide, Difference, h);
                
            case 'backward'
                % Backward finite differences
                XminusH = bsxfun(@minus, X(ii,nonConstIdx), diag(h));
                
                XminusHTmp = zeros(size(XminusH,1),size(X,2));
                XminusHTmp(:,nonConstIdx) = XminusH;
                XminusHTmp(:,constIdx) = repmat(X(:,constIdx),size(XminusH,1),1);
                XminusH = XminusHTmp;
                
                if NeedX
                    ExpDesign(ii).X = [X(ii,:); XminusH];
                    ExpDesign(ii).Y = fun(ExpDesign(ii).X);
                    Cost = size(ExpDesign(ii).Y, 1);
                    KnownX(ii,:) = ExpDesign(ii).Y(1, :);
                    fXminusH = ExpDesign(ii).Y(2:end, :);
                else
                    ExpDesign(ii).X = XminusH;
                    ExpDesign(ii).Y = fun(ExpDesign(ii).X);
                    fXminusH = ExpDesign(ii).Y;
                    Cost(ii) = size(ExpDesign(ii).Y, 1);
                end
                
                Difference = (repmat(KnownX(ii,:), M, 1) - fXminusH)';
                G{ii} = bsxfun(@rdivide, Difference, h);
                
            case {'centred','centered'}
                % Centred finite differences (requires more model evaluations)
                % Prepare the increased and decreased points:
                XplusH = bsxfun(@plus, X(ii,:), diag(h/2));
                XminusH = bsxfun(@minus, X(ii,:), diag(h/2));
                
                if NeedX && nargout > 1
                    
                    ExpDesign(ii).X = [X(ii,:); XplusH; XminusH];
                    ExpDesign(ii).Y = fun(ExpDesign(ii).X);
                    Cost(ii) = size(ExpDesign(ii).Y, 1);
                    KnownX(ii,:) = ExpDesign(ii).Y(1, :);
                    fXplusH = ExpDesign(ii).Y(2:end, :);
                else
                    ExpDesign(ii).X = [XplusH; XminusH];
                    ExpDesign(ii).Y = fun(ExpDesign(ii).X);
                    fXplusH = ExpDesign(ii).Y;
                    Cost(ii) = size(fXplusH, 1);
                end
                
                fXminusH = fXplusH(length(XminusH) + 1:end, :);
                fXplusH = fXplusH(1 : length(XminusH), :);
                
                G{ii} = bsxfun(@rdivide, (fXplusH  - fXminusH)', h);
                
            otherwise
                fprintf('\nError: GradientMethod "%s" not available. Please choose "forward", \n',GradientMethod)
                fprintf('"backward" or "centred" or insert your own gradient function.\n\n')
                error('While trying to evaluate the gradient')
                
        end % Of switch method type
        
    else  % Then it is a function
        user_gradient = GradientMethod;
        G{ii} = user_gradient(X(ii,:));
        Cost(ii) = 1;
        if nargout > 1
            KnownX(ii,:) = fun(X(ii,:));
            Cost(ii) = Cost(ii) + 1;
            ExpDesign(ii).X = X(ii,:);
            ExpDesign(ii).Y = KnownX(ii,:);
        end
        
    end % Of ischar()
end % Of for-loop

if nargout > 1
    M_X = KnownX;
end

% Add the constant dimensions - they simply have zero gradient:
Gtmp = zeros(N,M,size(G{ii},1));
% And therefore reshape the G matrix
G = permute(cat(3,G{:}),[3,2,1]); % cat makes cell array into 3d matrix and with permute dimensions 1 & 3 are switched
Gtmp(:,nonConstIdx,:) = G;
G = Gtmp;

Cost = sum(Cost);

end