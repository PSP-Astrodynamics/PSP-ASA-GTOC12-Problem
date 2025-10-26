function success = uq_initialize_uq_randomfield(module)
% UQ_INITIALIZE_UQ_RANDOMFIELD: initializes the random field discretization
% algorithm going through the options specfied by the user and setting
% default parameters

% 
success = 0 ;

%% DEFAULT VALUES

% Random field type
RFTypeDefault = 'Gaussian' ;

% Discretization scheme
DiscSchemeDefault = 'EOLE' ;

% Energy ratio
EnergyRatioDefault = 0.99 ;

% Expansion order default
ExpOrderDefault = [] ; % Empty means it will be computed w.r.t. target energy ratio

% Correlation function
CorrDefaults.Family = 'Gaussian';
CorrDefaults.Type = 'ellipsoidal';
CorrDefaults.Nugget = 0 ; % Explicitlely set no nugget
CorrDefaults.Handle = @uq_eval_Kernel;
% CorrDefaults.Isotropic is set once the dimension of the random field is
% known

% Known RFTyoes
KnownRFTypes = {'Gaussian','Lognormal','Exponential','Uniform','Gumbel','GumbelMin','Gamma','Logistic','Laplace'};

%%

% Retrieve the Input object
if exist('module', 'var')
    current_input = uq_getInput(module);
else
    current_input = uq_getInput;
end

% The module must be of "uq_randomfield" type
if ~strcmp(current_input.Type, 'uq_randomfield')
    error('uq_initialize_uq_randomfield error: you must initialize a uq_randomfield type object, not a % one!!', current_input.Type);
end

% Retrieve the options
Options = current_input.Options;

%% Initialize RFType
[RFType, Options] = uq_process_option(Options, 'RFType', RFTypeDefault);
% Make sure that the RFType is valid
if any(strcmpi(RFType.Value,KnownRFTypes))
   current_input.Internal.RFType = RFType.Value ; 
else
    error('The selected marginal distribution (.RFType) is not accepted!');
end

%% Initialize Mean
[RFMean, Options] = uq_process_option(Options, 'Mean');
if RFMean.Missing|| RFMean.Invalid
    error('The random field''s mean must be defined!');
end
current_input.Internal.Mean = RFMean.Value ;

%% Initialize standard deviation
[RFStd, Options] = uq_process_option(Options, 'Std');
if RFStd.Missing|| RFStd.Invalid
    error('The random field''s standard deviation must be defined!');
end
current_input.Internal.Std = RFStd.Value ;

%% Initialize Expansion order
[RFExpOrd, Options] = uq_process_option(Options, 'ExpOrder', ExpOrderDefault);

current_input.Internal.ExpOrder = RFExpOrd.Value ;

%% Initialize energy ration
[RFRatio, Options] = uq_process_option(Options, 'EnergyRatio', EnergyRatioDefault, 'double');
if RFRatio.Invalid
    error('The random field''s expansion order must be defined!');
end

current_input.Internal.EnergyRatio = RFRatio.Value ;

%% Initialize Correlation function

% First treat the correlation length option. Then attribute the remaining
% parameters according to their default values if not given by the user
if isfield(Options, 'Corr')
    [corrLength, Options.Corr] = ...
        uq_process_option(Options.Corr, 'Length');
    
    if corrLength.Invalid || corrLength.Missing
        error('A correlation length must be defined !');
    end
    current_input.Internal.Corr.Length = corrLength.Value ;
else
    error('At least one correlation option (the correlation length) must be defined !') ;
end

