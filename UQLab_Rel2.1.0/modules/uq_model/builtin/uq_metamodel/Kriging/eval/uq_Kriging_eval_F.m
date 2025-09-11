function F = uq_Kriging_eval_F(X,current_model)
%UQ_KRIGING_EVAL_F evaluates the trend (observation) matrix at X of a Kriging metamodel. 
%
%   F = uq_Kriging_eval_F(X,current_model) returns the trend (observation)
%   matrix F evaluated at points X of a Kriging metamodel stored in
%   current_model.
%
%   See also UQ_KRIGING_CALCULATE, UQ_KRIGING_EVAL, UQ_KRIGING_INITIALIZE, 
%   UQ_KRIGING_INITIALIZE_TREND.

%% Set local variables
M = current_model.Internal.Runtime.MnonConst;  % Input dimensions
N = size(X,1);  % Number of rows (size of experimental design)
nonConstIdx = current_model.Internal.Runtime.nonConstIdx;

% Obtain the current output
current_output = current_model.Internal.Runtime.current_output ;

% Variable shorthand
InternalKriging = current_model.Internal.Kriging(current_output);

%% If the F function is given use it, otherwise proceed with polynomial F
if isfield(InternalKriging.Trend,'CustomF') && ...
        ~isempty(InternalKriging.Trend.CustomF)
    if isnumeric(InternalKriging.Trend.CustomF)
        % F is numeric
        F = repmat(InternalKriging.Trend.CustomF, N, 1);
    else
        % F is a cell array, this is the general case of custom trend
        P = length(InternalKriging.Trend.CustomF);
        F = zeros(N,P);
        for ii = 1:P
            f_ii =  InternalKriging.Trend.CustomF{ii};
            F(:,ii) = f_ii(X);
        end
    end
else
    % the trend is not Custom, use polynomial basis for F
    
    %% Get the polynomial type for each input dimension
    PolyTypes = {InternalKriging.Trend.PolyTypes{nonConstIdx}};
    P = InternalKriging.Trend.Degree;

    %% Get the polynomial basis index matrix
    % current maximum degree. It is set to the first value of Degree array,
    % even for a non-basis adaptive scheme
    MaxDegree = InternalKriging.Trend.Degree(1);
    % if truncation is set to manual,
    % use the user-supplied polynomial indices, otherwise compute them
    
    %% Add indices to the Trend options
    if isfield(InternalKriging.Trend.TruncOptions,'Custom')
        % User-specified truncation
        current_model.Internal.Kriging(current_output).Trend.Indices = ...
            InternalKriging.Trend.TruncOptions.Custom;
    else
        current_model.Internal.Kriging(current_output).Trend.Indices = ...
            uq_generate_basis_Apmj(...
                0:MaxDegree, M, InternalKriging.Trend.TruncOptions);
    end

    %% Compute the univariate polynomials
    univ_p_val = zeros(N, M, P+1);
    % evaluating the univariate polynomials in the experimental design
    for ii = 1:M
        currPolyType = PolyTypes{ii};
        if iscell(currPolyType)
            currPolyType = cell2string(currPolyType);
        end
        switch lower(currPolyType)
            case 'simple_poly'
                univ_p_val(:,ii,:) = uq_eval_simple_poly(P,X(:,ii));
        end
    end
    F = uq_PCE_create_Psi(...
            current_model.Internal.Kriging(current_output).Trend.Indices,...
            univ_p_val);
end

end
