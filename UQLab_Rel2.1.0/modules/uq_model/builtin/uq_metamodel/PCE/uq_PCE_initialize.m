function success = uq_PCE_initialize( current_model )
% success = UQ_PCE_INITIALIZE(CURRENT_MODEL): Initialize a PCE model based on the
%     user-specified options.
% 
% See also: UQ_PCE_INITIALIZE_CUSTOM, UQ_KRIGING_INITIALIZE,
% UQ_INITIALIZE_UQ_METAMODEL

%% definition of the defaults


% option fields that should be ignored by the option parser. THEY WILL BE
% REMOVED FROM THE PROCESSED OPTIONS!!
IGNORE_OPTIONS = {'Type', 'MetaType', 'ExpDesign', 'Name', 'FullModel', 'Display', 'Input','ValidationSet'};

% check the size of the experimental design
% if N > EarlyStopThreshold, we will use the LARSinitialEnrich/OMP EarlyStop options
N = current_model.ExpDesign.NSamples;
EarlyStopThreshold = 50;

% lars
LARSDefaults.LarsEarlyStop = N>EarlyStopThreshold;
LARSDefaults.KeepIterations = false;
LARSDefaults.TargetAccuracy = 0;
% LARSDefaults.HybridLars = true;
LARSDefaults.ModifiedLoo = true;
LARSDefaults.HybridLoo = true;

% OMP
OMPDefaults.OmpEarlyStop = N>EarlyStopThreshold;
OMPDefaults.KeepIterations = false;
OMPDefaults.TargetAccuracy = 0;
OMPDefaults.ModifiedLoo = true;

% SP
SPDefaults.ModifiedLoo = true;
SPDefaults.TargetAccuracy = 0; % legacy option

% BCS
BCSDefaults.ModifiedLoo = false;
BCSDefaults.TargetAccuracy = 0; % legacy option

% OLS
OLSDefaults.TargetAccuracy = 0;
OLSDefaults.ModifiedLoo = true;

% Quadrature
QuadratureDefaults.Type = 'Smolyak';
QuadratureDefaults.Rule = 'Gaussian';

% General
GeneralDefaults.DegreeEarlyStop = true;
GeneralDefaults.qNormEarlyStop = true;

% Custom
CustomDefaults.TargetAccuracy = 0;
CustomDefaults.ModifiedLoo = true;

% Bootstrap
BootstrapDefaults.Replications = 100;
BootstrapDefaults.Alpha = 0.05;

% Basis Truncation options
TruncDefaults.qNorm = 1;

% some checks: the model must be of "uq_metamodel" type
if ~strcmp(current_model.Type, 'uq_metamodel')
    success = -1;
    error('uq_initialize_uq_metamodel error: you must initialize a uq_metamodel type object, not a % one!!', module.Type);
end

%% CREATE THE PCE FIELD IN THE MODEL STRUCTURE
uq_addprop(current_model, 'PCE');

%% RETRIEVE THE OPTIONS AND PARSE THEM
Options = current_model.Options;

%% INPUT
if ~isfield(Options,'Input') ||...
        (~isa(Options.Input,'uq_input') &&...
        ~ischar(Options.Input) )
    current_model.Internal.Input = uq_getInput;
    if isempty(current_model.Internal.Input)
        error('Error: the specified input does not seem to be either a string nor a recognized object!')
    end
else
    current_model.Internal.Input = uq_getInput(Options.Input);
end

%% Make sure that the constant inputs are correctly dealt with
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

% update quadrature defaults if M < 4
if length(current_model.Internal.Input.Marginals) < 4
   QuadratureDefaults.Type = 'Full';
end


%% COEFFICIENTS
% now checking the coefficient options

%% Method
[Method, Options] = uq_process_option(Options, 'Method', 'LARS', 'char');
if Method.Invalid
    error('The Method field must be a string!')
else
    current_model.Internal.Method = Method.Value;
end


%% Basis Truncation
[TruncOptions, Options] = uq_process_option(Options,'TruncOptions', TruncDefaults, 'struct');
if TruncOptions.Invalid
   error('TruncOptions must be a structure!') ;
end
% directly pass the truncation options to the PCE. It will take care of
% building the basis appropriately
current_model.Internal.PCE.Basis.Truncation = TruncOptions.Value;

% set the degree value properly. Later we will have to handle the case of a
% cell array with different degree sets for each output variable
[Degree, Options] = uq_process_option(Options, 'Degree', 1:3, {'double','cell'});
if Degree.Invalid
    error('The Degree field must be a constant, an array or a cell array!')
end
% In case of custom PCE, compute the degree from the custom basis (ignore
% .Degree supplied by user)
% Two possibilities of custom PCE: 
% 1) Custom basis given in MetaOpts.TruncOpts.Custom
if isfield(current_model.Internal.PCE.Basis.Truncation, 'Custom') && ~isempty(current_model.Internal.PCE.Basis.Truncation.Custom)
    Degree.Value = max(max(current_model.Internal.PCE.Basis.Truncation.Custom));
