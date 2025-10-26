function [current_model, Options]= uq_initialize_uq_metamodel_univ_basis(current_model, Options, meta_idx)
% [current_model, Options] = UQ_INITIALIZE_UQ_METAMODEL_UNIV_BASIS(current_model, Options)
%
%   Manage the univariate regressor basis initialization for all
%   dependent modules. This takes care of managing during initialization 
%   the necessary univariate basis parameters. 
%   (PolyTypes,PolyTypesParams,PolyTypesAB)
%   A thin wrapper to the present function is to be implemented in place of
%   uq_PCE_initialize_process_basis (with the purpose of replacing it)
%   and uq_LRA_initialize.
%
%   "Options" should contain the processed basis parameters.
%   "current_model" is assumed to know about its inputs already (so if
%   'Arbitrary' is requested PolyTypesAB can be constructed).

% In order to support initialization for multiple outputs:
if ~exist('meta_idx','var')
    meta_idx=1;
end

switch lower(current_model.Options.MetaType)
    case 'pce'
        MetaModel = current_model.PCE;
    case 'lra'
        MetaModel = current_model.LRA;
    case 'kriging'
        MetaModel = current_model.Kriging;
    case 'glam'
        MetaModel = struct();
    otherwise
        error('You requested basis initialization for a metamodel that does not support it.');
end

% In case of 'Custom' metamodel, the basis has been already defined to what 
% it should be. I take the PolyTypes and the PolyTypeParams from the basis
% definition directly.
if isfield(current_model.Internal,'Method') && strcmpi(current_model.Internal.Method,'custom')
    if isfield(MetaModel(meta_idx).Basis,'PolyTypes')
        Options.PolyTypes = MetaModel(meta_idx).Basis.PolyTypes;
    end
    if isfield(MetaModel(meta_idx).Basis,'PolyTypesParams')
        Options.PolyTypesParams = MetaModel(meta_idx).Basis.PolyTypesParams;
    end
end

%% POLY TYPES
% PolyTypes: contains manually specified polynomial values or 'auto'
[PolyTypes, Options] = uq_process_option(Options, 'PolyTypes', ...
                    uq_auto_retrieve_poly_types(current_model.Internal.Input));

if PolyTypes.Invalid
    error('PolyTypes must be a cell array of strings');
else
    MetaModel(meta_idx).Basis.PolyTypes = PolyTypes.Value;
end

%% POLY TYPE PARAMETERS
% Contains the parameters of the polynomials in a cell array of matrices
% when needed (Jacobi Laguerre and maybe later 'Custom')
[PolyTypesParams, Options] = uq_process_option(Options,...
                            'PolyTypesParams',...
                            cell(length(PolyTypes.Value),1),...
                             'cell');

% the maximum degree considered in the current model:
if isfield(current_model.Options, 'Degree')
    maxdeg = max(current_model.Options.Degree+1);
else
    switch lower(current_model.Options.MetaType)
        case 'pce'
            maxdeg = max(max(MetaModel(meta_idx).Basis.Indices))+1;
        case 'lra'
            maxdeg = MetaModel(meta_idx).Basis.Degree;
        case 'glam'
            maxdeg = 0;
            for ilam=1:4
                maxdeg = max(maxdeg,max(current_model.Internal.lam{ilam}.Degree));
            end
        otherwise
            error('You specified a univariate basis with undefined maximum degree.');    
    end    
end

% Some error checks to enforce a rational treatment of the basis
% construction management when the user defined the "PolyTypes"
if (~PolyTypes.Missing)
    % In case we only have Hermite and Legendre the parameters are not 
    % needed and can be skipped. 
    if(PolyTypesParams.Invalid)
        error('PolyTypesParams must be a cell array of matrices.');
    end

    % What happens when the parameters are not explicitly set:
    % ---------------------------------------------------------
    % In case Jacobi and Laguerre polynomials are not used,
    % the parameters are redundant and it should be possible
    % to skip them (and have backwards compatible code).
    if PolyTypesParams.Missing
        if any(ismember(lower(MetaModel(meta_idx).Basis.PolyTypes),{'jacobi','laguerre'})) == 0 
            % In any case, I keep that array the same size as the number of polynomials
            % for consistency.
            MetaModel(meta_idx).Basis.PolyTypesParams = PolyTypesParams.Value;
        else
            error('You have speciffied Laguerre or Jacobi polynomial families but no corresponding parameters for the custom basis!');
        end
    end
