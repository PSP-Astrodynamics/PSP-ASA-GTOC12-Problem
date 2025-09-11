function Options = uq_Kriging_init_Optim(current_model,Options)
%UQ_KRIGING_INIT_OPTIM processes the optim. opts. to calculate Kriging.
%
%   Options = uq_Kriging_init_Optim(current_model,Options) parses the
%   optimization options used in the calculation of a Kriging metamodel and
%   updates current_model with valid options. The function returns
%   the structure Options not parsed by the function.
%
%   Side-effect:
%   The function will change the current state of current_model,
%   by adding the optimization options to the relavant fields in the
%   current_model.
%
%   See also uq_Kriging_initialize, uq_Kriging_helper_get_DefaultValues.

%% Get the Default Values for Optimizations Options

% Default values for common optimization options
OptimDefaults = uq_Kriging_helper_get_DefaultValues(current_model,'optim');
% Known optimization methods and dependency with MATLAB toolboxes
OptimMethods = uq_Kriging_helper_get_DefaultValues(...
    current_model,'OptimMethods');

%% Parse Optimizations Options (Options.Option)

% Check if Options.Optim is defined
isOptim = get_isOptim(Options);

if isOptim
    % Optim options are given
    % Get optimization method and store it
    
    %% Parse the Optimization *Method* 
    [optimMethod,Options.Optim] = uq_process_option(...
        Options.Optim, 'Method', OptimDefaults.Method, 'char');
            
    if optimMethod.Invalid
        % Get default optimization method based on the available toolboxes
        [optimMethod.Value,EVT] = set_DefaultOptimMethod(...
            optimMethod.Default, 'Invalid optimization method.\n', 'W');
        % Log an event
        uq_logEvent(current_model,EVT);
    end
        
    if optimMethod.Missing || isempty(optimMethod.Value)
        % Check that the available toolboxes (optim and global optim) exist
        % and use the available method
        [optimMethod.Value,EVT] = set_DefaultOptimMethod(...
            optimMethod.Default, 'Missing optimization method.\n', 'D');
        % Log an event
        uq_logEvent(current_model,EVT);        
    end
    
    if any(strcmpi(OptimMethods.Known,optimMethod.Value))
         % Make sure that the selected method exists, or throw an error
        verify_KnownOptimMethod(optimMethod.Value,OptimMethods)
    else
        % Selected method is unknown
        % Select method that are available
        [optimMethod.Value,EVT] = set_DefaultOptimMethod(...
            optimMethod.Default, 'Invalid optimization method.\n', 'W');
        % ...and log a warning
        uq_logEvent(current_model,EVT);
    end

    %% Update the current_model with the optimization *method*
    current_model.Internal.Kriging.Optim.Method = optimMethod.Value;

    optimMethod = upper(current_model.Internal.Kriging.Optim.Method);

    %% Process Required Options that are Common Across Optimization Methods
    Options = process_OptimReqFields(current_model, Options, optimMethod);
    
    % Some options in Options.Optim.(optimMethod) have been set 
    if isfield(Options.Optim,optimMethod)
        %% Process Options that are specific to an Optimization Method   
         Options = process_OptimMethodReqFields(...
             current_model, Options, optimMethod);
 
        % Check for leftover options inside Options.Optim.(optimMethod)
        uq_options_remainder(...
            Options.Optim.(optimMethod),...
            sprintf(' Kriging Optim.%s options.',optimMethod));
        % Remove Options.Optim.(optimMethod)
        Options.Optim = rmfield(Options.Optim,optimMethod);
        
    else
        %% No Options.Optim.(optMethod) have been set, set to default
        process_OptimDefaultsMethod(current_model,optimMethod)
    end

    %% Additional checks for some specific fields
    uq_Kriging_helper_validate_OptimOptions(current_model)
    if isfield(Options.Optim,'InitialValue')
        Options.Optim = rmfield(Options.Optim,'InitialValue');
    end
    if isfield(Options.Optim,'Bounds')
        Options.Optim = rmfield(Options.Optim,'Bounds');
    end

    %% Check for leftover options inside Options.Optim
    uq_options_remainder(Options.Optim,' Kriging Optim options.');

