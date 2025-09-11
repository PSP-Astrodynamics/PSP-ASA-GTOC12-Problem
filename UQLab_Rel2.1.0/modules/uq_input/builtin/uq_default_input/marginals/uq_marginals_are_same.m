function pass = uq_marginals_are_same(X_Marginals, Y_Marginals)
% [pass, reason] = uq_ksmarginals_are_same(X_Marginals, Y_Marginals)
%     Provided ks marginal distributions X_Marginals and Y_Marginals, check 
%     that X_Marginals(ii) is equivalent to Y_Marginals(ii) for each ii.
%
% pass: 1 (true) or 0 (false)

pass = 1;

Mx = length(X_Marginals);
My = length(Y_Marginals);

% Check that nr. of marginals is the same
if Mx ~= My
    pass = 0;
else
    % For each marginal...
    for ii = 1:Mx
        marg_x = X_Marginals(ii);
        marg_y = Y_Marginals(ii);
        
        % Add bounds, if missing (+/- inf)
        if ~isfield(marg_x, 'Bounds')
            marg_x.Bounds = [-inf, inf];
        end
        
        if ~isfield(marg_y, 'Bounds')
            marg_y.Bounds = [-inf, inf];
        end

        % ...Check that the type is the same
        if ~strcmpi(marg_x.Type, marg_y.Type)
            pass = 0;
            break;
        % ...Check that the bounds are the same
        elseif ~isequal(marg_x.Bounds, marg_y.Bounds)
            pass = 0;
            break;
        % ...Check that the parameters are the same
        elseif ~isequal(marg_x.Parameters,marg_y.Parameters)
            pass = 0;
            break;
        end
    end
end
        
        
            
            
            
