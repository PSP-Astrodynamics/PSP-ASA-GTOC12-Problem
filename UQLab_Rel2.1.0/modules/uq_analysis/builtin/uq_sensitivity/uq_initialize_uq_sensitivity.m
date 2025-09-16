function success = uq_initialize_uq_sensitivity(current_analysis)
% SUCCESS = UQ_INITIALIZE_UQ_SENSITIVITY(ANALYSISOBJ): configure the
%     analysis object ANALYSISOBJ based on the user specified options.
%     Also the appropriate input/output structure of the ANALYSISOBJ object
%     and run the analysis.
%
% See also: UQ_SENSITIVITY,UQ_CORRELATION_INDICES,UQ_SRC_INDICES,UQ_COTTER_INDICES,
%           UQ_PERTURBATION_METHOD,UQ_MORRIS_INDICES,UQ_SOBOL_INDICES,
%           UQ_ANCOVA_INDICES, UQ_KUCHERENKO_INDICES, UQ_SHAPLEY_INDICES


%% INITIALIZATION AND RETRIEVAL OF THE REQUESTED OPTIONS
% User-specified options as given in uq_createAnalysis(Options)
Options = current_analysis.Options; 
% Processed options that will be assigned to the object after
% initialization
Internal = current_analysis.Internal; 

% Default to the full input distributions
FactorDefaults.Boundaries = 1; 
success = 0;



%% CHECK FOR USER DEFINED MODEL/INPUT
%  Retrieve the current ones if not defined

% MODEL
[opt, Options] = uq_process_option(Options, 'Model', uq_getModel);
Internal.Model = uq_getModel(opt.Value);

% INPUT
[opt, Options] = uq_process_option(Options, 'Input', uq_getInput);
Internal.Input = uq_getInput(opt.Value);
CurrentInput = Internal.Input;

% Determine the number of input variables from the following sources
% (ordered by priority):
% 1 - User-specified input object
% 2 - Options.M

% Define the methods, that do not need an input object
methods_noinput = {'Correlation','SRC','Borgonovo','Kucherenko'};

[opt, Options] = uq_process_option(Options, 'M', [], 'double');

if ~isempty(opt.Value)
    Internal.M = opt.Value;
    M = Internal.M;
    nonConst = 1:M;
else
    % throw error if input object is missing for non-allowed methods
    if isempty(CurrentInput) && ~any(strcmpi(Options.Method,methods_noinput))
        fprintf('\nError: It was not possible to determine the dimension of the problem.\n');
        fprintf('\nYou can fix this by taking one of the following actions:');
        fprintf('\n\t- Pass an input object in the analysis options (in Options.Input).');
        fprintf('\n\t- Create an input in UQLab prior to defining the sensitivity module.\n');
        error('While creating the sensitivity analysis module: problem dimension undefined.');
        
    % procedure if the input object is missing for allowed methods_noinput
    elseif isempty(CurrentInput) && any(strcmpi(Options.Method,methods_noinput))
        
        % create the path to the sample (done case by case bacause of
        % different capitalization)
        if strcmpi(Options.Method, methods_noinput(1))
            inputsample_path = sprintf('Options.Correlation.Sample.X');
        elseif strcmpi(Options.Method, methods_noinput(2))
            inputsample_path = sprintf('Options.SRC.Sample.X');
        elseif strcmpi(Options.Method, methods_noinput(3))
            inputsample_path = sprintf('Options.Borgonovo.Sample.X');
        elseif strcmpi(Options.Method, methods_noinput(4))
            inputsample_path = sprintf('Options.Kucherenko.Samples.X');
        end
        
        try % to investigate the input sample
            M = size(eval(inputsample_path),2);
            Internal.M = size(eval(inputsample_path),2);
        catch me
            fprintf('\nError: No input object or samples defined. Analysis cannot be performed.\n')
            rethrow(me)
        end
        
    % last chance
    else
        % M should be the length of the non-constants inputs or the length of
        % the Marginals themselves if for some reason Internal.Input.nonConst
        % field is not defined
        if isfield(Internal.Input, 'nonConst') || isprop(Internal.Input,'nonConst')
            nonConst = (Internal.Input.nonConst);
        else
            nonConst = 1:length(Internal.Input.Marginals);
        end
        M = length(Internal.Input.Marginals);
        Internal.M = length(Internal.Input.Marginals);
    end
    
    
end


%% COMMON INITIALIZATION

% Initialization flags for shared options
InitFactors = false;
InitBootstrap = false;

% Check if the inputs are independent
CorrelInputs = false;  % Assume independent inputs
if ~isempty(CurrentInput)
    if isfield(CurrentInput,'Copula') || isprop(CurrentInput,'Copula')
        checkGaussian = true;  % Also check independence in Gaussian copula
        CorrelInputs = ~uq_isIndependenceCopula(...
            CurrentInput.Copula,checkGaussian);
    end
