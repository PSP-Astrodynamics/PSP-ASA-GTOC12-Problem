function Options = uq_Kriging_init_EstimMethod(current_model,Options)
%UQ_KRIGING_INIT_ESTIMMETHOD processes the opts. related to estim. method.
%
%   Options = uq_Kriging_init_EstimMethod(current_model,Options) parses the
%   specification of the estimation method specified in the structure
%   Options and update the current_model. The function returns the options
%   not parsed by the function.
%
%   Side-effect:
%   The function will change the current state of current_model,
%   by adding the valid options related to the estimation method
%   (the method and leave-k-out value, if the method is cross validation)
%   to the fields of the current_model.
%
%   See also uq_Kriging_initialize, uq_Kriging_helper_get_DefaultValues.

%% Set local variables
nSample = current_model.ExpDesign.NSamples;

%% Get the default values for the estimation method-related options
EstMethodDefaults = uq_Kriging_helper_get_DefaultValues(...
    current_model,'EstimMethod');

%% Parse Estimation Method - related options (Options.EstimMethod)
if isfield(Options, 'EstimMethod')
    
    %% Parse *EstimMethod*
    [EstMethod,Options] = uq_process_option(...
        Options, 'EstimMethod', EstMethodDefaults.EstimMethod, 'char');

    if EstMethod.Invalid
        error('Invalid Hyperparameter estimation method!')
    end

    % If the *EstimMethod* is missing, log an event
    if EstMethod.Missing
        msg = sprintf(...
            'Hyperparameters estimation method is set to (default): %s',...
            EstMethod.Default);
        EVT.Type = 'D';
        EVT.Message = msg;
        EVT.eventID = 'uqlab:metamodel:kriging:init:estmethod:defaultsub';
        uq_logEvent(current_model,EVT);
    end

    % Update the current_model with the *EstimMethod*
    current_model.Internal.Kriging.GP.EstimMethod = EstMethod.Value;

    switch lower(current_model.Internal.Kriging.GP.EstimMethod)
        % If method is CV make sure that K (is properly defined)
        case 'cv'
            %% Parse *CV* 
            [CV,Options] = uq_process_option(...
                Options, 'CV', EstMethodDefaults.CV, 'struct');
            
            if CV.Invalid
                error('Invalid Cross-Validation method options!')
            end
            
            % If the *CV* is missing, log an event
            if CV.Missing
                msg = sprintf(...
                    ['Using Cross-Validation method, with (default): ',...
                    'Leave-%i-Out or %i-Fold'],...
                    CV.Default.LeaveKOut, nSample);
                EVT.Type = 'D';
                EVT.Message = msg;
                EVT.eventID = ['uqlab:metamodel:kriging:init:',...
                    'estmethod:lko_defaultsub'];
                uq_logEvent(current_model,EVT);
            end

            % Update the current_model with *CV* options
            current_model.Internal.Kriging.GP.CV = CV.Value;
            
            % Make sure that .CV.LeaveKOut is not empty, if so use default
            % and log an event
            if isempty(CV.Value.LeaveKOut)
                msg = sprintf(['Using Cross-Validation method, ',...
                    'with (default): Leave-%i-Out or %i-Fold'],...
                    CV.Default.LeaveKOut, nSample);
                EVT.Type = 'D';
                EVT.Message = msg;
                EVT.eventID = ['uqlab:metamodel:kriging:init:',...
                    'estmethod:lko_defaultsub'];
                uq_logEvent(current_model,EVT);
                CV.Value.LeaveKOut = CV.Default.LeaveKOut;
            end
            
            % Get the number of classes in k-fold CV
            nClasses = ceil(nSample/CV.Value.LeaveKOut);
            
            % If *nClasses* == 1, reduce LeaveKOut
            % until nClasses at least 2 and log an event
            if nClasses == 1
                error(...
                    ['Number of left out sample points (%i) ',...
                    'is greater than the size of ',...
                    'the experimental design (%i)!'],...
                    CV.Value.LeaveKOut, nSample)
            end

            % Update the current_model with the *CV.LeaveKOut* value
            current_model.Internal.Kriging.GP.CV.LeaveKOut = ...
                CV.Value.LeaveKOut;
            
            % Create a random permutation of the exp. design indices.
            randIdx = uq_Kriging_helper_create_randIdx(...
                    CV.Value.LeaveKOut,nSample);
            % Update the current_model with the *CV.RandIdx*
            current_model.Internal.Runtime.CV.RandIdx = randIdx;
    end
else
    %% No Options.EstimMethod is specified, use default and log an event
    msg = sprintf(...
        'The default estimation method options are used:\n%s',...
        uq_Kriging_helper_print_fields(EstMethodDefaults));
    EVT.Type = 'D';
    EVT.Message = msg;
    EVT.eventID = 'uqlab:metamodel:kriging:init:estmethod:defaultsub';
    uq_logEvent(current_model,EVT);
    
    % Update the current_model with the *default* estimation method options
    % NOTE: It is assumed that Options.Corr has been processed.
    current_model.Internal.Kriging.GP = uq_Kriging_helper_merge_structs(...
        current_model.Internal.Kriging.GP,EstMethodDefaults);
    
    % Update the current_model with the *default* CV folds.
    randIdx = uq_Kriging_helper_create_randIdx(...
        EstMethodDefaults.CV.LeaveKOut,...
        nSample);
    current_model.Internal.Runtime.CV.RandIdx = randIdx;
end

% For CV Estimation method, compute the number of classes
% that corresponds to the CV.LeaveKOut Leave-K-Out value
if isfield(current_model.Internal.Kriging.GP,'CV')
    current_model.Internal.Kriging.GP.CV.CV_K = floor(...
        current_model.ExpDesign.NSamples/...
        current_model.Internal.Kriging.GP.CV.LeaveKOut);
end

end
