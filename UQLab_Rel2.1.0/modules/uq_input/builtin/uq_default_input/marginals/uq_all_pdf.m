function pdfx = uq_all_pdf(X,Marginals)
% UQ_ALL_PDF(X, Marginals) 
%     calculates the marginal Probability Density Function (PDF) of
%     each component of a random vector for values collected in X matrix. 
%     Each column of X corresponds to a component of the random vector that 
%     follows some distribution with some parameters as specified by the 
%     Marginals structure array. In order to compute the joint PDF use the
%     uq_evalPDF function.
%
%     For more information about available distributions and their 
%     parameters please refer to the UQLab user manual: The Input module
%
% See also UQ_ALL_CDF, UQ_ALL_INVCDF, UQ_EVALPDF
pdfx = zeros(size(X));

for ii = 1:length(Marginals)
    
    %% marginal-specific options
    if strcmpi(Marginals(ii).Type, 'ks')
        if isfield(Marginals(ii), 'KS') %&& ...
            Marginals(ii).Parameters = Marginals(ii).KS;
        else
            iOpts.Marginals(1) = Marginals(ii);
            tmpInput = uq_createInput(iOpts, '-private');
            Marginals(ii).Parameters = tmpInput.Marginals(1).KS;
        end
    end
    
    pdfarguments = {X(:,ii), Marginals(ii).Type, Marginals(ii).Parameters};
       
    if isfield(Marginals(ii), 'Options')
       pdfarguments = [pdfarguments, Marginals(ii).Options];
    end

    if isfield(Marginals(ii),'Bounds') && ...
            ~isempty(Marginals(ii).Bounds)
        %% calculate PDF (bounded case)
        a = Marginals(ii).Bounds(1); % lower bound
        b = Marginals(ii).Bounds(2); % upper bound
        if ~isfield(Marginals(ii), 'Options')
            F =  uq_cdfFun(Marginals(ii).Bounds(:), Marginals(ii).Type, ...
                Marginals(ii).Parameters) ; 
        else
            F =  uq_cdfFun(Marginals(ii).Bounds(:), Marginals(ii).Type, ...
                Marginals(ii).Parameters, Marginals(ii).Options) ; 
        end
        Fa = F(1);
        Fb = F(2);
        
        idx_x_lt_a = X (:,ii) < a ;
        idx_x_gt_b = X (:,ii) > b ;
        idx_x_in_ab = ~(idx_x_lt_a | idx_x_gt_b) ;
        
        % Calculate the PDF in the region between the bounds
        pdfx(:,ii) = uq_pdfFun(pdfarguments{:});
        pdfx(idx_x_lt_a, ii) = 0 ;
        pdfx(idx_x_gt_b, ii) = 0 ;

        % Add the weight that is truncated out of the bounds 
        % as uniform along the distribution to keep integral(pdf) == 1
        trunc_weight = Fb - Fa;
        pdfx(idx_x_in_ab, ii) = pdfx(idx_x_in_ab,ii)/trunc_weight;
    else
        %% calculate PDF (unbounded case)
        pdfx(:,ii)  = uq_pdfFun(pdfarguments{:});
    end
end