end
% Retrieve the sensitivity method (DEFAULT: MC)
[Method, Options] = uq_process_option(Options, 'Method', 'src', 'char');
if Method.Missing || Method.Invalid
    error('\nAn analysis method should be provided.\n');
else
    % Set the appropriate method and the corresponding shared
    % initialization flags, if needed
    switch lower(Method.Value)
        case {'cotter'}
            Internal.Method = 'cotter';
            InitFactors = true;
            
        case {'morris'}
            Internal.Method = 'morris';
            InitFactors = true;
            
        case {'sobol'}
            if CorrelInputs
                fprintf('\nWarning: Sobol'' sensitivity analysis does not yield reliable results for correlated inputs!\n')
            end
            Internal.Method = 'sobol';
            InitBootstrap = true;
            
        case {'perturbation'}
            if CorrelInputs
                fprintf('\nWarning: Perturbation sensitivity analysis does not yield reliable results for correlated inputs!\n')
            end
            Internal.Method = 'perturbation';
            
        case {'src'}
            if CorrelInputs
                fprintf('\nWarning: SRC sensitivity analysis does not yield reliable results for correlated inputs!\n')
            end
            Internal.Method = 'SRC';
            
        case {'correlation'}
            Internal.Method = 'correlation';
            
        case {'borgonovo'}
            Internal.Method = 'borgonovo';
            InitBootstrap = true;
        case {'ancova'}
            Internal.Method = 'ancova';
        case {'kucherenko'}
            Internal.Method = 'kucherenko';
        case {'shapley'}
            Internal.Method = 'shapley';
    end
end

% Initialize the factors structure. It is used to define onto which input
% variables the sensitivity analysis is run: 
if InitFactors
    [opt, Options] = uq_process_option(Options, 'Factors', struct, 'struct');
    Factors = opt.Value;
    % Add boundaries if not specified
    if ~isfield(Factors, 'Boundaries')
        % The boundaries are initialized depending on the input
        % distributions, if available
        
        % Loop over input variables
        for ii = 1:M
            % set upper and lower bounds for bounded distributions
            Marginals = CurrentInput.Marginals(ii);
            if isfield(Marginals, 'Bounds') && ~isempty(Marginals.Bounds)
                Factors(ii).Boundaries = Marginals.Bounds;
            else
                switch lower(Marginals.Type)
                    % Upper and Lower bounds
                    case 'uniform' 
                        % Upper and lower bounds for uniform
                        Factors(ii).Boundaries = Marginals.Parameters;
                    case 'beta' 
                        % Upper and lower bounds of beta distribution
                        Factors(ii).Boundaries = Marginals.Parameters([3 4]);
                    case 'lognormal' 
                        % use moments, but make sure the lower bound is > 0
                        Factors(ii).Boundaries(1) = max(Marginals.Moments(1) - FactorDefaults.Boundaries*Marginals.Moments(2),0);
                        Factors(ii).Boundaries(2) = Marginals.Moments(1) + FactorDefaults.Boundaries*Marginals.Moments(2);
                    case 'constant'
                        % The boundaries should be NaN for constants.
                        Factors(ii).Boundaries(1) = NaN;
                        Factors(ii).Boundaries(2) = NaN;
                    otherwise
                        % use moments in all other cases
                        Factors(ii).Boundaries(1) = Marginals.Moments(1) - FactorDefaults.Boundaries*Marginals.Moments(2);
                        Factors(ii).Boundaries(2) = Marginals.Moments(1) + FactorDefaults.Boundaries*Marginals.Moments(2);
                end
            end
        end
    else
        for ii = 1:M
            % I need to treat the constants anyway:
            if strcmpi(CurrentInput.Marginals(ii).Type,'Constant')
                Factors(ii).Boundaries(1) = ...
                    CurrentInput.Marginals(ii).Parameters;
                Factors(ii).Boundaries(2) = ...
                    CurrentInput.Marginals(ii).Parameters;
            end
        end
    end
    
    if length(Factors) == 1
        % If only one value is provided, it is replicated to all the dimensions:
        NS = Factors.Boundaries;
        [Factors(1:M).Boundaries] = deal(NS);
    end
    % Assign the initialized factors structure
    Internal.Factors = Factors;
    
    % Consistency check on the Factors structure
    if M ~= length(Factors)
        error('The defined boundaries are not compatible with the selected input.');
    end
    
    % Options.Factors is an M-dimensional struct with a field Boundaries.
    % Check if they are intervals or if the intervals need to be defined
    % from a scalar in terms of standard deviation:
    for ii = 1:M
        % Retrieve the value provided:
        NS = Factors(ii).Boundaries;
        switch length(NS)
            case 1
                % Single value: generate an interval in terms of input
                % standard deviation. Also check if the distribution is not
                % bounded
                
                % Check that the dimension is correct:
                if length(Factors) > 1
                    if ~(length(CurrentInput.Marginals) == length(Factors))
                        fprintf('\nThe provided Input module: "%s" does not have the same dimension as Options.Factors.\n', ...
                            CurrentInput.Name);
                        error('Input and Options.Factors dimensions do not match.')
                    end
                end
                                
                % set upper and lower bounds for bounded distributions
                Marginals = CurrentInput.Marginals(ii);
                if isfield(Marginals, 'Bounds') && ~isempty(Marginals.Bounds)
                    Factors(ii).Boundaries = Marginals.Bounds;
                else
                    switch lower(Marginals.Type)
                        case 'lognormal' % use moments, but make sure the lower bound is > 0
                            Factors(ii).Boundaries(1) = max(Marginals.Moments(1) - NS*Marginals.Moments(2),0);
                            Factors(ii).Boundaries(2) = Marginals.Moments(1) + NS*Marginals.Moments(2);
                        otherwise % use moments in all other cases
                            Factors(ii).Boundaries(1) = Marginals.Moments(1) - NS*Marginals.Moments(2);
                            Factors(ii).Boundaries(2) = Marginals.Moments(1) + NS*Marginals.Moments(2);
                    end
                end
                
                % Assign the final structure to the analysis                
                Internal.Factors =  Factors;
                
            case 2
                % The interval is already provided, there are no
                % consistency checks made:
                continue
                
            otherwise
                error('Unrecognized interval for Factors(%d).Boundaries', ii);
        end
    end