else
    %% No Options.Optim is given, so set all options to the defaults
    
    % Get the .Optim.Display if exists 
    if isfield(Options, 'Optim') && ...
            isfield(Options.Optim, 'Display') && ...
            ~isempty(Options.Optim.Display)
        %...and override the OptimDefaults.Display
        OptimDefaults.Display = Options.Optim.Display;
    end
    % Get the default optim. method according to the available toolboxes
    [optimMethod,EVT] = set_DefaultOptimMethod(...
        OptimDefaults.Method, '', 'D');
    % Log any event (e.g., a warning if the default method is changed)
    uq_logEvent(current_model,EVT);

    % Update the current_model with the default *Optim* structure
    if strcmpi(optimMethod,OptimDefaults.Method)
        OptimDefaults.Method = optimMethod;
        current_model.Internal.Kriging.Optim = OptimDefaults;
    else
        % Override the OptimDefaults.Method,
        % because some required toolboxes are not available
        Options = process_OptimReqFields(...
            current_model, Options, upper(optimMethod));
        process_OptimDefaultsMethod(current_model,optimMethod)
        current_model.Internal.Kriging.Optim.Method = optimMethod;
    end

    % Additional checks for some specific fields
    uq_Kriging_helper_validate_OptimOptions(current_model);

    % Log an event that default values have been used
    msg = sprintf(...
        'Set the values for .Optim to (default):\n%s', ...
        uq_Kriging_helper_print_fields(OptimDefaults));
    EVT.Message = msg;
    EVT.Type = 'D';
    EVT.eventID = 'uqlab:metamodel:kriging:init:optim:all:defaultsub';
    uq_logEvent(current_model,EVT);

end

%% Remove Options.Optim
Options = rmfield(Options,'Optim');

end

%% Local Helper Functions

%%
function isOptim = get_isOptim(Options)
%Check if Options.Optim is defined or specified.
%
%   NOTE: Initialization of Display options adds Optim.Display except when
%   the method is 'none', such that checking if Options.Optim field exists
%   is not straightforward.

if isfield(Options,'Optim')
    if isfield(Options.Optim,'Display')
        if isempty(fieldnames(rmfield(Options.Optim,'Display')))
            % If nothing else other than .Optim.Display,
            % then Options.Optim is not specified
            isOptim = false;
        else
            isOptim = true;
        end
    else
        if isempty(fieldnames(Options.Optim))
            isOptim = false;
        else
            isOptim = true;
        end
    end
else
    isOptim = false;
end

end

%%
function Options = process_OptimReqFields(...
    current_model, Options, optimMethod)
%Process the common required fields of the optimization options.

% Default values for common optimization options
OptimDefaults = uq_Kriging_helper_get_DefaultValues(current_model,'optim');

% Data types for the required common fields
OptimFieldsDataTypes = uq_Kriging_helper_get_DefaultValues(...
    current_model,'OptimFieldsDataTypes');

% Required common fields in optimization options (across methods)
OptimReqFields = uq_Kriging_helper_get_DefaultValues(...
    current_model,'OptimReqFields');

% Required common fields specific to an optimization method
optimReqFieldsMethod = OptimReqFields.(optimMethod);

