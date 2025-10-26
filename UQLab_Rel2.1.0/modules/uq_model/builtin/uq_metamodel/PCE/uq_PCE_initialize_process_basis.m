function [current_model, Options] = uq_PCE_initialize_process_basis(current_model,pce_idx,Options)
% [CURRENT_MODEL, OPTIONS] = UQ_PCE_INITIALIZE_PROCESS_BASIS(CURRENT_MODEL,PCE_IDX,OPTIONS)
%     Helper function to decouple the logic and error checking of basis
%     definition from the other components of PCE initialization.
%
% See also UQ_PCE_INITIALIZE, UQ_PCE_INITIALIZE_ARBITRARY_BASIS

% OUTPUT INDEX OF THE BASIS
if ~exist('pce_idx','var')
    pce_idx=1;
end

% In case of 'Custom' PCE, the basis has been already defined to what it
% should be. PolyTypes and PolyTypeParams are taken from the basis
% definition directly.
if strcmpi(current_model.Internal.Method,'custom')
    if isfield(current_model.PCE(pce_idx).Basis,'PolyTypes')
        Options.PolyTypes = current_model.PCE(pce_idx).Basis.PolyTypes;
    end
    if isfield(current_model.PCE(pce_idx).Basis,'PolyTypesParams')
        Options.PolyTypesParams = current_model.PCE(pce_idx).Basis.PolyTypesParams;
    end
end

%% POLY TYPES
% PolyTypes: contains manually specified polynomial values or 'auto'
[PolyTypes, Options] = uq_process_option(Options, 'PolyTypes', ...
                    uq_auto_retrieve_poly_types(current_model.Internal.Input));
% For constant variables, the PolyType must be "zero", even if the user
% specified something else
for kk = 1:length(PolyTypes.Value)
    if strcmpi(current_model.Internal.Input.Marginals(kk).Type , 'constant') ...
            && ~strcmpi(PolyTypes.Value{kk}, 'zero')
        warning('PolyTypes for constant variable %d changed from ''%s'' to ''zero''!', kk, PolyTypes.Value{kk});
        PolyTypes.Value{kk} = 'zero';        
    end
end
if PolyTypes.Invalid
    error('PolyTypes must be a cell array of strings');
else
    current_model.PCE(pce_idx).Basis.PolyTypes = PolyTypes.Value;
end


%% POLY TYPE PARAMETERS
% Contains the parameters of the polynomials in a cell array of matrices
% when needed (Jacobi Laguerre and period for Fourier or any other basis 
% parametrically defined)
[PolyTypesParams, Options] = uq_process_option(Options,...
                            'PolyTypesParams',...
                            cell(length(PolyTypes.Value),1),...
                             'cell');

% Check the maximal degree: either from the custom truncation or a given
% degree. Prefer a custom truncation to the degree.
if ~strcmpi(current_model.Internal.Method,'custom')
    TruncOpts = current_model.Internal.PCE.Basis.Truncation;
    Degree = current_model.Internal.PCE.Degree;
    % First try the custom truncation
    if isfield(TruncOpts,'Custom') && ~isempty(TruncOpts.Custom)
        % check if its an array
        if ~isa(TruncOpts.Custom,'double')
            fprintf('\n\nError: the custom truncation is not an integer array!\n');
            error('While setting up the PCE');
        end
        maxdeg = max(max(TruncOpts.Custom)) + 1;
        %     current_model.Internal.PCE.Degree = maxdeg-1;
        % Then try the degree field
    else
        maxdeg = max(Degree+1);
    end
else
    if isfield(current_model.Options, 'Degree')
        maxdeg = max(current_model.Options.Degree+1);
    else
        maxdeg = max(max(current_model.PCE(pce_idx).Basis.Indices))+1;
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
        if any(ismember(lower(current_model.PCE(pce_idx).Basis.PolyTypes),...
                {'jacobi','laguerre'})) == 0 
            % In any case, we keep that array the same size as the number 
            % of polynomials for consistency.
            current_model.PCE(pce_idx).Basis.PolyTypesParams = PolyTypesParams.Value;
        else
            error('You have specified Laguerre or Jacobi polynomial families but no corresponding parameters for the custom basis!');
        end
    end
