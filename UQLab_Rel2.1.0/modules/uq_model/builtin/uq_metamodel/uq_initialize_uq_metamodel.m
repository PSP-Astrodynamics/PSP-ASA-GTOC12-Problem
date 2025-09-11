function success = uq_initialize_uq_metamodel(module)
% UQ_INITIALIZE_UQ_METAMODEL: initializes the UQ metamodel infrastructure on the basis of
% the specified module

%% argument and consistency checks
% if the module is not specified on the command line, retrieve the default
if exist('module', 'var')
    current_model = uq_getModel(module);
else
    current_model = uq_getModel;
end

% initialize the success status to 0
success = 0;

% retrieve the options (new structure)
Options = current_model.Options;


% some checks: the model must be of "uq_metamodel" type
if ~strcmp(current_model.Type, 'uq_metamodel')
    success = -1;
    error('uq_initialize_uq_metamodel error: you must initialize a uq_metamodel type object, not a % one!!', module.Type);
end
% make sure that some metamodel type has been selected
if ~isfield(Options,'MetaType') || isempty(Options.MetaType)
    error('Could not initialize the metamodelling tool without defining a metamodel type!')
end

MetaTypeProp = uq_addprop(current_model, 'MetaType', Options.MetaType);
MetaTypeProp.Hidden = true;

%% VERBOSITY LEVEL
DISPLAYDefaults = 1; % Only essential information

[Options, current_model.Internal] = uq_initialize_display(Options, current_model.Internal);

DisplayLevel = current_model.Internal.Display;
if DisplayLevel > 1
    fprintf('Initializing the metamodeling infrastructure... \n');
end

%% VALIDATION SET
[ValSet, Options] = uq_process_option(Options, 'ValidationSet');
ValFlag = false;
if ~ValSet.Missing
    VSet = ValSet.Value;
    if ~isfield(VSet(1),'X') || ~isfield(VSet(1),'Y')
        error('The provided validation set is invalid');
    else
        ValFlag = true;
        current_model.Internal.ValidationSet = VSet;
    end
end

%% MANUAL DEFINITION OF PCE (predictor only)
% in case we want to manually specify the PCE basis + coeff only and use
% predictor without calculating, provide all the necessary information
if isequal(lower(Options.MetaType), 'pce')
    if isfield(Options, 'Method') && isequal(lower(Options.Method), 'custom')
        uq_PCE_initialize_custom(current_model, Options);
        current_model.Internal.Runtime.isCalculated = true;
        return;
    end
end

%% MANUAL DEFINITION OF LRA (predictor only)
% in case we want to manually specify the LRA basis + coeff only and use
% predictor without calculating, provide all the necessary information
if isequal(lower(Options.MetaType), 'lra')
    if isfield(Options, 'Method') && isequal(lower(Options.Method), 'custom')
        success = uq_LRA_initialize_custom(current_model, Options);
        current_model.Internal.Runtime.isCalculated = success;
        return;
    end
end

%% MANUAL DEFINITION OF KRIGING (predictor-only mode)
% If we want to manually specify Kriging parameters and use it as predictor
% without first calculating it, provide all the necessary information
if isequal(lower(Options.MetaType),'kriging')
    if isfield(Options,'Kriging') && ~isempty(Options.Kriging)
        uq_Kriging_initialize_custom(current_model,Options);
        current_model.Internal.Runtime.isCalculated = true;
        % now return, as no further initialization is needed
        return
    end
end

%% MANUAL DEFINITION OF GLAM (predictor-only mode)
% If we want to manually specify GLaM parameters and use it as predictor
% without first calculating it, provide all the necessary information
if isequal(lower(Options.MetaType),'glam')
    if isfield(Options,'Lambda') && isfield(Options,'Method') && isequal(lower(Options.Method), 'custom')
        uq_GLaM_initialize_custom(current_model,Options);
        % now return, as no further initialization is needed
        return
    end
end

%% EXPERIMENTAL DESIGN
% General ED-related consistency checks
% 1) An empty ExpDesign field is generally not allowed
if ~isfield(Options,'ExpDesign') || isempty(Options.ExpDesign)
    if ~isfield(Options, 'Method')||~any(strcmpi(Options.Method, {'quadrature'})) % ## This  is PCE-specific
        % ## also if no experimental design is defined (eg in Kriging
        % metaopts)  the error that the user gets is misleading (Reference
        % to non-existent field 'Method'.)
        error('Could not initialize the metamodelling tool without defining an experimental design!')
    else
        Options.ExpDesign.Sampling = Options.Method;
        Options.ExpDesign.NSamples = -1;
    end