% Copied-pasted and adapted from Kriging initialization - Assuming that the
% same formalism is used
if isfield(Options, 'Corr') %This should always be true... to be modified
    % Some Correlation related options have been set by the user so
    % parse them
    
    % check whether a non-default function handle is selected for
    % evaluating R:
    [evalRhandle, Options.Corr] = ...
        uq_process_option(Options.Corr, 'Handle',...
        CorrDefaults.Handle, 'function_handle');
    
    % just silently assign the default handle if the user has not specified
    % something
    if evalRhandle.Missing
        % do nothing
    end
    
    if evalRhandle.Invalid
        error('Invalid definition of Correlation function handle!')
    end
    % The rest of the options are only relevant to the default
    % evalR-handle. So only parse them in case the default handle is used:
    if strcmp(char(evalRhandle.Value),'uq_eval_Kernel')
        % first set the handle option
        current_input.Internal.Corr.Handle = evalRhandle.Value ;
        
        % Correlation function *type*
        [rtype, Options.Corr] = uq_process_option(Options.Corr, 'Type',...
            CorrDefaults.Type, 'char');
        if rtype.Invalid
            error('Invalid definition of correlation function type!')
        end
        
        current_input.Internal.Corr.Type = rtype.Value ;
        
        if rtype.Missing
            msg = sprintf('Correlation function type was set to : %s', ....
                current_input.Internal.Corr.Type) ;
            EVT.Type = 'D';
            EVT.Message = msg;
            EVT.eventID = 'uqlab:input:randomfield:init:corrfuntype_defaultsub';
            uq_logEvent(current_input, EVT);
            
        end
        
        % Correlation function *family* (it can be either a string for using
        % the built-in ones or a function handle for using a user-defined
        % one
        [rfamily, Options.Corr] = uq_process_option(Options.Corr, 'Family',...
            CorrDefaults.Family, {'char','function_handle'});
        if rfamily.Invalid
            error('Invalid definition of correlation function family!')
        end
        if rfamily.Missing
            error('A correlation function must be provided!');
        end
        
        current_input.Internal.Corr.Family = rfamily.Value ;
        
        if rfamily.Missing
            if strcmpi(class(rfamily.Value),'function_handle')
                msg = sprintf('Correlation family was set to : %s', ....
                    func2str(current_input.Internal.Corr.Family)) ;
            else
                msg = sprintf('Correlation family was set to : %s', ....
                    current_input.Internal.Corr.Family) ;
            end
            EVT.Type = 'D';
            EVT.Message = msg;
            EVT.eventID = 'uqlab:input:randomfiled:init:corrfamtype_defaultsub';
            uq_logEvent(current_input, EVT);
        end
        
        % Isotropic
        % Is anisotropic an option for this randon field module ?
        % Set the default
        if length(current_input.Internal.Corr.Length) > 1
            CorrDefaults.Isotropic = false ;
        else
            CorrDefaults.Isotropic = true ;
        end
        [risotropic, Options.Corr] = uq_process_option(Options.Corr, 'Isotropic',...
            CorrDefaults.Isotropic, {'double','logical'});
        if risotropic.Invalid
            error('Invalid definition of correlation function''s Isotropic option!')
        end
        
        current_input.Internal.Corr.Isotropic = logical(risotropic.Value) ;
        
        if risotropic.Missing
            if current_input.Internal.Corr.Isotropic
                msg = sprintf('Correlation function is set to *Isotropic* (default)');
            else
                msg = sprintf('Correlation function is set to *Anisotropic* (default)');
            end
            EVT.Type = 'D';
            EVT.Message = msg;
            EVT.eventID = 'uqlab:input:randomfield:init:corrisotropy_defaultsub';
            uq_logEvent(current_input, EVT);
        end
        
        % Nugget
        [nuggetopts, Options.Corr] = uq_process_option(Options.Corr, 'Nugget',...
            CorrDefaults.Nugget, {'double','struct'});
        if nuggetopts.Invalid
            error('Invalid Nugget definition!')
        end
        
        current_input.Internal.Corr.Nugget = nuggetopts.Value;
        % No warning message is printed if the user has not set some nugget value
        
        
        % Check for leftover options inside Options.Corr
        uq_options_remainder(Options.Corr, ...
            ' Random field Correlation function options(.Corr field).');
        
    else
        % If some non-default evalR handle is used, treat all options that
        % are set within the Corr structure as correct and store them
        %
        EVT.Type = 'N';
        EVT.Message = sprintf('Using the user-defined function handle: %s',...
            char(evalRhandle.Value));
        EVT.eventID = 'uqlab:input:randomfield:init:corrhandle_custom';
        uq_logEvent(current_input, EVT);
        
        % all the options that were set by the user inside .Corr are stored
        current_input.Internal.Corr = Options.Corr;
        % make sure that the handle option is there
        current_input.Internal.Corr.Handle = evalRhandle.Value ;
    end
    % Remove Options.Corr
    Options = rmfield(Options,'Corr');
    
else
    % Default substitution of all options related to the correlation
    % function
    msg = sprintf('The default correlation function options are used:\n%s',...
        printfields(CorrDefaults));
    EVT.Type = 'D';
    EVT.Message = msg;
    EVT.eventID = 'uqlab:input:randomfield:init:corrfun_defaultsub';
    uq_logEvent(current_input, EVT);
    
    % No Corr options have been selected so set the default values
    current_input.Internal.Corr = CorrDefaults ;
    
end


%% Initialize Mesh/Domain & Discretization

[RFMesh, Options] = uq_process_option(Options, 'Mesh');
[RFDomain, Options] = uq_process_option(Options, 'Domain');
[RFSPD, Options] = uq_process_option(Options, 'SPD');

MeshDefined = ~RFMesh.Missing ;
DomainDefined = ~RFDomain.Missing ;
SPDDefined = ~RFSPD.Missing ;

if ~MeshDefined && ~DomainDefined
    error('A mesh or a domain must be defined !') ;
    
elseif ~MeshDefined && DomainDefined
    % Assign the domain
    current_input.Internal.Domain = RFDomain.Value ;
    
    % Save the domain range as runtime variable
    current_input.Internal.Runtime.DomainRange = ...
        current_input.Internal.Domain(2,:)  - current_input.Internal.Domain(1,:) ;
    
    if SPDDefined
        current_input.Internal.SPD = RFSPD.Value ;
        SPD = current_input.Internal.SPD ;
    else
        % Use default values
        if size(current_input.Internal.Domain,2) > 1 % Multi-dimensional random field
            if length(current_input.Internal.Corr.Length) > 1
                % Define a number of points for each dimension
                for ii = 1:length(current_input.Internal.Corr.Length) % Anisotropic case
                    SPD(ii) = 1 + 5 * ceil(current_input.Internal.Runtime.DomainRange(ii)/current_input.Internal.Corr.Length(ii));
                end
            else % Isotropic case
                for ii =1:length(current_input.Internal.Corr.Length)
                    SPD(ii) = 1 + 5 * ceil(current_input.Internal.Runtime.DomainRange(ii)/current_input.Internal.Corr.Length);
                end
            end
        else
            SPD = 1 + 5 * ceil(current_input.Internal.Runtime.DomainRange/current_input.Internal.Corr.Length);
        end
    end
    
    % Define the mesh
    switch size(current_input.Internal.Domain,2)
        case 1
            % 1-dimensional case
            current_input.Internal.Mesh = linspace(current_input.Internal.Domain(1,1),current_input.Internal.Domain(2,1), SPD)' ;
            
        case 2
            % 2-dimensional case
            if length(SPD) == 1
                SPD = [SPD , SPD] ;
            end
            
            [xx, yy ] = meshgrid( linspace(current_input.Internal.Domain(1,1), current_input.Internal.Domain(2,1), SPD(1)) , ...
                linspace(current_input.Internal.Domain(1,2), current_input.Internal.Domain(2,2), SPD(2)) ) ;
            
            current_input.Internal.Mesh = [xx(:), yy(:)] ;
            
        otherwise
            
            %  Build an input object and sample from it
            for ii = 1:size(current_input.Internal.Domain,2)
                iopts.Marginals(ii).Type = 'Uniform' ;
                iopts.Marginals(ii).Parameters = current_input.Internal.Domain(:,ii) ;
            end
            myinput = uq_createInput(iopts,'-private') ;
            
            if prod(SPD) > 3000
                warning('The number of samples in the mesh has been rerduced to 3000. \n');
            end
            NSamples = min(3000,prod(SPD)) ;
            % Now sample
            current_input.Internal.Mesh  = uq_getSample(myinput, NSamples) ;
            
    end
    
elseif MeshDefined && ~DomainDefined
    
    % Assign the defined mesh
    current_input.Internal.Mesh = RFMesh.Value ;
    
    % Retrieve the boundaries of the domain using the  given mesh
    current_input.Internal.Domain(1,:) = min(current_input.Internal.Mesh) ;
    current_input.Internal.Domain(2,:) = max(current_input.Internal.Mesh) ;
    
    % Save the domain range as runtime variable
    current_input.Internal.Runtime.DomainRange = ...
        current_input.Internal.Domain(2,:)  - current_input.Internal.Domain(1,:) ;
    
else
    
    % Both Mesh and domain are defined
    current_input.Internal.Mesh = RFMesh.Value ;
    current_input.Internal.Domain = RFDomain.Value ;
    
    % Save the domain range as runtime variable
    current_input.Internal.Runtime.DomainRange = ...
        current_input.Internal.Domain(2,:)  - current_input.Internal.Domain(1,:) ;
end

%% Initialize the covariance mesh (through its properties)

% Specify the number of points in the discretization
if exist('SPD','var')
    current_input.Internal.SPD = SPD;
else
    if SPDDefined
        current_input.Internal.SPD = RFSPD.Value ;
    else
        % Calculate default values
        if size(current_input.Internal.Domain,2) > 1 % Multi-dimensional case
            if length(current_input.Internal.Corr.Length) > 1 % Anisotripic
                for ii = 1:length(current_input.Internal.Corr.Length)
                    current_input.Internal.SPD(ii) = 1 + 5 * ceil(current_input.Internal.Runtime.DomainRange(ii)/current_input.Internal.Corr.Length(ii));
                end
            else % Isotropic
                for ii = 1:length(current_input.Internal.Corr.Length)
                    current_input.Internal.SPD(ii) = 1 + 5 * ceil(current_input.Internal.Runtime.DomainRange(ii)/current_input.Internal.Corr.Length);
                end
            end
        else
            current_input.Internal.SPD = 1 + 5 * ceil(current_input.Internal.Runtime.DomainRange/current_input.Internal.Corr.Length);
        end
    end
end

% Get the dimension of the problem
current_input.Internal.Runtime.Dimension = size(current_input.Internal.Domain,2) ;

%% Initialize the discretization method
[DiscScheme, Options] = uq_process_option(Options, 'DiscScheme', DiscSchemeDefault,'char');
% Make sure that the Discretization scheme is valid
typeKnown = strcmpi(DiscScheme.Value,'kl') || strcmpi(DiscScheme.Value,'eole') ;
if ~typeKnown
    error('Error: Unknown discretization method type: %s !', RFType.Value) ;
end
if DiscScheme.Invalid
    error('Invalid discretization method type !') ;
end

current_input.Internal.DiscScheme = DiscScheme.Value ;

%% Initialize observations
[RFdata, Options] = uq_process_option(Options, 'RFData');

if RFdata.Missing || isempty(RFdata.Value)
    current_input.Internal.RFData = [];
else
    current_input.Internal.RFData = RFdata.Value ;
end
% Make sure that both the inputs and outputs are given, in case data are
% provided by the user
if ~isempty(current_input.Internal.RFData)
    if ~isfield(current_input.Internal.RFData,'X') || isempty(current_input.Internal.RFData.X)
        error('Please provide the input entries of the data!');
    end
    if ~isfield(current_input.Internal.RFData,'Y') || isempty(current_input.Internal.RFData.Y)
        error('Please provide the output entries of the data!');
    end
end

%% Initialize KL/EOLE specific methods

% Default KL options
if strcmpi(current_input.Internal.Corr.Family,'exponential') & ...
        current_input.Internal.Runtime.Dimension <= 2 & ...
        isempty(current_input.Internal.RFData)
    KLDefaults.KL.Method = 'analytical' ;
else
    KLDefaults.KL.Method = 'Nystrom' ;
end

if current_input.Internal.Runtime.Dimension <= 3
    KLDefaults.KL.Quadrature = 'Full' ;
else
    KLDefaults.KL.Quadrature = 'Smolyak' ;
end
KLDefaults.KL.SPC = 5 ;

% Default EOLE options
% Discretization method - Direct EOLE (using posterior covariance in case
% of Kriging) - Option not available to the user.
EOLEDefaults.EOLE.Method = 'direct' ;
EOLEDefaults.EOLE.SPC = 5 ;

if current_input.Internal.Runtime.Dimension <= 3
    EOLEDefaults.EOLE.SPD = 1 + EOLEDefaults.EOLE.SPC * ceil(current_input.Internal.Runtime.DomainRange ./current_input.Internal.Corr.Length) ;
else
    EOLEDefaults.EOLE.SPD = 10 ;
end

if current_input.Internal.Runtime.Dimension > 2
    EOLEDefaults.EOLE.Sampling = 'LHS' ;
else
    EOLEDefaults.EOLE.Sampling = 'grid' ;
end

% Default sampling size (for the covariance mesh) for dimension larger 
% than 2 or when a grid is not used
EOLEDefaults.EOLE.NSamples = 2000 ;

switch lower(current_input.Internal.DiscScheme)
    case 'kl'
        % Set the method
        if isfield(Options, 'KL')
            KLopts.KL = Options.KL;
        else
            KLopts.KL = struct;
        end
        
        % Method
        Method = uq_process_option(KLopts.KL,'Method',KLDefaults.KL.Method);
        % missing & invalid
        if Method.Invalid
            error('The KL method is invalid');
        end
        % assign second level to first level
        current_input.Internal.KL.Method = Method.Value ;
        
        % Quadrature type: Full or Smolyak (only valid for Nyström)
        Quadrature = uq_process_option(KLopts.KL,'Quadrature',KLDefaults.KL.Quadrature);
        % missing & invalid
        if Quadrature.Invalid
            error('The Gaussian quadrature type is invalid');
        end
        % assign second level to first level
        current_input.Internal.KL.Quadrature = Quadrature.Value ;
        
        % Number of samples per correlation length per dimension
        SPC = uq_process_option(KLopts.KL,'SPC',KLDefaults.KL.SPC) ;
        % missing & invalid
        if SPC.Invalid
            error('The Number of samples per correlation length type is invalid') ;
        end
        % Assign second level to first level
        current_input.Internal.KL.SPC = SPC.Value ;
        
        % Now that we have SPC, calculate the default value of SPD
        % Calculate default values
        if current_input.Internal.Runtime.Dimension <= 3
            if size(current_input.Internal.Domain,2) > 1 % Multi-dimensional case
                if length(current_input.Internal.Corr.Length) > 1 % Anisotripic
                    for ii = 1:length(current_input.Internal.Corr.Length)
                        KLDefaults.KL.SPD(ii) = 1 + current_input.Internal.KL.SPC * ceil(current_input.Internal.Runtime.DomainRange(ii)/current_input.Internal.Corr.Length(ii));
                    end
                else % Isotropic
                    for ii = 1:length(current_input.Internal.Corr.Length)
                        KLDefaults.KL.SPD(ii) = 1 + current_input.Internal.KL.SPC * ceil(current_input.Internal.Runtime.DomainRange(ii)/current_input.Internal.Corr.Length);
                    end
                end
            else
                KLDefaults.KL.SPD = 1 + current_input.Internal.KL.SPC * ceil(current_input.Internal.Runtime.DomainRange/current_input.Internal.Corr.Length);
            end
        else
            KLDefaults.KL.SPD = 10 ;
        end
        
        % Process the number of samples per dimension (levels) in the quadrature
        SPD = uq_process_option(KLopts.KL,'SPD',KLDefaults.KL.SPD) ;
        % Invalid
        if SPD.Invalid
            error('The number samples per dimension (SPD) type is invalid');
        end
        
        % assign second level to first level
        current_input.Internal.KL.SPD = SPD.Value ;
        
        % If Smolyak is used only isotropic level is allowed
        if length(current_input.Internal.KL.SPD)>  1 & ...
                strcmpi(current_input.Internal.KL.Quadrature, 'smolyak')
            % Print a warning if the level was actually given by the user
            if ~SPD.Missing
                warning('For Smolyak quadrature, only isotropic SPD are allowed - Using the largst level in all directions.')  ;
            end
            current_input.Internal.KL.SPD = max(current_input.Internal.KL.SPD) ;
        end
        % Save as runtime the number of samples needed for computing the
        % covariance matrix
        current_input.Internal.Runtime.SPD = ...
            current_input.Internal.KL.SPD ;
        
        % Number of points in case of full grid (Computed here only for
        % reference and to return a warning if that number is too large)
        if length(current_input.Internal.KL.SPD) == 1
            NTotal =  current_input.Internal.KL.SPD^current_input.Internal.Runtime.Dimension ;
        else
            NTotal = prod(current_input.Internal.KL.SPD);
        end
        
        % Return a warning and not an error...
        if NTotal > 2000
            warning('The number of points in the mesh is too large and may cause memory issues!') ;
        end
        
        % Initialize the covariance matrix mesh in case of KL:
        switch lower(current_input.Internal.KL.Method)
            case {'analytical','pca','discrete'}
                
                CovMesh = current_input.Internal.Mesh ;

            case 'nystrom'
                % Initialize an empty matrix (will be populated
                % in uq_KL_Nystrom.m
                CovMesh = [] ;
  
            case 'posteriorcovariance'
            if ~exist('myinput', 'var')
                    %  Build an input object - if it wasn't built yet
                    for ii = 1:current_input.Internal.Runtime.Dimension
                        iopts.Marginals(ii).Type = 'Uniform' ;
                        iopts.Marginals(ii).Parameters = current_input.Internal.Domain(:,ii) ;
                    end
                    myinput = uq_createInput(iopts,'-private') ;
                end
                
                
                % Sample the covariance mesh points
                CovMesh = uq_getSample(myinput, ...
                    NTotal, 'LHS');

                lb = min(CovMesh) - 0.1*(range(CovMesh)) ;
                ub = max(CovMesh) + 0.1*(range(CovMesh)) ;

                CovMesh = [CovMesh; lb ; ub];

        end
        current_input.Internal.CovMesh = CovMesh ;
        
    case 'eole'
        % Set the method
        if isfield(Options, 'EOLE')
            EOLEopts.EOLE = Options.EOLE;
        else
            EOLEopts.EOLE = struct;
        end
        
        % % Method
        % Method = uq_process_option(EOLEopts.EOLE,'Method',EOLEDefaults.EOLE.Method);
        % % missing & invalid
        % if Method.Invalid
        %     error('The EOLE method is invalid');
        % end
        % % assign second level to first level
        % current_input.Internal.EOLE.Method = Method.Value ;

        % Sampling type: grid - lhs - mc, etc.
        Sampling = uq_process_option(EOLEopts.EOLE,'Sampling',EOLEDefaults.EOLE.Sampling);
        % missing & invalid
        if Sampling.Invalid
            error('The Gaussian Sampling type is invalid');
        end
        if ~Sampling.Missing & strcmpi(Sampling.Value, 'grid') & ...
                current_input.Internal.Runtime.Dimension > 2
            warning('Full grid sampling is not available for problems of dimension larger than 2. LHS is used instead.')
            Sampling.Value = 'LHS' ;
        end

        % assign second level to first level
        current_input.Internal.EOLE.Sampling = Sampling.Value ;   
        
        % Number of samples per correlation length per dimension
        SPC = uq_process_option(EOLEopts.EOLE,'SPC',EOLEDefaults.EOLE.SPC);
        % missing & invalid
        if SPC.Invalid
            error('The Number of samples per correlation length type is invalid')
        end
        % assign second level to first level
        current_input.Internal.EOLE.SPC = SPC.Value ;
        
        % Now that we have SPC, calculate the default value of SPD
        if current_input.Internal.Runtime.Dimension <= 3
            if size(current_input.Internal.Domain,2) > 1 % Multi-dimensional case
                if length(current_input.Internal.Corr.Length) > 1 % Anisotripic
                    for ii = 1:length(current_input.Internal.Corr.Length)
                        EOLEDefaults.EOLE.SPD(ii) = 1 + current_input.Internal.EOLE.SPC * ceil(current_input.Internal.Runtime.DomainRange(ii)/current_input.Internal.Corr.Length(ii));
                    end
                else % Isotropic
                    for ii = 1:length(current_input.Internal.Corr.Length)
                        EOLEDefaults.EOLE.SPD(ii) = 1 + current_input.Internal.EOLE.SPC * ceil(current_input.Internal.Runtime.DomainRange(ii)/current_input.Internal.Corr.Length);
                    end
                end
            else
                EOLEDefaults.EOLE.SPD = 1 + current_input.Internal.EOLE.SPC * ceil(current_input.Internal.Runtime.DomainRange/current_input.Internal.Corr.Length);
            end
        else
            EOLEDefaults.EOLE.SPD = 10 ;
        end
        
        % Total number of samples per dimension
        SPD = uq_process_option(EOLEopts.EOLE, 'SPD', EOLEDefaults.EOLE.SPD);
        % Invalid
        if SPD.Invalid
            error('The number samples per dimension (SPD) type is invalid');
        end
        % assign second level to first level
        current_input.Internal.EOLE.SPD = SPD.Value ;
        
        % Total number of samples per dimension
        if strcmpi(current_input.Internal.EOLE.Sampling, 'grid')
            NSamples = uq_process_option(EOLEopts.EOLE,'NSamples');
            % missing
            if ~NSamples.Missing
                warning('The total number of samples is ignored when a grid is used: It is computed using .EOLE.SPD!');
            end
            % Compute one using the rule of thumb 5 per correlation length
            % Now sample
            if current_input.Internal.Runtime.Dimension > 1 & ...
                    length(current_input.Internal.EOLE.SPD) == 1
                NSamples.Value = current_input.Internal.EOLE.SPD.^current_input.Internal.Runtime.Dimension;
            else
                NSamples.Value = prod(current_input.Internal.EOLE.SPD) ;
            end
        else
            % When a grid is not used, the default number of samples is
            % 2000
            NSamples = uq_process_option(EOLEopts.EOLE,'NSamples',EOLEDefaults.EOLE.NSamples,'double');
        end
        
        % assign second level to first level
        current_input.Internal.EOLE.NSamples = NSamples.Value ;
        
        if ~NSamples.Missing & strcmpi(current_input.Internal.EOLE.Sampling, 'grid')
            warning('When using a full grid, only the number of samples per dimension is considered (.SPD). The given .NSamples option is ignored!')
        end
        
        
        %% Coordinates of the expansion
        CovMeshopts = uq_process_option(EOLEopts.EOLE,'CovMesh');
        
        if CovMeshopts.Missing
            %  Create a default random field coordinate / grid for EOLE. This is where
            %  the covariance matrix will be computed and discretization actually
            %  carried out
            
            if strcmpi(current_input.Internal.EOLE.Sampling, 'grid') & ...
                    current_input.Internal.Runtime.Dimension <= 2
                switch current_input.Internal.Runtime.Dimension
                    case 1
                        NTotal = current_input.Internal.EOLE.SPD ;
                        
                        VV =   linspace( current_input.Internal.Domain(1), current_input.Internal.Domain(2), NTotal)';
                        
                        CovMesh = VV ;
                        
                    case 2
                        
                        if length(current_input.Internal.EOLE.SPD) == 1
                            SPD = [current_input.Internal.EOLE.SPD, current_input.Internal.EOLE.SPD] ;
                        else
                            SPD = current_input.Internal.EOLE.SPD ;
                        end
                        
                        [A , B ] = meshgrid(current_input.Internal.Domain(1,1) : ...
                            (current_input.Internal.Domain(2,1) - ...
                            current_input.Internal.Domain(1,1))/ ...
                            (SPD(1)-1) : current_input.Internal.Domain(2,1) , ...
                            current_input.Internal.Domain(1,2) : ...
                            (current_input.Internal.Domain(2,2) - ...
                            current_input.Internal.Domain(1,2))/ ...
                            (SPD(2)-1) : current_input.Internal.Domain(2,2));
                        
                        Asize = size(A);
                        NbRFnodes = Asize(1) * Asize(2);
                        VV = cat(2,reshape(A',NbRFnodes,1),reshape(B',NbRFnodes,1));
                        
                        CovMesh = VV ;
                        
                end
                
            else
                
                if ~exist('myinput', 'var')
                    %  Build an input object - if it wasn't built yet
                    for ii = 1:current_input.Internal.Runtime.Dimension
                        iopts.Marginals(ii).Type = 'Uniform' ;
                        iopts.Marginals(ii).Parameters = current_input.Internal.Domain(:,ii) ;
                    end
                    myinput = uq_createInput(iopts,'-private') ;
                end
                
                
                % Sample the covariance mesh points
                CovMesh = uq_getSample(myinput, ...
                    current_input.Internal.EOLE.NSamples, ...
                    current_input.Internal.EOLE.Sampling);
                
            end
            
        else
            % In case .CovMesh is given by the user, check consistency with the
            % discretization method and modify given value if needed
            if size(CovMeshopts.Value,2) ~= current_input.Internal.Runtime.Dimension
                error('The covariance mesh is not consitent with the random field dimension!');
            end
            CovMesh = CovMeshopts.Value ;

            
        end
        
        current_input.Internal.CovMesh = CovMesh ;
end

% Check consistency between the mesh and the expansion order
if ~isempty(current_input.Internal.ExpOrder)
    if ~isempty(current_input.Internal.CovMesh) & ...
            size(current_input.Internal.CovMesh,1) < current_input.Internal.ExpOrder
        fprintf('The expansion order should be smaller or equal to the number of points in the discretization scheme\n');
        fprintf('Please adjust the options .ExpOrder and .SPD or .CovMesh\n');
        error('Expansion order larger than the number of discretization samples!');
    end
end

%% Pass the Kriging model, if any
[RFmodel, Options] = uq_process_option(Options, 'Model');
if RFmodel.Missing || isempty(RFmodel.Value)
    current_input.Internal.RFModel = [];
    current_input.Internal.Runtime.isKriging = false ;
else
    current_input.Internal.RFModel = RFmodel.Value ;
    current_input.Internal.Runtime.isKriging = true ;
end
% No check is necessary as this Kriging model is only passed internally and
% not given by the user - then this should be in runtime, no?

%%
% Initialize the regression options, if any is given - note that this feature
% is only used internally for resampling the Kriging model
[RFReg, Options] = uq_process_option(Options, 'Regression',[]);
current_input.Internal.Regression = RFReg.Value ;

%%%%%%%%%%%%%%%%%%%%%%%%%
%% Perform the discretization

% Create the random field according to one of the two methods (KL or EOLE)
current_input.Internal.RF = uq_createRF(current_input);

% Remove some temporary variables from RF and place them in Runtime to
% clean the output:
if isfield(current_input.Internal.RF , 'EigsFull')
    current_input.Internal.Runtime.EigsFull = current_input.Internal.RF.EigsFull ;
    current_input.Internal.RF  = rmfield(current_input.Internal.RF, 'EigsFull' ) ;
end

% Also remove the trace of the correlation matrix
if isfield(current_input.Internal.RF , 'TraceCorr')
    current_input.Internal.Runtime.TraceCorr = current_input.Internal.RF.TraceCorr ;
    current_input.Internal.RF  = rmfield(current_input.Internal.RF, 'TraceCorr' ) ;
end

%% Create the output fields of the input object and populate them
% Add the 'RF' property to the output
uq_addprop(module,'RF');
module.RF = current_input.Internal.RF;

% Add the Underlying Gaussian property
uq_addprop(module,'UnderlyingGaussian');
module.UnderlyingGaussian = current_input.Internal.UnderlyingGaussian ;


% Add the global input distribution - This is the marginal of the random
% field
IOpts.Marginals.Type = current_input.Internal.RFType ;
IOpts.Marginals.Moments = [current_input.Internal.Mean, current_input.Internal.Std] ;
current_input.Internal.GlobalInput = uq_createInput(IOpts,'-private');

uq_addprop(module,'GlobalInput');
module.GlobalInput = current_input.Internal.GlobalInput ;

success = 1 ;

end