else
    % Try to loop over the PolyTypes and see if we have the Laguerre or
    % Jacobi with corresponding Gamma or Beta. If yes then take the
    % parameters from the Marginals. Otherwise, throw error since the
    % polynomial names do not define anything.
    for kk=1:length(PolyTypes.Value)
        if strcmpi( current_model.Internal.Input.Marginals(kk).Type,'gamma') ...
                && strcmpi(PolyTypes.Value(kk),'laguerre') 
            PolyTypesParams.Value{kk} = ...
                current_model.Internal.Input.Marginals(kk).Parameters;
        end
        if strcmpi( current_model.Internal.Input.Marginals(kk).Type,'beta') ...
                && strcmpi(PolyTypes.Value(kk),'jacobi') 
            PolyTypesParams.Value{kk} = current_model.Internal.Input.Marginals(kk).Parameters;
        end
        %% ADD HERE PROPER HANDLING OF KS VARIABLES
        if strcmpi( current_model.Internal.Input.Marginals(kk).Type , 'KS')  
            PolyTypesParams.Value{kk} = current_model.Internal.Input.Marginals(kk).Parameters;
        end
    end
end
% Treatment of constant variables: uq_poly_marginals needs the constant
% value in the field PolyTypesParams, regardless whether or not PolyTypes
% was specified explicitly by the user.
for kk=1:length(PolyTypes.Value)
    if strcmpi( current_model.Internal.Input.Marginals(kk).Type , 'constant')  
        % The value of the constant marginal:
        PolyTypesParams.Value{kk} = current_model.Internal.Input.Marginals(kk).Parameters;
    end
end


% The user wants the recurrence coefficients computed numerically and 
% has chosen 'arbitrary' for PolyTypes
for kk = 1:length(PolyTypes.Value)

    % This is a potentially arbitrary weight function
    % to calculate the recurrence terms for:
    if any(strcmpi(PolyTypes.Value(kk),{'arbitrary','fourier'}))
        % The PDF:
        marginal = current_model.Internal.Input.Marginals(kk);
        
        % The 'custom' field contains the info about the marginal in a
        % convenient structure for future development.
        [AB, custom] = uq_PCE_initialize_arbitrary_basis(marginal,'stieltjes','polynomials',maxdeg);
        current_model.PCE(pce_idx).Basis.PolyTypesAB{kk} = AB;

        if strcmpi(PolyTypes.Value(kk),'fourier')
            % To allow for more general spectral representations in the
            % future, the parameters field is called internally
            % "SpectralParams" but allows the user only set the period.
            % It is important for custom PCE to discriminate these cases at
            % the moment:
            if isfield(PolyTypesParams.Value{kk},'SpectralParams')
                custom(1).SpectralParams = PolyTypesParams.Value{kk}.SpectralParams;
            else
                custom(1).SpectralParams.period = PolyTypesParams.Value{kk}.period;
                custom(1).SpectralParams.bounds = custom(1).bounds;
            end
        else
            PolyTypesParams.Value{kk} = custom;
        end
        
        current_model.PCE(pce_idx).Basis.PolyTypesParams{kk} = custom;
    elseif any(strcmpi(PolyTypes.Value(kk),{'arbitraryPrecomp'}))
        % Precomputed polynomials, AB already provided
        % assign AB
        AB = Options.PolyTypesAB{kk};
        current_model.PCE(pce_idx).Basis.PolyTypesAB{kk} = AB;
        % and Custom
        custom = Options.PolyCustom{kk};
        current_model.PCE(pce_idx).Basis.PolyTypesParams{kk} = custom;
        
        if kk == length(PolyTypes.Value)
            % last iteration
            % remove PolyTypesAB from Options structure
            Options = rmfield(Options,{'PolyTypesAB','PolyCustom'});
        end
    else
        % This block takes care of the situations where the PolyType 
        % of the marginal is already one of the known types and
        % the recurrence coefficients do not have to be computed 
        % numerically. It also covers the situation where the type is 'arbitrary'
        % and there are pdf,cdf,invcdf,bounds set directly by the user in 
        % the script through proper use of 
        %   1) metaopts.PolyTypes and metaopts.PolyTypesParams
        %   2) or set in the Input.Marginals
        current_model.PCE(pce_idx).Basis.PolyTypesParams{kk} = PolyTypesParams.Value{kk};
        current_model.PCE(pce_idx).Basis.PolyTypes{kk} = PolyTypes.Value{kk};
        current_model.PCE(pce_idx).Basis.PolyTypesAB{kk} = ...
            uq_poly_rec_coeffs(maxdeg-1, ...
                    PolyTypes.Value{kk} ,...
                    PolyTypesParams.Value{kk} );
    end
end