end
% 2) Return an error if a datafile is set but no sampling method has been
% selected
if isfield(Options.ExpDesign, 'DataFile')
    if ~isfield(Options.ExpDesign,'Sampling') || isempty(Options.ExpDesign) ...
            || strcmpi(Options.ExpDesign.Sampling, 'data')
        Options.ExpDesign.Sampling = 'data';
    else
        error('A DataFile has been provided but the sampling method is not ''data''!');
    end
end
% 3) Return an error if X,Y have been set and the sampling method is not
% 'user'
if xor(isfield(Options.ExpDesign, 'X'), isfield(Options.ExpDesign, 'Y')) % if only one of X, Y is specified
    error('Both X and Y have to be provided if you want to manually specify an experimental design!')
end
if isfield(Options.ExpDesign, 'X') && isfield(Options.ExpDesign, 'Y')
    if ~isfield(Options.ExpDesign,'Sampling') || isempty(Options.ExpDesign) ...
            || strcmpi(Options.ExpDesign.Sampling, 'user')
        Options.ExpDesign.Sampling = 'User';
    else
        error(['Both a sampling strategy and a set of experimental design points were provided!',...
            sprintf('\n'), ...
            'The sampling method needs to be set to ''user'' for using manually specified X,Y.']);
    end
end
% 4) Assign the default sampling method if none is set
if ~isfield(Options.ExpDesign,'Sampling') ||...
        isempty(Options.ExpDesign.Sampling)
    
    % if a number of samples is given assign a default Sampling method
    Options.ExpDesign.Sampling = 'LHS';
end

% 5) Add the property ExpDesign to current_model
uq_addprop(current_model, 'ExpDesign', Options.ExpDesign);

% 6) Pre-postprocessing of the ED
% simple, function-handle based -> should be updated to models
if isfield(Options.ExpDesign, 'Preproc')
    % preprocY
    if isfield(Options.ExpDesign.Preproc, 'PreY')
        clear preYopts;
        switch class(Options.ExpDesign.Preproc.PreY)
            case 'function_handle'
                %current_model.ExpDesign.PreprocY = Options.ExpDesign.Preproc.PreY;
                preYopts.fHandle = Options.ExpDesign.Preproc.PreY;
            case 'char'
                preYopts.mFile = Options.ExpDesign.Preproc.PreY;
        end
        % add options if specified
        if isfield(Options.ExpDesign.Preproc,'PreYPar')
            preYopts.Parameters = Options.ExpDesign.Preproc.PreYPar;
            current_model.ExpDesign.PreYPar = Options.ExpDesign.Preproc.PreYPar;
        end
        preYopts.isVectorized = 1;
        current_model.ExpDesign.PreprocY = uq_createModel(preYopts, '-private');
        
    end
    % postprocY
    if isfield(Options.ExpDesign.Preproc, 'PostY')
        clear postYopts;
        switch class(Options.ExpDesign.Preproc.PostY)
            case 'function_handle'
                %current_model.ExpDesign.PreprocY = Options.ExpDesign.Preproc.PreY;
                postYopts.fHandle = Options.ExpDesign.Preproc.PostY;
            case 'char'
                postYopts.mFile = Options.ExpDesign.Preproc.PostY;
        end
        postYopts.isVectorized = true;
        current_model.ExpDesign.PostprocY = uq_createModel(postYopts, '-private');
    end
end




