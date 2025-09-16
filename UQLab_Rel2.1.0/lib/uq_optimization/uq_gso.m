function [xstar,fstar,exitflag,output] = uq_gso(fun, mygrid, nvars, lb, ub, options)
% UQ_GSO finds a local unconstrained minimum of multi-dimensional function by grid search.
%   UQ_GSO attempts to solve problems of the following form:
%   xstar = argmin F(X), where lb <= X <= ub.
%             X
%
%   XSTAR = UQ_GSO(FUN, MYGRID, NVARS) finds a local minimizer of 
%   the function FUN using only evaluations at a predefined set of 
%   points (MYGRID) of size N. NVARS is the input dimension (number of 
%   design variables) of FUN.
%
%   XSTAR = UQ_GSO(FUN, MYGRID, NVARS, LB, UB) finds a local minimizer of 
%   the function FUN using only evaluations at a predefined set of points 
%   (MYGRID), and only evaluating data points that are within lower 
%   and upper bounds defined by LB and UB, respectively.
%
%   XSTAR = UQ_GSO(FUN, [], NVARS, LB, UB) finds a local minimizer of 
%   the function FUN using only evaluations at points defined in
%   an automatically generated grid within the lower (LB) and upper (UB)
%   bounds.
%
%   XSTAR = UQ_GSO(FUN, MYGRID, NVARS, LB, UB, OPTIONS) and
%   XSTAR = UQ_GSO(FUN, [], NVARS, LB, UB, OPTIONS) find a local minimizer 
%   of the function FUN as described above with the default optimization 
%   options replaced by the values in the OPTIONS structure:
%       .Display      : Level of output display - String:
%                           'none' : No output.
%                           'iter' : Display output at each iteration.
%                           'final': Only the final output.
%                       default: 'final'.
%       .DiscPoints   : Number of points that are used to construct
%                       the grid. One value for each input dimension,
%                       otherwise the value is replicated along
%                       all dimensions - Scalar or NVARS-by-1 Double,
%                       default: 5.
%       .isVectorized : Flag indicating whether the objective function is
%                       vectorized or not - Logical,
%                       default: true.
%
%   [XSTAR,FSTAR] = UQ_GSO(FUN,...) additionally returns the value of
%   the objective function at the solution XSTAR.
%
%   [XSTAR,FSTAR,EXITFLAG] = UQ_GSO(FUN,...) additionally returns
%   an exit flag that indicates the exit condition:
%        1 : Successful exit - A local minimum has been found.
%       -1 : An error occured - e.g., none of the given points belong to 
%            the specified bounds.
%
%   [XSTAR,FSTAR,EXITFLAG,OUTPUT] = UQ_GSO(FUN,,...) additionally returns
%   a structure with additional information about the optimization process:
%       .message  : Exit message - String.
%       .funccount: Total number of objective function evaluations -
%                   Integer.
%       .History  : History of the optimization process (Xi, FUN(Xi) 
%                   at each Xi on the grid) - Structure:
%                     .Grid    : Grid points that have been evaluated in 
%                                the search for an optimum - 
%                                NVARS-by-N Double.
%                     .Fitness : Objective function values corresponding
%                                to the grid points - N-by-1 Double.
%
%   See also: UQ_CEO, UQ_CMAES, UQ_1P1CMAES, UQ_C1P1CMAES

%% Pre-processing and parameters checking

% Check the number of input arguments
try
    narginchk(3,6)
catch ME
    error('Wrong number of input arguments.')
end
if nargin < 6
    options = [];
    if nargin < 5
        ub = [];
        if nargin < 4
            lb = [];
        end
    end
end

% Consistency checks and get number of variables
% Check if input is a row or column vector (for multi-dimensional inputs)
if isempty(mygrid) && (isempty(lb) || isempty(ub))
    error('Either a grid or bounds should be given.')
elseif isempty(mygrid) && ~isempty(lb) && ~isempty(ub)
    % Initial points is not given but bounds are
    % Make sure lb and ub are of equal sizes
    if length(lb) ~= length(ub)
        error('Dimension mismatch between lb and ub!')
    end
    if ~isempty(nvars)
        if length(lb(:))> 1 && nvars ~= length(lb(:))
            error('The given number of variables is not equal to dimension of the bounds')
        end
    else
        nvars = length(lb(:));
    end
    if any(isnan(lb)) || ~any(isfinite(lb)) || any(isnan(ub)) || ~any(isfinite(lb))
        error('Bounds should have finite values if initial grid is not given')
    end
