function cdfx = uq_all_cdf(X, Marginals)
% cdfx = UQ_ALL_CDF(X, Marginals):
%     calculates the marginal Cumulative Distribution Function (CDF) of
%     each component of a random vector for values collected in X matrix. 
%     Each column of X corresponds to a component of the random vector that 
%     follows some distribution with some parameters as specified by the 
%     Marginals structure array. 
%
%     For more information about available distributions and their 
%     parameters please refer to the UQLab Input module user manual.
% 
% See also UQ_ALL_PDF, UQ_ALL_INVCDF


cdfx = zeros(size(X));

for ii = 1:length(Marginals)

    cdfarguments = {};
    %% marginal-specific options
    if strcmpi(Marginals(ii).Type, 'ks')
        if uq_isnonemptyfield(Marginals(ii), 'Parameters') && isfield(Marginals(ii), 'KS') 
            Marginals(ii).Parameters = Marginals(ii).KS;
            Marginals(ii).KS = [];
        else
            iOpts.Marginals = Marginals(ii);
            if isfield(iOpts.Marginals, 'Moments')
                iOpts.Marginals = rmfield(iOpts.Marginals(1), 'Moments');
            end
            tmpInput = uq_createInput(iOpts, '-private');
            Marginals(ii).Parameters = tmpInput.Marginals(1).KS;
        end
    end
    if isfield(Marginals(ii), 'Options')
        cdfarguments = [cdfarguments, Marginals(ii).Options];
    end

    %% calculate CDF
    cdfx(:,ii) = uq_cdfFun(X(:,ii), Marginals(ii).Type, ...
        Marginals(ii).Parameters, cdfarguments{:});

    %% satisfy bounds if specified
    if isfield(Marginals(ii),'Bounds') && ...
            ~isempty(Marginals(ii).Bounds)
        a = Marginals(ii).Bounds(1); % lower bound
        b = Marginals(ii).Bounds(2); % upper bound
        if ~isfield(Marginals(ii), 'Options') || isempty(Marginals(ii).Options)
            F =  uq_cdfFun(Marginals(ii).Bounds(:), Marginals(ii).Type, ...
                Marginals(ii).Parameters) ; 
        else
            F =  uq_cdfFun(Marginals(ii).Bounds(:), Marginals(ii).Type, ...
                Marginals(ii).Parameters, Marginals(ii).Options) ; 
        end
        Fa = F(1);
        Fb = F(2);
        % 'squeeze' the inverse CDF so that it lies in [a,b] interval
        idx_x_lt_a = X (:,ii) < a ;
        idx_x_gt_b = X (:,ii) > b ;
        idx_x_in_ab = ~(idx_x_lt_a | idx_x_gt_b) ;

        cdfx(idx_x_lt_a, ii) = 0 ;
        cdfx(idx_x_gt_b, ii) = 1 ;
        cdfx(idx_x_in_ab, ii) = (cdfx(idx_x_in_ab, ii) - Fa) / (Fb - Fa) ;
    end
 
    
end