% Parse Data- or User-specified ED
USER_SPECIFIED_ED =  any(strcmpi(Options.ExpDesign.Sampling, {'user', 'data'}));
if USER_SPECIFIED_ED
    % 1) Case of 'Data'
    if strcmpi(Options.ExpDesign.Sampling, 'data')
        % make sure that DataFile has been defined
        if ~isfield(current_model.ExpDesign,'DataFile') || ...
                isempty(current_model.ExpDesign.DataFile)
            error('No DataFile has been defined!')
        end
        
        % Try to load the data from the mat file
        fname = current_model.ExpDesign.DataFile;
        try
            LoadedData = load(fname);
            % make sure that current_model.ExpDesign.X,Y have been defined
            if ~isfield(LoadedData,'X') || ...
                    isempty(LoadedData.X)
                error('The experimental design method is set to ''data'', but no ''X'' field was found in the specified file');
            end
            if ~isfield(LoadedData,'Y') || ...
                    isempty(LoadedData.Y)
                error('The experimental design method is set to ''data'', but no ''Y'' field was found in the specified file');
            end
            current_model.ExpDesign.X = LoadedData.X;
            current_model.ExpDesign.Y = LoadedData.Y;
        catch e
            error('There was an error while trying to load the Experimental Design from the DataFile! Recorded error: \n%s',e.message);
        end
        
    end
    
    
    % 2) Case of 'User'
    if strcmpi(Options.ExpDesign.Sampling,'user')
        
        % make sure that current_model.ExpDesign.X,Y have been defined
        if ~isfield(current_model.ExpDesign,'X') || ...
                isempty(current_model.ExpDesign.X)
            error('The experimental design method is set to user-defined but there is no .ExpDesign.X defined!')
        end
        if ~isfield(current_model.ExpDesign,'Y') || ...
                isempty(current_model.ExpDesign.Y)
            error('The experimental design method is set to user-defined but there is no .ExpDesign.Y defined!')
        end
        
    end
    
    
    % validate dimensions
    % ## This check should take place inside the initialization of each
    % module because this check makes sense only when an input module has defined and we want 
    % to make sure that the length of Input.Marginals is consistent with
    % the number of rows in ExpDesign.X
    
    %    % Check that the X dimension is consistent with M
    %     if size(current_model.ExpDesign.X,2) ~= M
    %         error('Experimental design : X dimension error size(X,2) = %d, M = %d (length of Input Marginals)!\n', size(X,2), M);
    %     end
    
    % number of data points
    N = size(current_model.ExpDesign.X,1);
    if size(current_model.ExpDesign.Y,1) ~= N
        error(sprintf('Experimental design dimension error : size(X,1) = %d ,size(Y,1) = %d \n', N, size(current_model.ExpDesign.Y,1)));
    end
    
    % Store Number of samples
    current_model.ExpDesign.NSamples = N;
    % Find the input dimension based on the experimental design dimensions size
    M = size(current_model.ExpDesign.X,2);
    current_model.Internal.Runtime.M = M;
    % Store the indices of non-constant variables (in this case all of
    % them)
    current_model.Internal.Runtime.MnonConst = M;
    current_model.Internal.Runtime.nonConstIdx = 1:M;
    
    % for SSE, create ED_Input object to transform user supplied sample to
    % the unit hypercube. SSE always requires an input object
    if strcmpi(Options.MetaType, 'sse')        
        % -Retrieve the Input object from the options
        if (~isfield(current_model.Internal,'Input')||isempty(current_model.Internal.Input))...
                && (~isfield(Options, 'Input') || isempty(Options.Input))
            % if no input is specified manually, get the currently selected one
            current_model.Internal.Input = uq_getInput;
        elseif isfield(Options, 'Input') && ~isempty(isfield(Options, 'Input'))
            current_model.Internal.Input = uq_getInput(Options.Input);
        end
        
        % generate the necessary marginals
        [Marginals(1:M).Type] = deal('Constant');
        [Marginals(1:M).Parameters] = deal(0.5);
        [Marginals(current_model.Internal.Input.nonConst).Type] = deal('Uniform');
        [Marginals(current_model.Internal.Input.nonConst).Parameters] = deal([0 1]);


        Copula.Type = 'Independent';
        Sampling.Method = current_model.ExpDesign.Sampling;
        inputopts.Marginals = Marginals;
        inputopts.Copula = Copula;
        inputopts.Sampling = Sampling;
        inputopts.Name = 'ED_Input';
        inputopts.Type = 'uq_default_input';
        % Now create the auxiliary input uq_input
        current_model.ExpDesign.ED_Input = uq_createInput(inputopts, '-private');
        
        % and turn off NEnrich
        current_model.ExpDesign.NEnrich = 0;

        % Get U and update current_model
        [~, ~, U] = uq_getExpDesignSample(current_model);
        current_model.ExpDesign.NSamples = size(U,1);
        current_model.ExpDesign.U = U;
    end
    