end

%% FLAG TO SAVE THE MODEL EVALUATIONS (IF POSSIBLE)
[opt, Options] = uq_process_option(Options, 'SaveEvaluations', 1, {'logical', 'double', 'char'});
switch opt.Value
    case {1, true}
        Internal.SaveEvaluations = 1;
    otherwise
        Internal.SaveEvaluations = 0;
end


% Set the verbosity level:
[Options, Internal] = uq_initialize_display(Options, Internal);

% Subset of input variables to include in the analysis
[opt, Options] = uq_process_option(Options, 'FactorIndex', true(1, M), {'logical', 'double'});
% Make sure that the FactorIndex is a row vector
SI = size(opt.Value);
if ~isequal(SI, [1 M]) % if the size is not correct
   if isequal(SI, [M 1]) % if it is just transposed, fix it
       opt.Value = opt.Value.';
   else % Throw an error otherwise
       error('The FactorIndex option must be a 1xM row vector. \nThe specified FactorIndex is of size %dx%d', SI(1),SI(2));
   end
end
% If an input is constant set the factorIndex to 0
if exist('nonConst', 'var')
    Internal.FactorIndex = opt.Value & ismember(1:M, nonConst);
else
    Internal.FactorIndex = opt.Value;
end


%% METHOD-SPECIFIC INITIALIZATION
switch lower(Internal.Method)
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Correlation-based indices       %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'correlation'
        CorrOpts = struct;
        InitCorrOpts = struct;
        
        [opt, Options] = uq_process_option(Options, 'Correlation', CorrOpts, 'struct');
        CorrOpts = opt.Value;
        
        % check for specifications. prefer provided samples
        if isfield(CorrOpts,'Sample') && ~isempty(CorrOpts.Sample)
            try
                x = CorrOpts.Sample.X;
                y = CorrOpts.Sample.Y;
                if size(x,1) == size(y,1)
                    InitCorrOpts.Sample = CorrOpts.Sample;
                else
                    fprintf('\n\nError: The provided samples do not have the same length!\n')
                    error('While initializing the analysis')
                end
            catch ME
                fprintf('\n\nError: Something went wrong while getting the provided samples!\n')
                fprintf('The cached error message may help:\n')
                ME
                error('While initializing the analysis')
            end
        else
            % get sampling information
            [opt, CorrOpts] = uq_process_option(CorrOpts, 'Sampling', 'LHS', 'char');
            InitCorrOpts.Sampling = opt.Value;
            [opt, CorrOpts] = uq_process_option(CorrOpts, 'SampleSize', 10000);
            InitCorrOpts.SampleSize = opt.Value;
        end
        Internal.Correlation = InitCorrOpts;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Standard Regression Coefficients%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'src'
        % Just specify the correlation type
        [opt, Options] = uq_process_option(Options, 'SRC');
        if opt.Missing || opt.Invalid
            Internal.SRC = [];
        else
            Internal.SRC = opt.Value;
        end
        % Give an error if neither a sample size nor a sample are specified
        if ~isfield(Internal.SRC, 'SampleSize') && ~isfield(Internal.SRC, 'Sample')
           error('Neither sample nor sample size specified. Cannot perform correlation analysis');
        end
                     
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %              COTTER             %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'cotter'
        % No specific intialization needed for Cotter indices
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %          PERTURBATION           %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'perturbation'
        % make sure that the standard gradient step is relative
        if ~isfield(Options, 'Gradient')||(isfield(Options, 'Gradient') &&  ~isfield(Options.Gradient, 'Step'))
            Options.Gradient.Step = 'relative';
        end
        % Initialize the numerical calculation of the gradient
        [Options, Internal] = uq_initialize_gradient(Options, Internal);
        
           
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %             MORRIS              %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'morris'
        % Check if Options.Morris is present and if it is a struct:
        MorrisOpts = struct;
        
        [opt, Options] = uq_process_option(Options, 'Morris', MorrisOpts, 'struct');
        MorrisOpts = opt.Value;
        
        % GridLevels
        % GridLevels = M;
        if isfield(MorrisOpts,'PerturbationSteps')
            GridLevels = MorrisOpts.PerturbationSteps*2;
        else
            GridLevels = 2*ceil(M/2);
        end
        [opt, MorrisOpts] = uq_process_option(MorrisOpts, 'GridLevels', GridLevels, 'double');
        InitMorrisOpts.GridLevels = opt.Value;
        
        % PerturbationSteps
        % Define the Delta of the perturbation, as the integer c such that
        % Delta = c * 1/(1-p)
