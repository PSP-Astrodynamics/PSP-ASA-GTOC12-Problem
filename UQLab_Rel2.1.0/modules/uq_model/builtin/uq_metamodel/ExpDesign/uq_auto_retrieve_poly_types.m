function poly_types = uq_auto_retrieve_poly_types(input_module)
% POLY_TYPES = UQ_AUTO_RETRIEVE_POLY_TYPES(INPUT_MODULE): simple script to
%     retrieve the default orthogonal polynomials based on the specified
%     INPUT_MODULE.
%
% See also: UQ_POLY_MARGINALS,UQ_PCE_INITIALIZE

%% consistency checks and initializations
if ~isprop(input_module, 'Marginals')%&&~isfield(input_module, 'Marginals')
    error('Error: the specified input module %s is not initialized correctly', input_module.Name);
end

Marginals = input_module.Marginals;
nvars = length(Marginals);

%% creating the array of poly_types
poly_types = cell(nvars,1);
for ii = 1:nvars
    % Default to arbitrary for bounded variables
    if isfield(Marginals(ii), 'Bounds') && ~isempty(Marginals(ii).Bounds)
        PolyType = 'arbitrary';
        % We have to check that the distribution can be integrated with the
        % integrator we provide. If not, then depending on the existence of 
        % bounds, the polytypes are set to hermite or legendre.
       
        % We will at least need some bounds for the integrator,
        % therefore we'll use the invcdf:
        b0 = uq_all_invcdf(0,Marginals(ii));
        b1 = uq_all_invcdf(1,Marginals(ii));
        wp = uq_all_invcdf(linspace(1e-8,1-1e-8,30)',Marginals(ii));
        wp(isinf(wp)) = [];
        pdfint = integral(@(x) uq_all_pdf(x',Marginals(ii))',b0,b1,'waypoints', wp);
        
        if abs(pdfint-1)>1e-3
            PolyType = 'legendre';
        end
        
    else
        switch lower(Marginals(ii).Type)
            case {'gaussian','lognormal'}
                PolyType = 'Hermite';
            case {'lognormal'}
                PolyType = 'Hermite';
            case {'uniform'}
                PolyType = 'Legendre';
            case {'beta'}
                PolyType = 'Jacobi';
            case {'gamma'}
                PolyType = 'Laguerre';
            case {'constant'}
                % Added for consistent treatment of 'Constant'
                PolyType = 'Zero';
            otherwise % default to arbitrary polynomials (possibly defined at [-inf, inf])
                PolyType = 'Arbitrary';
                % We will at least need some bounds for the integrator,
                % therefore we'll use the invcdf:
                b0 = uq_all_invcdf(0,Marginals(ii));
                b1 = uq_all_invcdf(1,Marginals(ii));
                wp = uq_all_invcdf(linspace(1e-8,1-1e-8,30)',Marginals(ii));
                wp(isinf(wp)) = [];
                pdfint = integral(@(x) uq_all_pdf(x',Marginals(ii))',b0,b1,'waypoints', wp);

                if abs(pdfint-1)>1e-3
                    PolyType = 'hermite';
                end

        end
    end
    
    poly_types{ii} = PolyType;
end