else % USER_SPECIFIED_ED = false (that is the ED needs to be generated)
    % In order to generate X,Y the following steps are required:
    % -Retrieve the Input object from the options
    if (~isfield(current_model.Internal,'Input')||isempty(current_model.Internal.Input))...
            && (~isfield(Options, 'Input') || isempty(Options.Input))
        % if no input is specified manually, get the currently selected one
        current_model.Internal.Input = uq_getInput;
    elseif isfield(Options, 'Input') && ~isempty(isfield(Options, 'Input'))
        current_model.Internal.Input = uq_getInput(Options.Input);
    end
    % -Initialize the model FullModel
    %   check that a full model is specified
    if ~isfield(Options, 'FullModel') || isempty(Options.FullModel)
        current_model.Internal.FullModel = uq_getModel;
        if isempty(current_model.Internal.FullModel)
            error('At least a model object must be defined in UQLab for the selected sampling strategy!');
        end
    else
        current_model.Internal.FullModel = uq_getModel(Options.FullModel);
    end
    
    % -Initialize sampling and ED_Input
    switch lower(current_model.ExpDesign.Sampling)
        case {'lhs', 'mc', 'sobol', 'halton', 'simplelhs', 'grid', 'sequential'}
            
            % sequential is only possible with SSE, sample will be added
            % sequentially during SSE construction
            if strcmpi(current_model.ExpDesign.Sampling, 'sequential') && ~strcmpi(Options.MetaType, 'sse')
                error('Sequential sampling is only possible with SSE!')
            end
            
            % number of samples in the exp design (only if not doing quadrature)
            if ~isfield(current_model.ExpDesign,'NSamples') ||...
                    isempty(current_model.ExpDesign.NSamples)
                % ## This looks like PCE-specific:
                if isfield(Options, 'Method') && ~any(strcmpi(Options.Method, {'quadrature', 'gaussquad', 'smolyakquad'}))
                    error('A type of Experimental Design Sampling or number of Experimental Design samples is needed!')
                end
            end
            % Retrieve the input dimension from the Input.Marginals' length
            M = length(current_model.Internal.Input.Marginals);
            % generate the necessary marginals
            [Marginals(1:M).Type] = deal('Constant');
            [Marginals(1:M).Parameters] = deal(0.5);
            [Marginals(current_model.Internal.Input.nonConst).Type] = deal('Uniform');
            [Marginals(current_model.Internal.Input.nonConst).Parameters] = deal([0 1]);
            

            Copula.Type = 'Independent';
            Sampling.Method = current_model.ExpDesign.Sampling;
            inputopts.Marginals = Marginals;
            inputopts.Copula = Copula;
            inputopts.Sampling = Sampling;
            inputopts.Name = 'ED_Input';
            inputopts.Type = 'uq_default_input';
            % Now create the auxiliary input module uq_input
            current_model.ExpDesign.ED_Input = uq_createInput(inputopts, '-private');
            
        case 'quadrature'
            % ## somehow the input dimension (M) should be retrieved if this
            % stays here
            M = length(current_model.Internal.Input.Marginals);
            if strcmpi(current_model.MetaType, 'kriging')
                warning('The requested sampling method "%s" is not recommended for Kriging!', current_model.ExpDesign.Sampling);
            end
            
        otherwise
            error('The requested sampling method "%s" was not recognized! Metamodelling will not be possible.', current_model.ExpDesign.Sampling);
    end
    
    % sse-specifics
    if strcmpi(Options.MetaType,'sse')
        % Experimental design defaults
        ExpDesignDefaults = current_model.ExpDesign;
        ExpDesignDefaults.NEnrich = 10;
        % sequential enrichment?
        if strcmpi(current_model.ExpDesign.Sampling, 'sequential')
            % sequential sampling requested
            ExpDesignDefaults.Enrichment = @(obj, currBounds, NEnrich) uq_SSE_enrichment_uniform(obj, currBounds, NEnrich);
            ExpDesignDefaults.NEnrich = 10;
        end
        
        % Process experimental design options
        [ExpDesign, Options] = uq_process_option(Options, 'ExpDesign', ExpDesignDefaults);
        if ExpDesign.Invalid
            error('The ExpDesign field must be a structure!')
        else
            current_model.ExpDesign = ExpDesign.Value;
        end 
        
        if strcmpi(current_model.ExpDesign.Sampling, 'sequential')
            % Sequential sampling, sample only smaller initial ED
            [X, ~, U] = uq_getExpDesignSample(current_model,'initialEnrich');
        else
            % No sequential sampling, get X and update current_model
            [X, ~, U] = uq_getExpDesignSample(current_model);
            current_model.ExpDesign.NSamples = size(X,1);
        end            
        
        % Get Y and update current_model
        Y = uq_eval_ExpDesign(current_model, X);

        % check for sequential with with multiple outputs
        if size(Y,2) > 1 && strcmpi(current_model.ExpDesign.Sampling, 'sequential')
            error('SSE does not currently support sequential experimental designs with multiple outputs.')
        end

        % Store
        current_model.ExpDesign.X = X;
        current_model.ExpDesign.U = U;
        current_model.ExpDesign.Y = Y;

        % Update the number of outputs of the model and update current_model
        M = size(X,2);
    end
    
    % Book-keeping of non-constant variables
    % Find the non-constant variables
    if isprop(current_model.Internal.Input, 'nonConst') && ~isempty(current_model.Internal.Input.nonConst)
        nonConst = current_model.Internal.Input.nonConst;
    else
        %  find the constant marginals
        Types = {current_model.Internal.Input.Marginals(:).Type}; % 1x3 cell array of types
        % get all the marginals that are non-constant
        nonConst =  find(~strcmpi(Types, 'constant'));
    end
    % Store the non-constant variables
    current_model.Internal.Runtime.MnonConst = numel(nonConst);
    current_model.Internal.Runtime.nonConstIdx = nonConst;
