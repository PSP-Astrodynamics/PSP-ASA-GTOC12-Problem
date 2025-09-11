function [X, U, u, W] = uq_getExpDesignSample(current_model, varargin)
% function [X, U, u, W] = UQ_GETEXPDESIGNSAMPLE(current_model,varargin):
% get an experimental design and related information for the given
% metamodelling type. The output arguments [X, U, u, W], when defined,
% represent the ED in the original space X, the corresponding ED in the
% reduced space U, the unit hypercube sample u and the quadrature weight
% (if used) W.

%% Argument and consistency checks

% make sure the model is of "uq_metamodel" type.
if ~strcmp(current_model.Type, 'uq_metamodel')
    error('Error, uq_getExpDesignSample is not defined for a model of type %s\n', current_model.Type);
end

%% Retrieve of the experimental design options:
EDOpts = current_model.ExpDesign;
% Sampling scheme:
sampling = EDOpts.Sampling;

%% first retrieve the poly types. If not specified by the user as an option,
% retrieve them as a function of the current_input module
if any(strcmpi(current_model.MetaType,{'pce','lra','glam','spce'}))
    switch lower(current_model.MetaType)
        case 'pce'
            Basis = current_model.PCE(1).Basis;
        case 'lra'
            Basis = current_model.LRA(1).Basis;
        case 'glam'
            Basis = current_model.Internal.Basis; 
        case 'spce'
            Basis.PolyTypes = current_model.Internal.SPCE.Basis.InputPolyTypes; 
            Basis.PolyTypesParams = current_model.Internal.SPCE.Basis.InputPolyTypesParams; 
    end
    [PolyMarginals, PolyCopula] = uq_poly_marginals(Basis.PolyTypes, Basis.PolyTypesParams);
end

%% generation of the experimental design based both on the input and the metamodel
% there are several different experimental design strategies, developed on the unit
% hypercube of dimension M. Available methods, right now, are:
% LHS - Latin Hypercube Sampling
% MC  - Plain Monte Carlo
% Sobol - Sobol pseudorandom series
% Halton - Halton minimum discrepancy series
% user - user-specified experimental design (directly by variables)
% data - user-specified experimental design (loaded from .mat files)
% gaussquad - standard gaussian quadrature
% smolyakquad - Smolyak sparse grid with gaussian quadrature

switch lower(sampling)
    case {'data', 'user'}
        % get the samples from the specified arrays
        switch(lower(sampling))
            case {'data','user'}
                X = current_model.ExpDesign.X;
                if isfield(current_model.ExpDesign, 'U')
                    U = current_model.ExpDesign.U;
                    u = U;
                else
                    U = X;
                    u = U;
                end
        end
        
        % Consistency check on the dimensions of the sample
        if size(X,2) ~= current_model.Internal.Runtime.M
            error('Error: the length of the provided experimental design is inconsistent with the input (%d instead of %d)\n', ...
                size(X,2), current_model.Internal.Runtime.M);
        end
        
        % Number of samples in the exp design
        current_model.ExpDesign.NSamples = size(X,1);
        
    case {'quadrature'}
        % gaussian quadrature sampling
        Quadrature = current_model.Internal.PCE(1).Quadrature;
        levels = Quadrature.Level;
        
        % Switch over full or sparse quadrature
        switch(lower(Quadrature.Type))
            case 'full'
                % get nodes and weights for the polynomial types directly
                % tensor-product gaussian quadrature
                [u, W] = uq_quadrature_nodes_weights_gauss( levels,...
                    current_model.PCE(1).Basis.PolyTypes, ...
                    current_model.PCE(1).Basis.PolyTypesParams,....
                    current_model.PCE(1).Basis.PolyTypesAB);
            case 'smolyak'
                % use Smolyak' sparse grids to combine lower order gaussian
                % quadratures and get a sparser ED
                [u, W] = uq_quadrature_nodes_weights_smolyak(levels,...
                    current_model.PCE(1).Basis.PolyTypes, ...
                    current_model.PCE(1).Basis.PolyTypesParams,...
                    current_model.PCE(1).Basis.PolyTypesAB);
        end
        
        % Warn the user when there are NaNs or infinites. This will need to
        % be updated in a future release to properly handle them.
        if current_model.Internal.Display>1 && any(any(isnan([u W]))) || any(any(isinf([u W])))
            warning('Numerical quadrature returned some invalid values!')
        end
        % Set the number of ExpDesign samples (depends on quadrature
        % scheme)
        current_model.ExpDesign.NSamples = size(u,1);
        
        % Generate a private input object handle isoprobabilistic
        % transforms easily
        Options.Marginals = PolyMarginals;
        Options.Copula = PolyCopula;
        Options.Name = 'ED_Input';
        % Make sure to set the input as "private" to avoid adding it to the
        % main UQLab session
        ED_Input = uq_createInput(Options, '-private');
        current_model.ExpDesign.ED_Input = ED_Input;
    case {'sequential'}
        % for sse check varargin for initial sample argument
        if strcmpi(current_model.MetaType,'sse')
            % at the initial stage of SSE enrichment, sample twice
            % NEnrich with LHS
            nsamples = 2*current_model.ExpDesign.NEnrich;
        else
            error('Sequential sampling only supported for SSE')
        end
        
        % Retrieve the ED_Input object and the number of samples
        ED_Input = current_model.ExpDesign.ED_Input;
        
        % Sample the unit hypercube with the correct sampling strategy
        u = uq_getSample(ED_Input,nsamples, 'lhs');
    otherwise
        % In any other case, there is a need to sample from the private
        % ED_Input object created during initialization.
        
        % Retrieve the ED_Input object and the number of samples
        ED_Input = current_model.ExpDesign.ED_Input;
  
        % number of samples:
        nsamples = EDOpts.NSamples;
        
        % Sample the unit hypercube with the correct sampling strategy
        u = uq_getSample(ED_Input,nsamples, sampling);