%         PerturbationSteps = 3;
        PerturbationSteps = floor(InitMorrisOpts.GridLevels/2);
        [opt, MorrisOpts] = uq_process_option(MorrisOpts, 'PerturbationSteps', PerturbationSteps, 'double');
        InitMorrisOpts.PerturbationSteps = opt.Value;
        
        % Define the number of samples per factor, if not defined or if
        % it is bigger than the max. num of runs of the full set:
        if ~isfield(MorrisOpts,'FactorSamples') && ~isfield(MorrisOpts,'Cost')
            error(sprintf(['Either the number of Samples per Factor ', ...
                'or the total cost of the method\n', ...
                'must be defined (Options.Morris.FactorSamples or Options.Morris.Cost)']));
        end
        if isfield(MorrisOpts,'FactorSamples') && isfield(MorrisOpts,'Cost')
            fprintf(['Warning: Both FactorSamples and Cost have been', ...
                'defined.\nThe Cost option will be ignored.']);
            MorrisOpts = rmfield(MorrisOpts, 'Cost');
        end
        
        % Process either FactorSamples or Cost:
        if isfield(MorrisOpts,'FactorSamples')
            [opt, MorrisOpts] = uq_process_option(...
                MorrisOpts, 'FactorSamples', 0, 'double');
            if opt.Invalid || opt.Disabled
                error('Options.Morris.FactorSamples must be an integer');
            else
                FSamples = opt.Value;
            end
            
        else
            [opt, MorrisOpts] = uq_process_option(...
                MorrisOpts, 'Cost', 0, 'double');
            if opt.Invalid || opt.Disabled
                error('Options.Morris.FactorSamples must be an integer');
            else
                FSamples = floor(opt.Value/(M + 1));
                if FSamples < 2
                    fprintf('\nWarning: The specified cost "%d" is not enough to carry out the method', MorrisOpts.Cost);
                    fprintf('\nThe total cost will be: %d\n', 2*(M + 1) );
                    FSamples = 2;
                end
            end
            
            
        end
        InitMorrisOpts.FactorSamples = FSamples;
        
        Internal.Morris = InitMorrisOpts;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %         SOBOL' INDICES          %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'sobol'
        % Check if Options.Sobol is present and if it is a struct:
        SobolOpts = struct;
        InitSobolOpts = struct;
        
        [opt, Options] = uq_process_option(Options, 'Sobol', SobolOpts, 'struct');
        SobolOpts = opt.Value;
        
        % Check if the model is a PCE or LRA:
        CurrentModel = uq_getModel(Internal.Model);
        if isprop(CurrentModel, 'MetaType') && ...
                any(strcmpi(CurrentModel.MetaType, {'pce','lra'}))
            MetamodelBased = true;
        else
            MetamodelBased = false;
        end
        
        [opt_pce, SobolOpts] = uq_process_option(SobolOpts, 'PCEBased', ...
            MetamodelBased);
        [opt_lra, SobolOpts] = uq_process_option(SobolOpts, 'LRABased', ...
            MetamodelBased);