else
    % Try to loop over the polytypes and see if we have the Laguerre or
    % Jacobi with corresponding Gamma or Beta. If yes then take the
    % parameters from the Marginals. Otherwise, throw error since the
    % polynomial names do not define anything.
    for kk=1:length(PolyTypes.Value)
        if strcmpi( current_model.Internal.Input.Marginals(kk).Type,'gamma') ...
                && strcmpi(PolyTypes.Value(kk),'laguerre') 
            PolyTypesParams.Value{kk} = current_model.Internal.Input.Marginals(kk).Parameters;
        end
        if strcmpi( current_model.Internal.Input.Marginals(kk).Type,'beta') ...
                && strcmpi(PolyTypes.Value(kk),'jacobi') 
            PolyTypesParams.Value{kk} = current_model.Internal.Input.Marginals(kk).Parameters;
        end
        if strcmpi( current_model.Internal.Input.Marginals(kk).Type , 'constant')
            % The value of the constant marginal:
            PolyTypesParams.Value{kk} = current_model.Internal.Input.Marginals(kk).Parameters;
        end
        %% ADD HERE PROPER HANDLING OF KS VARIABLES
        if strcmpi( current_model.Internal.Input.Marginals(kk).Type , 'KS')
            % The value of the constant marginal:
            PolyTypesParams.Value{kk} = current_model.Internal.Input.Marginals(kk).Parameters;
        end
    end
end
% The user wants the recurrence coefficients
% computed numerically and has chosen 'arbitrary' for PolyTypes
for kk = 1:length(PolyTypes.Value)

    % This is a potentially arbitrary weight function
    % to calculate the recurrence terms for:
    if any(strcmpi(PolyTypes.Value(kk),{'arbitrary','fourier'}))
        % The PDF:
        marginal = current_model.Internal.Input.Marginals(kk);

        % The parameters and name of the PDF:
        pdfname = marginal.Type;
        pdfparameters = marginal.Parameters;
        if isfield(marginal, 'Options')
            pdfparameters = [pdfparameters, marginal.Options];
        end

        pdfFun = @(x) uq_all_pdf(x,marginal);
        cdfFun = @(x) uq_all_cdf(x,marginal);
        invcdfFun = @(x) uq_all_invcdf(x,marginal);

        custom(1).pdfname = pdfname;
        custom(1).pdf = @(X) pdfFun(X);
        custom(1).invcdf = @(X) invcdfFun(X);
        custom(1).cdf = @(X) cdfFun(X,pdfparameters);
        custom(1).bounds = [invcdfFun(0) invcdfFun(1)];
        custom(1).parameters = pdfparameters;

        AB = uq_poly_rec_coeffs(maxdeg, 'arbitrary', custom);
        MetaModel(meta_idx).Basis.PolyTypesAB{kk} = AB;


        if strcmpi(PolyTypes.Value(kk),'fourier')
            % To allow for more general spectral representations in the
            % future, the parameters field is called internally
            % "SpectralParams" but lets the user only set the period
            % externally! It is important for custom PCE to discriminate
            % these cases at the moment:
            if isfield(PolyTypesParams.Value{kk},'SpectralParams')
                custom(1).SpectralParams = PolyTypesParams.Value{kk}.SpectralParams;
            else
                custom(1).SpectralParams.period = PolyTypesParams.Value{kk}.period;
                custom(1).SpectralParams.bounds = custom(1).bounds;
            end
        else
            PolyTypesParams.Value{kk} = custom;
        end
        
        MetaModel(meta_idx).Basis.PolyTypesParams{kk} = custom;
    
    else
        % This block takes care of the situations where the PolyType 
        % of the marginal is already one of the known types and
        % the recurrence coefficients do not have to be computed 
        % numerically. It also covers the situation where the type is 'arbitrary'
        % and there are pdf,cdf,invcdf,bounds set directly by the user in 
        % the script through proper use of 
        %   1) metaopts.PolyTypes and metaopts.PolyTypesParams
        %   2) or set in the Input.Marginals
        MetaModel(meta_idx).Basis.PolyTypesParams{kk} = PolyTypesParams.Value{kk};
        MetaModel(meta_idx).Basis.PolyTypes{kk} = PolyTypes.Value{kk};
        MetaModel(meta_idx).Basis.PolyTypesAB{kk} = ...
            uq_poly_rec_coeffs(maxdeg, ...
                    PolyTypes.Value{kk} ,...
                    PolyTypesParams.Value{kk} );
    end
end

% We need to return directly to the metamodel structure in order to enforce
% consistency. Make module specific changes either in the initialization
% routine or write the basis 
switch lower(current_model.Options.MetaType)
    case 'pce'
        current_model.PCE     = MetaModel;
    case 'lra'
        current_model.LRA     = MetaModel;
    case 'kriging'
        current_model.Kriging = MetaModel;
    case 'glam'
        current_model.Internal.Basis = MetaModel(meta_idx).Basis;
    otherwise
        error('You requested basis initialization for a metamodel that does not support it.');
end