for ii = 1:numel(optimReqFieldsMethod)
    optimReqField = optimReqFieldsMethod{ii};
        
    %% Parse the common required fields (.Optim.(reqField))
    [optimReqFieldOpts,Options.Optim] = uq_process_option(...
        Options.Optim, optimReqField, ...
        OptimDefaults.(optimReqField),...
        OptimFieldsDataTypes.(upper(optimReqField)));
        
    % Create a character from parsed value
    printedVal = print_val(optimReqFieldOpts.Value);

    if optimReqFieldOpts.Invalid
        % Invalid value for an .Optim field, log an event
        msg = sprintf(...
            ['Invalid value set at: .Optim.%s!',...
            ' Set to (default): %s\n'],...
            optimReqField, printedVal);
        EVT.Type = 'W';
        EVT.Message = msg;
        EVT.eventID = sprintf(...
            'uqlab:metamodel:kriging:init:optim:%s:override',...
            lower(optimReqField));
        uq_logEvent(current_model,EVT);
    end
 
    if optimReqFieldOpts.Missing || isempty(optimReqFieldOpts.Value)
        % Missing value for an .Optim field, log an event
        msg = sprintf(...
            ['Missing value at: .Optim.%s!',...
            ' Set to (default): %s\n'],...
            optimReqFieldsMethod{ii}, printedVal);
        EVT.Type = 'D';
        EVT.Message = msg;
        EVT.eventID = sprintf(...
            'uqlab:metamodel:kriging:init:optim:%s:defaultsub',...
            lower(optimReqFieldsMethod{ii}));
        uq_logEvent(current_model,EVT);
            
        % Overwrite empty field value with the default value
        if isempty(optimReqFieldOpts.Value)
            optimReqFieldOpts.Value = optimReqFieldOpts.Default;
        end
        
    end
       
    %% Update the current_model with the current required field
    current_model.Internal.Kriging.Optim.(optimReqField) = ...
        optimReqFieldOpts.Value;
end

end

%%
function Options = process_OptimMethodReqFields(...
    current_model, Options, optimMethod)
%Process the method-specific fields of the optimization options.

% Data types for the required common fields
OptimFieldsDataTypes = uq_Kriging_helper_get_DefaultValues(...
    current_model,'OptimFieldsDataTypes');

% Default values for fields specific to an optimization method
OptimDefaultsMethod = uq_Kriging_helper_get_DefaultValues(...
    current_model,'OptimDefaultsMethod');

% Get the set of fields specific for a given optimMethod
optimMethodFields = OptimDefaultsMethod.(optimMethod);

% Simply get the names from the given structure
if ~isempty(optimMethodFields)
    optimMethodFields = fieldnames(optimMethodFields);
else
    optimMethodFields = [];
end

for ii = 1:numel(optimMethodFields)
    optimMethodField = optimMethodFields{ii};
    
    %% Parse the Method-specific Optim. Opts (.Optim.(optimMethod).(field))
    [optimMethodFieldOpts,Options.Optim.(optimMethod)] = ...
        uq_process_option(...
                Options.Optim.(optimMethod),...
                optimMethodFields{ii},...
                OptimDefaultsMethod.(optimMethod).(optimMethodField),...
                OptimFieldsDataTypes.(upper(optimMethodField)));

    % Create a character from parsed value
    printedValue = print_val(optimMethodFieldOpts.Value);

    if optimMethodFieldOpts.Invalid
        % Invalid value for a field in Optim.(optimMethod) field,
        % log an event
        msg = sprintf(...
            'Invalid value set at .Optim.%s.%s! Set to (default): %s\n',...
            optimMethod, optimMethodField, printedValue);
        EVT.Type = 'W';
        EVT.Message = msg;
        EVT.eventID = sprintf(...
            'uqlab:metamodel:kriging:init:optim:%s:%s:override',...
            optimMethod, optimMethodField);
        uq_logEvent(current_model,EVT);
    end

    if optimMethodFieldOpts.Missing || isempty(optimMethodFieldOpts.Value)
        % Missing value for a field in Optim.(optimMethod) field,
        % log an event
        % Overwrite empty field value with the default value
        if isempty(optimMethodFieldOpts.Value)
            optimMethodFieldOpts.Value = optimMethodFieldOpts.Default;
            printedValue = print_val(optimMethodFieldOpts.Value);
        end

        msg = sprintf(...
            'Missing value at .Optim.%s.%s! Set to (default): %s\n',...
            optimMethod, optimMethodField, printedValue);
        EVT.Type = 'D';
        EVT.Message = msg;
        EVT.eventID = sprintf(...
            'uqlab:metamodel:kriging:init:optim:%s:%s:default_sub',...
            optimMethod, optimMethodField);
        uq_logEvent(current_model,EVT);        
    end
            
    %% Update current_model with the current method-specific field
    current_model.Internal.Kriging.Optim. ...
        (optimMethod).(optimMethodField) = optimMethodFieldOpts.Value;