%         [opt_sse, SobolOpts] = uq_process_option(SobolOpts, 'SSEBased', ...
%             MetamodelBased);
        
        if opt_pce.Value || opt_lra.Value %|| opt_sse.Value 
            if isprop(CurrentModel, 'MetaType') && ...
                    any(strcmpi(CurrentModel.MetaType, {'pce','lra'}))
                switch lower(CurrentModel.MetaType)
                    case 'lra'
                        InitSobolOpts.CoefficientBased = opt_lra.Value;
                        
                        % Check now the problem dimension - if larger than
                        % 20 revert to MC based Sobol' indices - Issue a
                        % warning saying that the dimension is too large
                        % for LRA 
                        if M > 20
                            % MC-based Sobol'
                          InitSobolOpts.CoefficientBased = false;
                          % Warning
                          if opt_lra.Missing 
                                fprintf('\nWarning: LRA based indices can''t be efficiently computed for large dimensional problems (M>20)');
                                fprintf('\nswitching back to MCS Sobol indices estimators...\n'); 
                          end
                        end
                    case 'pce'
                        InitSobolOpts.CoefficientBased = opt_pce.Value;
%                     case 'sse'
%                         % ensure that provided SSE is flattened, if not
%                         % flatten it
%                         if numnodes(CurrentModel.SSE.FlatGraph) == 0
%                             warning('Provided SSE is not flattened, flattening it now...')
%                             for oo = 1:length(CurrentModel.SSE)
%                                 CurrentModel.SSE(oo) = uq_SSE_flatten(CurrentModel.SSE(oo));
%                             end
%                         end
%                         % make sure that requested order is not larger
%                         % than 1
%                         if SobolOpts.Order > 1
%                             error('SSE-based indices only supported up to first order...')
%                         end
%                         % Store options
%                         InitSobolOpts.CoefficientBased = opt_sse.Value;
                end
            else
                fprintf('\nWarning: PCE or LRA-based indices are only available on PCE or LRA metamodels');
                fprintf('\nswitching back to MCS Sobol indices estimators...\n');
                InitSobolOpts.CoefficientBased = false;
            end
        else
            InitSobolOpts.CoefficientBased = opt_pce.Value || opt_lra.Value; %|| opt_sse.Value;
        end
        
        [opt, SobolOpts] = uq_process_option(SobolOpts, 'Order', 1, 'double');
        InitSobolOpts.Order = opt.Value;
        
        % The following options only apply for MCS estimators:
        if ~InitSobolOpts.CoefficientBased
            
            % Sampling method
            % Check the selected sampling method of the input:
            [opt, SobolOpts] = uq_process_option(SobolOpts, 'Sampling', 'mc', 'char');
            InitSobolOpts.Sampling = opt.Value;
            
            % SampleSize
            [opt, SobolOpts] = uq_process_option(SobolOpts, 'SampleSize', 10000, 'double');
            InitSobolOpts.SampleSize = opt.Value;
            
            % Estimator:
            [opt, SobolOpts] = uq_process_option(SobolOpts, 'Estimator', 't', 'char');
            switch lower(opt.Value)
                case {'sobol','classic'}
                    InitSobolOpts.Estimator = 'sobol';
                case {'janon','t'}
                    InitSobolOpts.Estimator = 't';
                case {'homma','s'}
                    InitSobolOpts.Estimator = 's';
                    
                otherwise
                    fprintf('\nWarning: Estimator "%s" is not available. Changed to "%s"\n', SobolOpts.Estimator, opt.Default);
                    InitSobolOpts.Estimator = opt.Default;
            end
            
            
        end
        
        % Set it to internal:
        Internal.Sobol = InitSobolOpts;

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %         BORGONOVO INDICES       %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'borgonovo'
        InitBorgonovoOpts = struct;
        [opt, Options] = uq_process_option(Options,...
            'Borgonovo',struct,'struct');
        BorgonovoOpts = opt.Value;
        
        % Determine the selected method: HistBased or CDFBased
        AvailableMethods = {'HistBased','CDFBased'};
        [opt, BorgonovoOpts] = uq_process_option(BorgonovoOpts,'Method','HistBased');        
        switch lower(opt.Value)
            case lower(AvailableMethods)
                InitBorgonovoOpts.Method = lower(opt.Value);
            otherwise
                fprintf('\n\nError: The chosen method "%s" is not supported.\n',opt.Value);
                fprintf('Please choose one of the available: %s.\n',uq_cell2str(AvailableMethods));
                error('While initializing the analysis')
        end

        
        % Check for provided sample
        [opt_ed, BorgonovoOpts] = uq_process_option(BorgonovoOpts,...
            'Sample',struct,'struct');        
        % if the sample is there, there is no need to sample again (we might
        % not even have the model)
        if ~opt_ed.Missing
            InitBorgonovoOpts.ExpDesign = opt_ed.Value;
            InitBorgonovoOpts.SampleSize = size(opt_ed.Value.X,1);
        else
            % Check the selected sampling method of the input:
            [opt_samp, BorgonovoOpts] = uq_process_option(BorgonovoOpts, ...
                'Sampling', 'lhs', 'char');
            InitBorgonovoOpts.Sampling = opt_samp.Value;

            % SampleSize
            [opt_samp, BorgonovoOpts] = uq_process_option(BorgonovoOpts, ...
                'SampleSize', 10000, 'double');            
            InitBorgonovoOpts.SampleSize = opt_samp.Value;
        end
        
        % Check the binning strategy for the classes: Overlap or no overlap
        % and Quantile or Regular.
        % Default: 15 classes, Quantile and 2% overlap        
        % Overlap
        [opt, BorgonovoOpts] = uq_process_option(BorgonovoOpts,'Overlap',0.02,'double');
        InitBorgonovoOpts.h_overlap = opt.Value;
        % The default number of bins depends / can depend on whether there is overlap or not
        if InitBorgonovoOpts.h_overlap == 0
            [opt, BorgonovoOpts] = uq_process_option(BorgonovoOpts,'NClasses',20,'double');
            InitBorgonovoOpts.nbins_x = opt.Value;
        else
            [opt, BorgonovoOpts] = uq_process_option(BorgonovoOpts,'NClasses',20,'double');
            InitBorgonovoOpts.nbins_x = opt.Value;
        end
        
        % Binning strat (applies only for X-direction)
        AvailableBinStrats = {'Quantile','Constant'};
        [opt, BorgonovoOpts] = uq_process_option(BorgonovoOpts,'BinStrat','Quantile','char');
        switch lower(opt.Value)
            case lower(AvailableBinStrats)
                InitBorgonovoOpts.BinStrat = lower(opt.Value);
            otherwise
                fprintf('\n\nError: The chosen binning strategy "%s" is not supported.\n',opt.Value);
                fprintf('Please choose one of the available: %s.\n',uq_cell2str(AvailableBinStrats));
                error('While initializing the analysis')
        end
        % Check for prefered bin amount in Y direction. The default is
        % 'auto', where a suitable amount for each class will be chosen by
        % histcounts (happens in UQ_BORGONOVO_INDEX)
        [opt, BorgonovoOpts] = uq_process_option(BorgonovoOpts,'NHistBins','auto');
        switch class(opt.Value)
            case 'double'
                InitBorgonovoOpts.nbins_y = opt.Value;
            case 'char'
                if strcmpi(opt.Value,'auto')
                    InitBorgonovoOpts.nbins_y = opt.Value;
                else
                    fprintf('\nWarning: The provided value "%s" in .NHistBins is not valid and will be ignored!\n',opt.Value);
                    fprintf('The default value ''auto'' is set.\n');
                    InitBorgonovoOpts.nbins_y = 'auto';
                end
            otherwise
                fprintf('\nWarning: The provided value in .NHistBins is not valid and will be ignored!\n');
                fprintf('The default value ''auto'' is set.\n');
                InitBorgonovoOpts.nbins_y = 'auto';
        end
        % Put it in Internal
        Internal.Borgonovo = InitBorgonovoOpts;
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %         ANCOVA INDICES          %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'ancova'
        % Check if Options.ANCOVA is present and if it is a struct:
        ANCOVAOpts = struct;
        InitANCOVAOpts = struct;
        
        Internal.CustomPCE = false;
        PCEOpts = struct;
        InitPCEOpts = struct;
        
        [opt, Options] = uq_process_option(Options, 'ANCOVA', ANCOVAOpts, 'struct');
        ANCOVAOpts = opt.Value;
        
        % Check the selected sampling method and size for the PCE, but use
        % provided samples if available
        SamplesEmpty = false;
        if isfield(ANCOVAOpts,'Samples') && ~isempty(ANCOVAOpts.Samples) % samples are provided
            if isfield(ANCOVAOpts.Samples,'X') && ~isempty(ANCOVAOpts.Samples.X)
                [opt,ANCOVAOpts.Samples] = uq_process_option(ANCOVAOpts.Samples,'X');
                InitPCEOpts.ExpDesign.X = opt.Value;
                % try getting Y as well
                [opt,ANCOVAOpts.Samples] = uq_process_option(ANCOVAOpts.Samples,'Y',[]);
                InitPCEOpts.ExpDesign.Y = opt.Value;
                
            else
                if Internal.Display > 1
                    fprintf('\nThe field ANCOVA.Samples is defined but there is no sample to be found!\n')
                    fprintf('Initiating sampling.\n')
                end
                SamplesEmpty = true;
            end
        end    
        if ~isfield(ANCOVAOpts,'Samples') || SamplesEmpty % sample yourself
            % SampleSize
            [opt,ANCOVAOpts] = uq_process_option(ANCOVAOpts,'SampleSize',200,'double');
            InitPCEOpts.ExpDesign.NSamples = opt.Value;
            % Sampling strat
            [opt, ANCOVAOpts] = uq_process_option(ANCOVAOpts,'Sampling','lhs','char');
            InitPCEOpts.ExpDesign.Sampling = opt.Value;
        end
        
        % Check for specifications of MC samples for analysis
        [opt,ANCOVAOpts] = uq_process_option(ANCOVAOpts,'MCSamples',10000,'double');
        InitANCOVAOpts.SampleSize = opt.Value;        
        
        % Check if the model is a PCE and if it should be used right away:
        [opt, ANCOVAOpts] = uq_process_option(ANCOVAOpts, 'CustomPCE');
        if ~opt.Missing
            % check the customPCE
            if isprop(opt.Value, 'MetaType') && any(strcmpi(opt.Value.MetaType, {'pce'}))
                Internal.CustomPCE = true;
            else
                fprintf('\n\nError: The provided object in ANCOVA.CustomPCE is not of type PCE!\n')
                disp(CurrentModel)
                error('While initializing the analysis');
            end
            % check if there is already a model in Internal.Model and if
            % so warn before replacing
            if ~isempty(Internal.Model) && Internal.Display >= 1
                fprintf('\nWarning: Only the MODEL object provided in ANCOVA.CustomPCE will be used!\n')
            end            
            Internal.Model = opt.Value;
            
        else % PCE needs to be set up, check specs
            Internal.CustomPCE = false;
            
            % check if there is a model
            if isempty(Internal.Model) && SamplesEmpty
                fprintf('\n\nError: There is no MODEL provided!\n')
                error('While initializing the analysis');
            end
            
            [opt, ANCOVAOpts] = uq_process_option(ANCOVAOpts, 'PCE', PCEOpts, 'struct');
            PCEOpts = opt.Value;
            
            % Check settings
            [opt, PCEOpts] = uq_process_option(PCEOpts, 'Type', 'Metamodel', 'char');
            InitPCEOpts.Type = opt.Value;
            [opt, PCEOpts] = uq_process_option(PCEOpts, 'MetaType', 'PCE', 'char');
            InitPCEOpts.MetaType = opt.Value;
            
            [opt, PCEOpts] = uq_process_option(PCEOpts, 'Degree', 1:10);
            InitPCEOpts.Degree = opt.Value;
            [opt, PCEOpts] = uq_process_option(PCEOpts, 'Method', 'LARS', 'char');
            InitPCEOpts.Method = opt.Value;            
        end
        
        % Set the specifics to internal:
        Internal.ANCOVA = InitANCOVAOpts;
        Internal.PCEOpts = InitPCEOpts;

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %        KUCHERENKO INDICES       %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'kucherenko'
        % Check if Options.Kucherenko is present and if it is a struct:
        KucherenkoOpts = struct;
        InitKucherenkoOpts = struct;
        
        [opt, Options] = uq_process_option(Options, 'Kucherenko', KucherenkoOpts, 'struct');
        KucherenkoOpts = opt.Value;
        
        % Estimator
        [opt,KucherenkoOpts] = uq_process_option(KucherenkoOpts,'Estimator','Modified','char');
        
        % Make sure that the given estimator is known
        if all(~strcmpi(opt.Value, {'standard','modified','samplebased'}))
            fprintf('\nWarning: Estimator "%s" is not available for Kucherenko. Changed to "%s".\n', opt.Value, opt.Default);
            opt.Value = opt.Default;
        end
        
        % When the copula is neither independent nor Gaussian, only the
        % samplebased estimator can be used. Make sure the analysis
        % parameters are consistent with this otherwise update
        if ~strcmpi(opt.Value, 'samplebased') 
            if isempty(CurrentInput)
                error('Cannot compute sensitivity indices without input object using estimator of type''%s''',opt.Value)
            elseif all(~strcmpi(CurrentInput.Copula.Type,{'Independent','Gaussian'}))
                if opt.Missing
                    % The user did not set the esitmator himself - Just issue a
                    % warning and change the estimator to samplebased
                    warning('For copula of type ''%s'', only the ''samplebased'' method can be used to compute Kucherenko indices!\n', CurrentInput.Copula.Type);
                    fprintf('Kucherenko method is set to ''samplebased''.\n');
                    opt.Value = 'samplebased' ;
                else
                    % The user expressely set the estimator to something that
                    % cannot be used so issue an error
                    error('Cannot compute sensitivity indices for copula of type ''%s'' using estimator of type ''%s''', CurrentInput.Copula.Type, opt.Value) ;
                end
            end
        end
        
        InitKucherenkoOpts.Estimator = lower(opt.Value);

        
        % Sampling strategy
        allowedaltmeth = {'sobol','halton'};
        switch InitKucherenkoOpts.Estimator % different defaults depending on estimator
            case 'alternative'
                [opt,KucherenkoOpts] = uq_process_option(KucherenkoOpts,'Sampling','sobol','char');
                InitKucherenkoOpts.Sampling = opt.Value;
                
                % check if QMC for alternative
                if ~any(strcmpi(InitKucherenkoOpts.Sampling,allowedaltmeth))
                    fprintf('\n\nError: The "%s" estimator does not improve performance if no\n',InitKucherenkoOpts.Estimator);
                    fprintf('QMC sampling method is used. Please use a pseudo-random sampling\n');
                    fprintf('startegy or use another estimator.\n');
                    error('While initializing the analysis');
                end
                
            otherwise
                [opt,KucherenkoOpts] = uq_process_option(KucherenkoOpts,'Sampling','LHS','char');
                InitKucherenkoOpts.Sampling = opt.Value;        
        end       
        
        % For the sample based est, check for provided sample
        if strcmpi(InitKucherenkoOpts.Estimator, 'samplebased')
            if isfield(KucherenkoOpts, 'Samples') % Sample is provided
                if isfield(KucherenkoOpts.Samples, 'X')
                    [opt,KucherenkoOpts.Samples] = uq_process_option(KucherenkoOpts.Samples,'X');
                    InitKucherenkoOpts.Samples.X = opt.Value;
                    InitKucherenkoOpts.SampleSize = size(opt.Value,1);
                    if isfield(KucherenkoOpts.Samples, 'Y') % Check for output sample
                        [opt,KucherenkoOpts.Samples] = uq_process_option(KucherenkoOpts.Samples,'Y');
                        InitKucherenkoOpts.Samples.Y = opt.Value;
                        if size(InitKucherenkoOpts.Samples.Y,1) ~= InitKucherenkoOpts.SampleSize
                            fprintf('\n\nError: The number of points in X and Y must be equal!\n');
                            error('While initializing the analysis: unequal sample lengths');
                        end
                    end
                    
                end
                                    
            else % define SampleSize for samplebased
                [opt,KucherenkoOpts] = uq_process_option(KucherenkoOpts,'SampleSize',100000,'double');
                InitKucherenkoOpts.SampleSize = opt.Value;
           
            end
            
            
        else % define SampleSize for other estimators
            [opt,KucherenkoOpts] = uq_process_option(KucherenkoOpts,'SampleSize',10000,'double');
            InitKucherenkoOpts.SampleSize = opt.Value;
        end
        
        % For the sample based estimation, set maximum number of bins
        % if not specified, it'll be done later depending on the conditioning
        if strcmpi(InitKucherenkoOpts.Estimator, 'samplebased')
            [opt,KucherenkoOpts] = uq_process_option(KucherenkoOpts,'maxBins',0,'double');
            InitKucherenkoOpts.nBins = opt.Value;
        end
        
        % [MM]: Why not Internal.Kucherenko? 
        % Set to Internal
        Internal.Kucherenko = InitKucherenkoOpts;

