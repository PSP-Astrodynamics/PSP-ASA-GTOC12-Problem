function Options = uq_Kriging_init_Corr(current_model,Options)
%UQ_KRIGING_INIT_CORR processes the correlation function-related options.
%
%   Options = uq_Kriging_init_Corr(current_model,Options) parse the
%   specification of the correlation function specified in the structure
%   Options and update the current_model. The function returns the options
%   not parsed by the function.
%
%   Side-effect:
%   The function will change the current state of current_model,
%   by adding the valid correlation function-related parameters to the
%   fields of the current_model
%
%   See also uq_Kriging_initialize, uq_Kriging_helper_get_DefaultValues.

%% Set local variables
logicalStr = {'true','false'};

%% Get the default values for Correlation function-related options
CorrDefaults = uq_Kriging_helper_get_DefaultValues(current_model,'corr');

%% Parse Correlation function-related Options (Options.Corr) 
if isfield(Options,'Corr')

    %% Parse the *handle* of the Correlation function 
    [EvalRHandle,Options.Corr] = uq_process_option(...
        Options.Corr, 'Handle', CorrDefaults.Handle, 'function_handle');

    if EvalRHandle.Invalid
        error('Invalid definition of the correlation function handle!')
    end

    % If the *handle* is missing, log an event
    if EvalRHandle.Missing
        msg = sprintf(...
            'Correlation function handle is set to (default): %s',...
            func2str(EvalRHandle.Default));
        EVT.Type = 'D';
        EVT.Message = msg;
        EVT.eventID = ['uqlab:metamodel:kriging:init:corr:',...
            'handle_defaultsub'];
        uq_logEvent(current_model,EVT);
    end
    
    % Update the current_model with the correlation *handle*
    current_model.Internal.Kriging.GP.Corr.Handle = EvalRHandle.Value;
        
    if strcmp(char(EvalRHandle.Value),func2str(EvalRHandle.Default))

        %% Parse the *type* of the correlation function
        [RType,Options.Corr] = uq_process_option(...
            Options.Corr, 'Type', CorrDefaults.Type, 'char');

        if RType.Invalid
            msg = 'Invalid definition of the correlation function type!';
            error(msg)
        end
        
        % If the *type* is missing, log an event
        if RType.Missing
            msg = sprintf(...
                'Correlation function type is set to (default): %s',...
                RType.Default);
            EVT.Type = 'D';
            EVT.Message = msg;
            EVT.eventID = ['uqlab:metamodel:kriging:init:corr:',...
                'funtype_defaultsub'];
            uq_logEvent(current_model,EVT);
        end

        % Update the current_model with the correlation *type*
        current_model.Internal.Kriging.GP.Corr.Type = RType.Value;
        
        %% Parse the *family* of the correlation function 
        % It can be either a string for using the built-in ones OR
        % a function handle for using a user-defined one
        [RFamily,Options.Corr] = uq_process_option(...
            Options.Corr, 'Family',...
            CorrDefaults.Family,...
            {'char','function_handle'});

        if RFamily.Invalid
            msg = 'Invalid definition of the correlation function family!';
            error(msg)
        end

        % If the *family* is missing, log an event
        if RFamily.Missing
            msg = sprintf(...
                'Correlation family was set to (default): %s',...
                RFamily.Default);
            EVT.Type = 'D';
            EVT.Message = msg;
            EVT.eventID = ['uqlab:metamodel:kriging:init:corr:',...
                'famtype_defaultsub'];
            uq_logEvent(current_model,EVT);
        end

        % Update the current_model with the correlation *family*
        current_model.Internal.Kriging.GP.Corr.Family = RFamily.Value;

        %% Parse the *isotropy* of the correlation function
        [RIsotropic, Options.Corr] = uq_process_option(...
            Options.Corr, 'Isotropic',...
            CorrDefaults.Isotropic,...
            {'double','logical'});
        
        if RIsotropic.Invalid
            msg = ['Invalid definition of the correlation function''s',...
                'Isotropy!'];
            error(msg)
        end
        
        % If the *isotropy* is missing, log an event
        if RIsotropic.Missing
            msg = sprintf(['Correlation function isotropy is set to ',...
                '(default): %s'], logicalStr{RIsotropic.Default+1});
            EVT.Type = 'D';
            EVT.Message = msg;
            EVT.eventID = ['uqlab:metamodel:kriging:init:corr:',...
                'isotropy_defaultsub'];
            uq_logEvent(current_model,EVT);
        end
        
        % Update the current_model with the *isotropy* of the correlation
        current_model.Internal.Kriging.GP.Corr.Isotropic = logical(...
            RIsotropic.Value);
        
        %% Parse the *nugget* of the correlation function
        [RNugget,Options.Corr] = uq_process_option(...
            Options.Corr, 'Nugget',...
            CorrDefaults.Nugget,...
            {'double','struct'});
        
        if RNugget.Invalid
            error('Invalid Nugget definition!')
        end
        
        % If the *nugget* is missing, log an event
        if RNugget.Missing
            msg = sprintf(['Correlation function nugget is set to ',...
                '(default): %8.3e'], RNugget.Default);
            EVT.Type = 'D';
            EVT.Message = msg;
            EVT.eventID = ['uqlab:metamodel:kriging:init:corr:',...
                'nugget_defaultsub'];
            uq_logEvent(current_model,EVT);
        end

        % Update the current_model with the *nugget* for the correlation
        current_model.Internal.Kriging.GP.Corr.Nugget = RNugget.Value;
        
        %% Check for leftover options inside Options.Corr
        uq_options_remainder(Options.Corr,...
            ' Kriging Correlation function options(.Corr field).');
        
    else
        %% If a non-default evalR handle is used,
        %  treat all options that are set within the Corr structure 
        %  as correct and store them
        msg = sprintf(...
            'Using the user-defined function handle: %s',...
            func2str(EvalRHandle.Value));
        EVT.Type = 'N';
        EVT.Message = msg;
        EVT.eventID = 'uqlab:metamodel:kriging:init:corr:handle_custom';
        uq_logEvent(current_model,EVT);
        
        % Update the current_model with the options set inside Options.Corr
        corrFields = fieldnames(Options.Corr);
        for i = 1:numel(corrFields)
            current_model.Internal.Kriging.GP.Corr.(corrFields{i}) = ...
                Options.Corr.(corrFields{i});
        end
    end

    %% Remove Options.Corr
    Options = rmfield(Options,'Corr');

else
    %% No Options.Corr is specified, log an event and use default
    msg = sprintf(...
        'The default correlation function options are used:\n%s',...
        uq_Kriging_helper_print_fields(CorrDefaults));
    EVT.Type = 'D';
    EVT.Message = msg;
    EVT.eventID = 'uqlab:metamodel:kriging:init:corr:defaultsub';
    uq_logEvent(current_model,EVT);
    
    % Update the current_model with the *default* correlation options
    current_model.Internal.Kriging.GP.Corr = CorrDefaults;
end

end