end
        
end

%%
function process_OptimDefaultsMethod(current_model,optimMethod)
%Process the method-specific optimization options when they are not given.

% Default values for fields specific to an optimization method
OptimDefaultsMethod = uq_Kriging_helper_get_DefaultValues(...
    current_model,'OptimDefaultsMethod');

% No Options.Optim.(optMethod) have been set, so set them to default
% NOTE: For optMethod = 'none', nothing should happen here
if ~isempty(OptimDefaultsMethod.(optimMethod))
    msg = sprintf(...
        'Set the values for .Optim.%s to (default):\n',...
        optimMethod);
    methodDefaults = fieldnames(OptimDefaultsMethod.(optimMethod));
            
    %% Loop over defaults for a method, create a message, and log the event
    for jj = 1:numel(methodDefaults)
        optimParam = methodDefaults{jj};
        optimParamVal = OptimDefaultsMethod.(optimMethod).(optimParam);
        switch class(optimParamVal)
            case 'double'
                msgNew = sprintf(...
                    ' %s : %s\n',...
                    optimParam,...
                    num2str(optimParamVal));
            case 'char'
                msgNew = sprintf(...
                    ' %s : %s\n', optimParam, optimParamVal);
            otherwise
                msgNew = sprintf(...
                    ' %s : %s\n',...
                    methodDefaults{jj},...
                    ['<',class(methodDefaults{jj}),'>']);
        end
        msg = [msg,msgNew];
    end
    
    % Log an event
    EVT.Type = 'D';
    EVT.Message = msg;
    EVT.eventID = 'uqlab:metamodel:kriging:init:optim:defaultsub';
    uq_logEvent(current_model, EVT);
            
    %% Update the current_model with the the default required field
    current_model.Internal.Kriging.Optim.(optimMethod) = ...
        OptimDefaultsMethod.(optimMethod);
end

end

%%
function [optimMethod,EVT] = set_DefaultOptimMethod(...
    optimMethodDefault, msgChar, evtType)
%Check the optimization method and if required toolbox is N/A, use another.

[optimToolboxExists, gOptimToolboxExists] = get_OptimTBExist();
OptimTB.OptimToolbox = optimToolboxExists;
OptimTB.GlobalOptimToolbox = gOptimToolboxExists;

if ~optimToolboxExists && gOptimToolboxExists
    % Global Optim. toolbox exists, but not optim.; use Genetic Algorithm
    optimMethod = 'GA';
elseif optimToolboxExists && ~gOptimToolboxExists
    % Optim. toolbox exists, but not global optim.; use Hybrid CMAES
    optimMethod = 'HCMAES';
elseif ~optimToolboxExists  && ~gOptimToolboxExists
    % None of the toolboxes are available; use CMAES
    optimMethod = 'CMAES';
else
    % Both toolboxes are available; use the default value
    optimMethod = optimMethodDefault;
end

% Create an event structure
msg = sprintf(...
    '%s%s Set the method to: %s\n',...
    msgChar, uq_Kriging_helper_print_fields(OptimTB), optimMethod);
EVT.Message = msg;

