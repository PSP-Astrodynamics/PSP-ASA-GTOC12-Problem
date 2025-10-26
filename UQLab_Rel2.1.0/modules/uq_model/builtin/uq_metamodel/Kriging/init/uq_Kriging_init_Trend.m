function Options = uq_Kriging_init_Trend(current_model,Options)
%UQ_KRIGING_INIT_TREND processes the Kriging trend-related options.
%
%   Options = uq_Kriging_init_Trend(current_model,Options) parse the
%   specification of the Kriging trend specified in the structure Options
%   and update the current_model. The function returns the input structure
%   Options not parsed by the function.
%
%   Side-effects:
%   - The function will change the current state of current_model,
%     by adding the valid Trend-related parameters to the appropriate
%     fields of the current_model.
%   - If a custom function handle to evaluate observation matrix F is used
%     and the scaling is not set, the value of Scaling (whatever it is) is
%     changed to false (i.e., not scaled) to avoid confusion.
%
%   See also uq_Kriging_initialize, uq_Kriging_helper_get_DefaultValues.

%% Set local variables

% Number of input dimensions
M = current_model.Internal.Runtime.M;

%% Get the default values for Correlation function-related options
TrendDefaults = uq_Kriging_helper_get_DefaultValues(current_model,'trend');

%% Parse Kriging trend-related information (Options.Trend)
if isfield(Options,'Trend')

    %% Parse the *handle* of the Trend function
    [TrendHandle,~] = uq_process_option(...
        Options.Trend, 'Handle', TrendDefaults.Handle, 'function_handle');

    if TrendHandle.Invalid
        msg = 'Invalid definition of the trend function handle!';
        error(msg)
    end

    % If the *handle* is missing or empty, log an event
    if TrendHandle.Missing || isempty(TrendHandle.Value) 
        msg = sprintf(...
            'Trend function handle is set to (default): %s',...
            func2str(TrendHandle.Default));
        EVT.Type = 'D';
        EVT.Message = msg;
        EVT.eventID = ['uqlab:metamodel:kriging:init:trend:handle:',...
            'defaultsub'];
        uq_logEvent(current_model,EVT);
    end
    
    trendHandle = TrendHandle.Value;

    if strcmp(func2str(trendHandle),func2str(TrendDefaults.Handle))
        %% Use the built-in handle to evaluate the observation matrix F

        %% Parse the whole contents of *Trend* structure
        [TrendOpts,Options] = uq_process_option(...
            Options, 'Trend', TrendDefaults, 'struct');

        % If *Trend* is invalid, throw an error
        if TrendOpts.Invalid
            msg = 'Invalid trend definition!';
            error(msg)
        end
        
        Trend = TrendOpts.Value;

        % Force the default trend to be 0 if the user has chosen simple
        % Kriging but did not specify a trend
        if strcmpi(Trend.Type,'simple') && isempty(Trend.CustomF)
            Trend.CustomF = zeros(1,M) ;
        end
        % NOTE: The trendtype MUST be set in to further define other trend
        % options, otherwise REVERT everything to default
        if ~isfield(Trend,'Type') || isempty(Trend.Type)
            msg = ['No trend type was defined, thus the rest of ',...
                'the options inside the Trend struct are ignored. ',... 
                'The default trend values are used instead.'];
            EVT.Message = msg;
            EVT.Type = 'W';
            EVT.eventID = 'uqlab:metamodel:kriging:init:trend:override';
            uq_logEvent(current_model, EVT);

            % Revert trend to its default
            Trend = TrendOpts.TrendDefaults;
        end
        
        %% Initialize the trend function
        if Options.InputExists
            [Trend,EVT] = uq_Kriging_initialize_trend(...
                Trend, M, current_model.Internal.Input, TrendDefaults);
        else
            [Trend,EVT] = uq_Kriging_initialize_trend(...
                Trend, M, [], TrendDefaults);
        end
    
        % Log any returned event
        if ~isempty(EVT)
            uq_logEvent(current_model,EVT);
        end

        % Update the current_model with the *Trend* options
        current_model.Internal.Kriging.Trend = Trend;
        
    else        
        %% Use a user-specified handle to evaluate the observation matrix F
        %  By-pass all the additional checks and accept all the supplied
        %  options "as is".
    
        % Log an event
        msg = sprintf('Trend: using the user-defined function handle: %s',...
            char(trendHandle));
        EVT.Message = msg;
        EVT.Type = 'N';
        EVT.eventID = 'uqlab:metamodel:kriging:init:trend:Fhandle_custom';
        uq_logEvent(current_model,EVT);

        % Update the current model with the *Trend* options
        current_model.Internal.Kriging.Trend = Options.Trend; 

        % NOTE: For now, a trend type field is assigned, so that this case
        % is easily compatible with the built-in one
        current_model.Internal.Kriging.Trend.Type = 'unknown';

        %% IMPORTANT: If the scaling is not set, revert the value to false
        %  to avoid confusion
        if Options.MissingScaling
            msg = ['The Scaling option is reverted to ''false'' ',...
                'because a custom trend is used.'];
            EVT.Message = msg;
            EVT.Type = 'W';
            EVT.eventID = ['uqlab:metamodel:kriging:init:scaling:',...
                'revert_custom_trend'];
            uq_logEvent(current_model,EVT);
            % Update the current_model with the *Scaling* option
            current_model.Internal.Scaling = false;
        end
        
        % Remove Options.Trend
        Options = rmfield(Options,'Trend');
    end

else
    %% No Options.Trend is specified, log an event and use default
    msg = sprintf(...
        'The default trend function options are used:\n%s',...
        uq_Kriging_helper_print_fields(TrendDefaults));
    EVT.Message = msg;
    EVT.Type = 'D';
    EVT.eventID = 'uqlab:metamodel:kriging:init:trend:defaultsub';
    uq_logEvent(current_model,EVT);

    Trend = TrendDefaults;
    
    %% Initialize default Kriging Trend
    if Options.InputExists
        [Trend,EVT] = uq_Kriging_initialize_trend(...
            Trend, M, current_model.Internal.Input, TrendDefaults);
    else
        [Trend,EVT] = uq_Kriging_initialize_trend(...
            Trend, M, [], TrendDefaults);
    end

    % log the returned event, if any
    if ~isempty(EVT)
        uq_logEvent(current_model,EVT);
    end
    
    % Update the current_model with the correlation *handle*
    current_model.Internal.Kriging.Trend = Trend;

end

% Remove processed field from Options
Options = rmfield(Options,'InputExists');
Options = rmfield(Options,'MissingScaling');

end