end

%%%%%%%%%%%%%%%%%%
% END OF METHODS %
%%%%%%%%%%%%%%%%%%

% Initialize Options.Bootstrap.(...)
if InitBootstrap
    % Field Bootstrap:
    SBoot = struct('Replications', 0, 'Alpha', 0.05);
    
    [opt, Options] = uq_process_option(Options, 'Bootstrap', SBoot, 'struct');
    SBoot = opt.Value;
    
    [opt, SBoot] = uq_process_option(SBoot, 'Replications', SBoot.Replications, 'double');
    Internal.Bootstrap.Replications = opt.Value;
    
    [opt, SBoot] = uq_process_option(SBoot, 'Alpha', SBoot.Alpha, 'double');
    Internal.Bootstrap.Alpha = opt.Value;
    
    uq_options_remainder(SBoot, ' the Bootstrap routine of Sobol'' indices.');
end

% Remove the basic fields (to avoid throwing errors):
Options = rmfield(Options, 'Type');
if isfield(Options, 'Name')
    Options = rmfield(Options, 'Name');
end
% give warnings in case unused options are still present
uq_options_remainder(Options, ' the Sensitivity Analysis Module');


%% Give the filtered options back to the object
current_analysis.Internal = Internal;

%% Run the analysis
uq_runAnalysis(current_analysis);

% If everything else ran correctly, set the SUCCESS output to 1
success = 1;

end