end
% 2) Custom PCE (basis and coefficients given)
% This is taken care of in uq_PCE_initialize_custom

% watch out for degree arrays for quadrature
if strcmpi(current_model.Internal.Method,'Quadrature') && numel(Degree.Value) > 1
    if current_model.Internal.Display >0
        fprintf('\nWarning: degree-adaptivity not available for Quadrature.')
        fprintf('Largest given value %d is chosen.\n',max(Degree.Value));
    end
    current_model.Internal.PCE.Degree = max(Degree.Value);
else
    current_model.Internal.PCE.Degree = Degree.Value;
end

% now initialize each method separately
[current_model,Options] = uq_PCE_initialize_process_basis(current_model,1,Options);

%% Initialization of the coefficient calculation methods
switch lower(Method.Value)
    case 'lars' % initialize lars
        [LARSOptions, Options] = uq_process_option(Options, 'LARS', LARSDefaults, 'struct');
        if LARSOptions.Invalid
            error('The LARS field must be a structure!')
        end
        current_model.Internal.PCE.LARS = LARSOptions.Value;
        
    case 'omp' % initialize omp
        [OMPOptions, Options] = uq_process_option(Options, 'OMP', OMPDefaults, 'struct');
        if OMPOptions.Invalid
            error('The OMP field must be a structure!')
        end
        current_model.Internal.PCE.OMP = OMPOptions.Value;
        
    case 'sp' % initialize SP
        [SPOptions, Options] = uq_process_option(Options, 'SP', SPDefaults, 'struct');
        if SPOptions.Invalid
            error('The SP field must be a structure!')
        end
        current_model.Internal.PCE.SP = SPOptions.Value;

    case 'bcs' % initialize BCS
        [BCSOptions, Options] = uq_process_option(Options, 'BCS', BCSDefaults, 'struct');
        if BCSOptions.Invalid
            error('The BCS field must be a structure!')
        end
        current_model.Internal.PCE.BCS = BCSOptions.Value;

        
    case 'ols' % initialize ordinary least squares
        [OLSOptions, Options] = uq_process_option(Options, 'OLS', OLSDefaults, 'struct');
        if OLSOptions.Invalid
            error('The OLS field must be a structure!')
        end
        current_model.Internal.PCE.OLS = OLSOptions.Value;
        
    case 'quadrature' % initialize quadrature
        [QuadratureOptions, Options] = uq_process_option(Options, 'Quadrature', QuadratureDefaults, 'struct');
        if QuadratureOptions.Invalid
            error('The Quadrature field must be a structure!');
        end
        current_model.Internal.PCE.Quadrature = QuadratureOptions.Value;
    otherwise % throw an error in case it's not a recognized method
         [CustomOptions, Options] = uq_process_option(Options, upper(Method.Value), CustomDefaults, 'struct');
        if CustomOptions.Invalid
            error('The Quadrature field must be a structure!');
        end
        current_model.Internal.PCE.(upper(Method.Value)) = CustomOptions.Value;
end


% Check EarlyStop specifications
[DegreeEarlyStop, Options] = uq_process_option(Options, 'DegreeEarlyStop', GeneralDefaults.DegreeEarlyStop);
current_model.Internal.PCE.DegreeEarlyStop = DegreeEarlyStop.Value;

[qNormEarlyStop, Options] = uq_process_option(Options, 'qNormEarlyStop', GeneralDefaults.qNormEarlyStop);
current_model.Internal.PCE.qNormEarlyStop = qNormEarlyStop.Value;

%% Bootstrapping
[BootstrapOpts, Options] = uq_process_option(Options, 'Bootstrap',BootstrapDefaults, 'struct');
if ~BootstrapOpts.Missing && ~BootstrapOpts.Invalid
    current_model.Internal.PCE.Bootstrap = BootstrapOpts.Value;
end

%% CACHING AND DEBUGGING
% cache the auxiliary space info
[current_model.Internal.ED_Input.Marginals, current_model.Internal.ED_Input.Copula] = ...
                    uq_poly_marginals(current_model.PCE(1).Basis.PolyTypes, current_model.PCE(1).Basis.PolyTypesParams);


% debug mode (enables caching and other things)
current_model.Internal.Options.debug = false;
if isfield(Options, 'debug')
    current_model.Internal.Options.debug = Options.debug;
end


%% final checks and return values

% Check if any field was not recognized here.
uq_options_remainder(Options, ...
    current_model.Name, IGNORE_OPTIONS, current_model);

success = 1;

EVT.Type = 'II';
EVT.Message = 'Metamodel initialized correctly';
EVT.eventID = 'uqlab:metamodel:PCE_initialized';
uq_logEvent(current_model, EVT);



