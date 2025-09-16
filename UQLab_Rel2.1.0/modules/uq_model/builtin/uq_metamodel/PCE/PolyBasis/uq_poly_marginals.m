function [PolyMarginals, PolyCopula] = uq_poly_marginals(PolyTypes,params)
% [POLYMARGINALS, POLYCOPULA] = UQ_POLY_MARGINALS(POLYTYPES,PARAMS): map
%     polynomial types to the corresponding marginal distributions.
%
% See also: UQ_PCE_INITIALIZE,UQ_INITIALIZE_UQ_METAMODEL

% For consistency, the 'zero' polynomial type was added to treat the case
% when the distribution is 'Constant'.

% polynomial types
Types = {...
     'legendre'; ...
     'hermite' ;...
     'laguerre';...
     'jacobi';...
     'fourier';...
     'zero';...
    };

% corresponding marginals
Marginals = {...
     'Uniform';...
     'Gaussian';...
     'Gamma';...
     'Beta';...
     'Uniform';....
     'Constant';
    };


for ii =1:length(PolyTypes)
    
    if any(strcmpi(PolyTypes{ii},{'Arbitrary','ArbitraryPrecomp'}))
        % These are assumed to be computed already in the initialization of
        % PCE. They should have been computed since they are needed to 
        % compute numerically the recurrence coefficients.
        PolyMarginals(ii).Type = params{ii}.pdfname;
        PolyMarginals(ii).Parameters = params{ii}.parameters;
        PolyMarginals(ii).Bounds = params{ii}.bounds;
        if isfield(params{ii},'KS')
           PolyMarginals(ii).KS = params{ii}.KS; 
        end
    else
        % For all other cases, the 'Marginals' are defined from a
        % correspondence between polynomials and marginals.
        idx = find(strcmpi(Types, PolyTypes{ii}));
        PolyMarginals(ii).Type = Marginals{idx};
    end
    
    switch lower(PolyTypes{ii})
        case 'legendre'
            % name  = 'Uniform'
            param = [-1 1];
        case 'hermite'
            % name = 'Gaussian'
            param = [0 1];
        case 'laguerre'
            % name = 'Gamma'
            parms = params{ii};
            param = [1 parms(2)];
        case 'jacobi'
            % In the case that we have Jacobi polynomials,
            % we scale back to the [0 1] beta distribution.
            % name  = 'beta';
            parms = params{ii};
            param = [parms(1) parms(2) 0 1];
        case {'arbitrary','arbitraryprecomp'}
            % We need to keep track the distribution these polynomials are
            % orthogonal to:
            PolyMarginals(ii).Type  = params{ii}.pdfname;
            param = params{ii}.parameters;
            % Kernel smoother needs some special treatment.
            if strcmpi(PolyMarginals(ii).Type,'ks')
                PolyMarginals(ii).KS = params{ii}.KS;
            end
        case 'fourier'
            % The treatment for spectral types is not mature yet. 
            % they don't really fit in that context anyway.
            %name = 'Uniform';
            param = [-pi pi];
        case 'zero'
            % This is only needed for consistency. Normally it should not
            % be used.
            %name = 'constant';
            param = params{ii};
    end
    %PolyMarginals(ii).Type = name;
    PolyMarginals(ii).Parameters = param;
end

% Also add the independent copula (even if it is unnecessary at this stage)
PolyCopula.Type = 'Independent';