elseif ~isempty(mygrid) && (isempty(lb) || isempty(ub))
    % mygrid is given but not lb and ub
    if ~(size(mygrid,1) == nvars || size(mygrid,2) == nvars)
        error('The given grid does not match the number of variables nvars!')
    end
elseif ~isempty(mygrid) && ~isempty(lb) && ~isempty(ub)
    % mygrid, lb and ub are given. Check that dimensions match
    % Make sure lb and ub are of equal sizes
    if length(lb) ~= length(ub)
        error('Dimension mismatch between lb and ub!')
    end
    if ~isempty(nvars)
        if length(lb) > 1 && nvars ~= length(lb(:))
            error('The given number of variables is not equal to dimension of the bounds')
        end
    else
        nvars = length(lb(:));
    end
    
    if nvars > 1 && length(lb) == 1
        lb = repmat(lb,nvars,1);
        ub = repmat(ub,nvars,1);
    end
end

% Make everything column
if isempty(mygrid)
    if size(lb,2) == nvars
        FunTakesRow = true;
    else
        FunTakesRow = false;
    end
else
    if size(mygrid,2) == nvars
        FunTakesRow = true;
    else
        FunTakesRow = false;
    end
end
if isrow(lb), lb = lb(:); end
if isrow(ub), ub = ub(:); end