end
% Store the input dimension
current_model.Internal.Runtime.M = M;

%% EXECUTE MODULE-SPECIFIC INITIALIZATION
switch lower(Options.MetaType)
    case 'pce'
        uq_PCE_initialize( current_model ) ;
        
    case 'kriging'
        uq_Kriging_initialize( current_model ) ;
        
    case 'lra'
        uq_LRA_initialize(current_model);
    
    case 'pck'
        uq_PCK_initialize( current_model );
        
    case 'svr'
        uq_SVR_initialize( current_model );

    case 'svc'
        uq_SVC_initialize( current_model );
        
    case 'sse'
        uq_SSE_initialize( current_model );
        
    case 'glam'
        uq_GLaM_initialize( current_model );
       
    case 'spce'
        uq_SPCE_initialize( current_model );
        
    otherwise
        error('Unknown metamodel type "%s"!',Options.MetaType)
end

% Add the isCalculated property
current_model.Internal.Runtime.isCalculated = false;

% Add isStochastic property
if ~isprop(current_model,'isStochastic')
    uq_addprop(current_model, 'isStochastic', false);
end

% Add the Error property
if ~isprop(current_model,'Error')
    uq_addprop(current_model, 'Error');
end

success = uq_calculateMetamodel(current_model);
current_model.Internal.Runtime.isCalculated = success;

%% CALCULATE A VALIDATION SET ERROR
if ValFlag
    VSet = current_model.Internal.ValidationSet;
    
    % calculate the validation metrics for stochastic emulators
    if current_model.isStochastic
        metrics=uq_evalStochSimMetrics(current_model,VSet.X,VSet.Y);
        if isstruct(metrics)
            fields = fieldnames(metrics);
            for ii = 1:length(fields)
                fn = fields{ii};
                for oo = 1: current_model.Internal.Runtime.Nout
                    current_model.Error(oo).Val.(fn)=metrics(oo).(fn);
                end
            end
        elseif isnumeric(metrics)
            for oo = 1: length(metrics)
                current_model.Error(oo).Val=metrics(oo);
            end
        end
        
    % calculate the validation normalized MSE for deterministic emulators    
    else
        YMetaVal = uq_evalModel(current_model, VSet.X);
        ValError = mean((YMetaVal-VSet.Y).^2)./var(VSet.Y,1);
        for oo = 1: length(current_model.Error)
            current_model.Error(oo).Val = ValError(oo);
        end
    end
end

%% REPORT THE WARNINGS, IF ANY
if DisplayLevel > 1
   FILTERS.Type = '*';
   uq_reportEvents(current_model, FILTERS);
end
