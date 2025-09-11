function Options = uq_Kriging_init_Scaling(current_model,Options)
%UQ_KRIGING_INIT_Scaling processes the options to scale the exp. design.
%
%   Options = uq_Kriging_init_Scaling(current_model,Options) parses the
%   options to scale the experimental design and updates the current_model
%   with the parameters used to scale the design. The function returns 
%   the structure Options not parsed by the function.
%
%   Side-effect:
%   The function will change the current state of current_model,
%   by adding the parameters used to scale the experimental design already 
%   stored in the current_model.
%
%   See also uq_Kriging_initialize, uq_Kriging_helper_get_DefaultValues.

%% Set local variable
logicalStr = {'false','true'};

% Add *MissingScaling* flag to the Options
Options.MissingScaling = false;

%% Get the default values for Correlation function-related options
ScalingDefaults = uq_Kriging_helper_get_DefaultValues(...
    current_model,'Scaling');

%% Parse Scaling-related Options (Options.Scaling)

% NOTE: The 'struct' case is included for the case of having a user-defined
% auxiliary space, BUT this is NOT yet implemented!
[Scaling,Options] = uq_process_option(...
    Options, 'Scaling',...
    ScalingDefaults,...
    {'logical', 'double', 'uq_input', 'struct'});

% If *Scaling* is invalid, log an event;
% Default value is assigned implicitly.
if Scaling.Invalid
    msg = sprintf(...
        'Scaling option is invalid and set to (default): %s',...
        logicalStr{Scaling.Default+1});
    EVT.Message = msg;
    EVT.Type = 'W';
    EVT.eventID = ['uqlab:metamodel:kriging:init:scaling:',...
        'invalid_defaultsub'];
    uq_logEvent(current_model,EVT);
end

% If *Scaling* is missing, log an event; 
% Default value is assigned implicitly
if Scaling.Missing
    msg = sprintf(...
        'Scaling option is missing and set to (default): %s',...
        logicalStr{Scaling.Default+1});
    EVT.Message = msg;
    EVT.Type = 'D';
    EVT.eventID = ['uqlab:metamodel:kriging:init:scaling:',...
        'missing_defaultsub'];
    uq_logEvent(current_model,EVT);
    % Update the Options with the *MissingScaling* flag
    Options.MissingScaling = true;
end

% If *Scaling* is empty, log an event
if isempty(Scaling.Value)
    msg = sprintf(...
        'Scaling option is empty and set to (default): %s',...
        logicalStr{Scaling.Default+1});
    EVT.Message = msg;
    EVT.Type = 'D';
    EVT.eventID = ['uqlab:metamodel:kriging:init:scaling:',...
        'missing_defaultsub'];
    uq_logEvent(current_model,EVT);
    % Explicitly assign default value
    Scaling.Value = Scaling.Default;
end

% Update the current_model with the *Scaling* option
current_model.Internal.Scaling = Scaling.Value;

%% Get the scaling parameters and update the current_model

% Check if Scaling.Value can be taken as a Boolean
isScalingBool = isa(Scaling.Value,'double') || ...
    isa(Scaling.Value,'logical') || ...
    isa(Scaling.Value,'int');

% Check whether an INPUT object has been defined
inputExists = isfield(current_model.Internal,'Input') && ...
    ~isempty(current_model.Internal.Input);

% Get the scaling parameter
if isScalingBool && Scaling.Value
    if inputExists
        % The experimental design is scaled as U = (X-muX) / stdX, 
        % where muX and stdX are computed from the moments of the marginal
        % distributions of the specified INPUT object
        inputMoments = reshape(...
            [current_model.Internal.Input.Marginals(:).Moments], 2, []);
        % Update the current_model
        % Update the current_model with *mean* of the INPUT marginals        
        current_model.Internal.ExpDesign.muX = inputMoments(1,:);
        % Update the current_model with *std.dev* of the INPUT marginals        
        current_model.Internal.ExpDesign.sigmaX = inputMoments(2,:);
    else
        % The experimental design is scaled as U = (X-muX)/stdX,
        % where muX and stdX are computed empirically
        % from the available data
        % Update the current_model with *mean* of the available data
        current_model.Internal.ExpDesign.muX = mean(...
            current_model.ExpDesign.X);
        % Update the current_model with *std.dev* of the available data
        current_model.Internal.ExpDesign.sigmaX = std(...
            current_model.ExpDesign.X);
    end
    else
end

%% Create Scaling INPUT object if a structure is passed as scaling options
isScalingStruct = isa(Scaling.Value,'struct');

if ~isScalingBool
    if ~inputExists
        msg = ['An INPUT object needs to be specified ',...
            'for the selected scaling option!'];
       error(msg) 
    end

    if isScalingStruct
        % Create an INPUT object based on the options passed in Scaling
        % and update the current_model with the *Scaling* option
       current_model.Internal.Scaling = uq_createInput(...
           Scaling.Value,'-private');
    end
end

end