end


%% Transform the generated sample to the original space X (isoprobabilistic transform)

% Switch over the possible metamodelling types
switch lower(current_model.MetaType)
    case {'pce','lra','glam','spce'}
        % retrieve the input model used to build the metamodel
        current_input = current_model.Internal.Input;
        % Polynomial Chaos Expansion/LRA
        % Only perform the transform if a sampling (random or
        % quadrature-based) was performed
        if ~any(strcmpi(sampling, {'user', 'data'}))
            % ED in the reduced/auxiliary space
            U = uq_IsopTransform(u,ED_Input.Marginals, PolyMarginals);
            % ED in the original space
            X = uq_GeneralIsopTransform(U, PolyMarginals, PolyCopula, current_input.Marginals, current_input.Copula);
            if any(isnan(X(:))) || any(isinf(X(:)))
                warning('The uq_GeneralIsopTransform returned NaN or Infs!')
            end
        else
            % In case the sample was provided during initialization, it
            % needs to be transformed into the suitable reduced space
            U = uq_GeneralIsopTransform(X, current_input.Marginals, current_input.Copula, PolyMarginals, PolyCopula);
            % dummy "u" value in this case is not used, as no sampling of
            % the unit hypercube was performed.
            u = U;
        end
        
        % In case only three output variables are requested, assign 'W' as
        % third output argument instead of "u"
        if nargout < 4 && exist('W', 'var')
            u = W;
        end
        
    case {'kriging', 'svr','svc'}
        % Kriging, SVR or SVC
        % retrieve the input model IF it exists
        if isfield(current_model.Internal, 'Input') && ...
                ~isempty(current_model.Internal.Input)
            current_input = current_model.Internal.Input;
        end
        
        if any(strcmpi(current_model.ExpDesign.Sampling, {'data', 'user'}))
            % no action required if the ED is specified  manually
        else
            % Map the unit hypercube sample u to the original space if sampling was performed
            X = uq_GeneralIsopTransform(u, ED_Input.Marginals, ...
                ED_Input.Copula, current_input.Marginals, current_input.Copula);
        end
        SCALING = current_model.Internal.Scaling;
        SCALING_BOOL = isa(SCALING, 'double') || isa(SCALING, 'logical') || isa(SCALING, 'int');
        
        if SCALING_BOOL && SCALING
            muX = current_model.Internal.ExpDesign.muX;
            sigmaX = current_model.Internal.ExpDesign.sigmaX;
            U = bsxfun(@rdivide,(bsxfun(@minus,X,muX)), sigmaX);
        elseif SCALING_BOOL && ~SCALING
            U = X;
        end
        
        if ~SCALING_BOOL
            % In that case SCALING is an INPUT object. An isoprobabilistic
            % transform is performed from:
            % current_model.Internal.Input
            % to:
            % current_model.Internal.Scaling
            U =  uq_GeneralIsopTransform(X,...
                current_model.Internal.Input.Marginals, current_model.Internal.Input.Copula,...
                SCALING.Marginals, SCALING.Copula);
        end
        
    case 'pck'
        % retrieve the input model used to build the metamodel
        current_input = current_model.Internal.Input;
        %in case of PCK, the input domain is defined, hence we can sample
        %from it if there is no experimental design given already
        if isfield(current_model.ExpDesign, 'X')
            X = current_model.ExpDesign.X;
        else
            X = uq_getSample(current_input, current_model.ExpDesign.NSamples, current_model.ExpDesign.Sampling);
        end
        U = X;
        
    case 'sse'
        % retrieve the input model
        current_input = current_model.Internal.Input;
        
        % Retrieve the ED_Input object and the number of samples
        ED_Input = current_model.ExpDesign.ED_Input;
        
        if any(strcmpi(current_model.ExpDesign.Sampling, {'data', 'user'}))
            % Map the specified sample to the unit hypercube
            u = uq_GeneralIsopTransform(X, current_input.Marginals, ...
                current_input.Copula, ED_Input.Marginals, ED_Input.Copula);
        else
            % Map the unit hypercube sample u to the original space if sampling was performed
            X = uq_GeneralIsopTransform(u, ED_Input.Marginals, ...
                ED_Input.Copula, current_input.Marginals, current_input.Copula);
        end
        U = u;
        
    otherwise
        % neither Kriging, PCE or PCK metamodel: skip scaling
        U = u;
        X = U;
end

%% Assign the remaining dummy variables if necessary
if ~exist('U', 'var')
    U = X;
end

if ~exist('u', 'var')
    u = X;
end
