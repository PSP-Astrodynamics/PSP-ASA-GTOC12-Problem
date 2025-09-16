function X = uq_all_invcdf(F, Marginals)
% X = UQ_ALL_INVCDF(F, Marginals):
%     Calculates the inverse Cumulative Distribution Function
%     given CDF values of a random vector collected in F matrix. 
%     Each column of F corresponds to a component of the random vector that 
%     follows some distribution with some parameters as specified by the 
%     Marginals structure array
%
%     For more information about available distributions and their 
%     parameters please refer to the UQLab user manual: The Input module
%
% See also UQ_ALL_PDF, UQ_ALL_CDF

X = zeros(size(F));
for ii = 1:length(Marginals)
    if strcmpi(Marginals(ii).Type, 'ks') 
        Marginals(ii).Parameters = Marginals(ii).KS;
    end
    % If bounds are given then calculate the bounded inverse CDF 
    if isfield(Marginals(ii),'Bounds') && ...
            ~isempty(Marginals(ii).Bounds)
        if  ~isfield(Marginals(ii), 'Options')
            Fbounds =  uq_cdfFun(Marginals(ii).Bounds(:), Marginals(ii).Type, ...
                Marginals(ii).Parameters) ; 
            Fa = Fbounds(1);
            Fb = Fbounds(2) ; 
            % 'squeeze' the inverse CDF so that it lies in [a,b] interval
            X(:,ii) = uq_invcdfFun( F(:,ii)*(Fb-Fa) + Fa , Marginals(ii).Type, ...
            Marginals(ii).Parameters);
        else
            if isfield(Marginals(ii), 'Options') && ~isempty(Marginals(ii).Options)
                Fbounds =  uq_cdfFun(Marginals(ii).Bounds(:), Marginals(ii).Type, ...
                    Marginals(ii).Parameters, Marginals(ii).Options) ;
                Fa = Fbounds(1);
                Fb = Fbounds(2) ;
                X(:,ii) = uq_invcdfFun( F(:,ii)*(Fb-Fa) + Fa ,Marginals(ii).Type, ...
                    Marginals(ii).Parameters, Marginals(ii).Options);
            else
                Fbounds =  uq_cdfFun(Marginals(ii).Bounds(:), Marginals(ii).Type, ...
                    Marginals(ii).Parameters) ;
                Fa = Fbounds(1);
                Fb = Fbounds(2) ;
                X(:,ii) = uq_invcdfFun( F(:,ii)*(Fb-Fa) + Fa ,Marginals(ii).Type, ...
                    Marginals(ii).Parameters);
            end
        end
    else
        % If no bounds are given then calculate the unbounded inverse CDF
        if  ~isfield(Marginals(ii), 'Options') || isempty(Marginals(ii).Options)% if no Options is given, don't pass
            X(:,ii) = uq_invcdfFun(F(:,ii), Marginals(ii).Type, Marginals(ii).Parameters);
        else
            X(:,ii) = uq_invcdfFun(F(:,ii), Marginals(ii).Type, ...
                Marginals(ii).Parameters, Marginals(ii).Options);
        end
    end
end

end