switch lower(evtType)
    case 'w'
        EVT.Type = 'W';
        EVT.eventID = 'uqlab:metamodel:kriging:init:opt:method:override';
    case 'd'
        EVT.Type = 'D';
        EVT.eventID = 'uqlab:metamodel:kriging:init:opt:method:defaultsub';
end

end

%%
function verify_KnownOptimMethod(optimMethod,OptimMethods)
%Verify the selected optimization method is a part of known methods.

[optimTBExists,gOptimTBExists] = get_OptimTBExist();
OptimTB.OptimToolbox = optimTBExists;
OptimTB.GlobalOptimToolbox = gOptimTBExists;

if any(strcmpi(optimMethod,OptimMethods.OptimToolbox))
    % Some optimization methods rely on 'fmincon',
    % a MATLAB function that belongs to the Optimization toolbox
    if ~optimTBExists
        msg = ['The selected algorithm to calculate ',...
            'the Kriging model is not available\n',...
            '''%s'' requires the Optimization toolbox ',...
            'which is not available.\n',...
            'Please select another algorithm or run custom Kriging\n'];
        fprintf(msg,optimMethod)
        msgErr = ['Kriging initialization failed:',...
            'No license for Optimization toolbox!'];
        error(msgErr)
    end
elseif any(strcmpi(optimMethod,OptimMethods.GlobalOptimToolbox))
    % Some optimization methods rely on the 'ga',
    % a MATLAB function that belongs to the Global Optimization toolbox
    if ~gOptimTBExists
        msg = ['The selected algorithm to calculate ',...
            'the Kriging model is not available\n',...
            '''%s'' requires the Global Optimization toolbox ',...
            'which is not available.\n',...
            'Please select another algorithm or run custom Kriging\n'];
        fprintf(msg,optimMethod)
        msgErr = ['Kriging initialization failed:',...
            'No license for Global Optimization toolbox!'];
        error(msgErr)
    end
elseif any(strcmpi(optimMethod,OptimMethods.OptimAndGlobalOptimToolbox))
    % Some optimization methods rely on both 'fmincon' and 'ga'
    if ~(optimTBExists && gOptimTBExists)
        msg = ['The selected algorithm to calculate ',...
            'the Kriging model is not available\n',...
            '''%s'' requires BOTH the Optimization and Global ',...
            'Optimization toolboxes\n',...
            'which either one or both are not available:\n%s',...
            'Please select another algorithm or run custom Kriging\n'];
        fprintf(...
            msg, optimMethod, uq_Kriging_helper_print_fields(OptimTB))
        msgErr = ['Kriging initialization failed: No license for',...
            'either Optimzation or Global Optimization toolbox!'];
        error(msgErr)
    end
end

end

%%
function [optimTBExists,gOptimTBExists] = get_OptimTBExist()
%Return the availability of the required optimization toolboxes.

% Required toolboxes for some optimization methods in the Kriging module
optimToolboxID = 'optimization_toolbox';
globalOptimToolboxID = 'gads_toolbox';

% Check if newer version of Optimization Toolbox is available
% The following private file must exist
newOptimTBExists = ~isempty(which('classifyBoundsOnVars','-all'));

% Note that licenses might be available, but they might not be installed
optimTBExists = logical(license('test',optimToolboxID)) && ...
    logical(exist('fmincon')) && newOptimTBExists;
gOptimTBExists = logical(license('test',globalOptimToolboxID)) && ...
     logical(exist('ga'));

end

%%
function printedVal = print_val(val)
%Create character arrays of a value to be printed.

switch lower(class(val))
    case 'char'
        printedVal = val;
    case 'double'
        if iscolumn(val)
            val = val';
        end
        printedVal = uq_sprintf_mat(val,'%g');
    case 'logical'
        if fieldval.Value
            printedVal = 'true';
        else
            printedVal = 'false';
        end
    case 'function_handle'
        printedVal = func2str(val);
    otherwise
        printedVal = '<not printed>';
end
        
end