% In case inputs are transposed,
% make sure that the function handles handle it properly
if FunTakesRow
    funfcn = @(x)fun(x');
else
    funfcn = @(x)fun(x);
end

%% Optimization parameters parsing

% Default values assignment for optional parameters
if isempty(options)
    options = struct;
end

if ~isfield(options,'DiscPoints')
    DiscPoints = 5;
else
    DiscPoints = options.DiscPoints;
end
if ~isfield(options,'isVectorized')
    isVectorized = true;
else
    isVectorized = options.isVectorized;
end
if ~isfield(options,'Display')
    Display = 'final';
else
    Display = options.Display;
end

%% Grid generation
% Generate grid points if not given by the user
% The user should make sure that the final size of the mygrid is not too
% large
if isempty(mygrid)
    mygridVector = cell(nvars);
    if length(DiscPoints) == 1
        for ii = 1:nvars
            mygridVector{ii} = linspace(lb(ii),ub(ii),DiscPoints);
        end
    elseif length(DiscPoints) == nvars
        for ii = 1:nvars
            mygridVector{ii} = linspace(lb(ii),ub(ii),DiscPoints(ii));
        end
    else
        error('The number of grid points should be a scalar or a vector of size nvars.')
    end
    
    if nvars == 1
        mygrid = mygridVector{1};
    elseif nvars == 2
        idx = uq_findAllCombinations(mygridVector{1},mygridVector{2});
        mygrid = [mygridVector{1}(idx(:,1)); mygridVector{2}(idx(:,2))];
    else
        find_comb = 'idx = uq_findAllCombinations(mygridVector{1}';
        for jj = 2:nvars
            find_comb = [find_comb, ', mygridVector{',num2str(jj) '}'];
        end
        find_comb = [find_comb, ');'];
        eval(find_comb);
        mygrid = [];
        for jj = 1:nvars
            mygrid = [mygrid;mygridVector{jj}(idx(:,jj))]; %#ok<NODEF>
        end
    end
    
end
if size(mygrid,2) == nvars && size(mygrid,1) ~= nvars
    mygrid = mygrid';
end

%% Grid search optimization

% Display the header for the iterations
headerString = {'Best', 'f-count', 'x', 'f(x)', 'f(x)'};
if strcmpi(Display,'iter')
    if length(mygrid(:,1)) == 1
        fprintf('%52s\n', headerString{1});
        fprintf('%-7s %9s %18s %15s\n', headerString{2:end})
    elseif length(mygrid(:,1)) == 2
        fprintf('%66s\n', headerString{1});
        fprintf('%-7s %16s %25s %15s\n', headerString{2:end})
    elseif length(mygrid(:,1)) == 3
        fprintf('%80s\n', headerString{1});
        fprintf('%-7s %24s %31s %15s\n', headerString{2:end})
    else
        fprintf('%84s\n', headerString{1});
        fprintf('%-7s %28s %31s %15s\n', headerString{2:end})
    end
end

% Points that are smaller than the lower bound in any given direction
if isempty(lb)
    idx_lb = [];
else
    idx_lb = bsxfun(@lt,mygrid,lb) ;
end
% Points that are larger than the upper bound in any given direction
if isempty(ub)
    idx_ub = [];
else
    idx_ub =  bsxfun(@gt,mygrid,ub);
end
% Points that are out of bounds
idx_inBounds = find(~any([idx_lb;idx_ub])==1);

% Grid search optimization iteration
if isVectorized
    fval = funfcn(mygrid(:,idx_inBounds)) ;
    fcount = length(idx_inBounds);
    if strcmpi(Display,'iter')
       X = mygrid(:,idx_inBounds) ;
        BestF = min(fval) ;
        for kk = 1:length(fval)
            if size(X,1) == 1 
                fprintf('%-7g | %+13.6e | %13.6e | %13.6e\n',...
                    kk, X(1,kk), fval(kk), BestF)
            elseif size(X,1) == 2
                fprintf('%-7g | %+13.6e %+13.6e | %13.6e | %13.6e\n',...
                    kk, X(1,kk), X(2,kk), fval(kk), BestF)
            elseif size(X,1) == 3
                fprintf('%-7g | %+13.6e %+13.6e %+13.6e | %13.6e | %13.6e\n',...
                     kk, X(1,kk), X(2,kk), X(3,kk), fval(kk), BestF)
            else
                fprintf('%-7g | %+13.6e %+13.6e %+13.6e ... | %13.6e | %13.6e\n',...
                    kk, X(1,kk), X(2,kk), X(3,kk), fval(kk), BestF)
            end
        end
    end
else
    fcount = size(mygrid,2);
    fval = zeros(1,fcount);
    BestF = Inf;
    for kk = 1: size(mygrid,2)
        if idx_inBounds(kk)
            X = mygrid(:,kk);
            J = funfcn(X);
            fval(kk) = J;
            if J < BestF
                BestF = J;
            end
            if strcmpi(Display,'iter')
                if length(X) == 1
                    fprintf('%-7g | %+13.6e | %13.6e | %13.6e\n',...
                        kk, X(1), J, BestF)
                elseif length(X) == 2
                    fprintf('%-7g | %+13.6e %+13.6e | %13.6e | %13.6e\n',...
                        kk, X(1), X(2), J, BestF)
                elseif length(X) == 3
                    fprintf('%-7g | %+13.6e %+13.6e %+13.6e | %13.6e | %13.6e\n',...
                        kk, X(1), X(2), X(3), J, BestF)
                else
                    fprintf('%-7g | %+13.6e %+13.6e %+13.6e ... | %13.6e | %13.6e\n',...
                        kk, X(1), X(2), X(3), J, BestF)
                end
            end
        else
            fval(kk) = NaN ;
            fcount = fcount - 1 ;
        end
    end
end

%% Return results
%
sortSX = sortrows([mygrid(:,idx_inBounds)' fval(:)],nvars+1);
xstar = sortSX(1,1:nvars);
fstar = sortSX(1,nvars+1);
if FunTakesRow
    history.Grid = mygrid(:,idx_inBounds);
    if isVectorized
        history.Fitness = fval;
    else
        history.Fitness = fval(idx_inBounds);
    end
else
    xstar = xstar';
    history.Grid = mygrid(:,idx_inBounds)';
    if isVectorized
        history.Fitness = fval';
    else
        history.Fitness = fval(idx_inBounds)';
    end
end

% Print the results
if fcount == 0
    output.message = sprintf('None of the grid points belong to the defined bounds.');
    exitflag = -1;
else
    output.message = sprintf('Local minimum found based on the given grid points.');
    exitflag = 1;
end

if strcmpi(Display,'iter') || strcmpi(Display,'final')
    switch exitflag
        case 1
            fprintf('\nLocal minimum found that satisfies the bound constraints.\n')
        case -1
            fprintf('\nNo solution found that satisfies the bound constraints.\n')
     end
    fprintf('obj. value = %12.6g\n',fstar)
end

output.funccount = fcount;
output.History = history;

end