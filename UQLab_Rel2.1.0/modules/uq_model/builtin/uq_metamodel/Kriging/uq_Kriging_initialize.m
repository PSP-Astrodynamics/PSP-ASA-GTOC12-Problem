function success = uq_Kriging_initialize(current_model)
%UQ_KRIGING_INITIALIZE initializes a Kriging model with user-spec. options.
%
%   SUCCESS = UQ_KRIGING_INITIALIZE(CURRENT_MODEL) initializes
%   the CURRENT_MODEL as a Kriging model and returns the status of the
%   initialization.
%
%   NOTE:
%   The order of parsing the fields in the options are fixed and should not
%   be re-ordered arbitrarily.
% %
%   See also UQ_INITIALIZE_UQ_METAMODEL, UQ_KRIGING_INITIALIZE_CUSTOM

%% Set local variables

% Skipped fields are unprocessed fields, dealt with external functions
skipFields = {'Type', 'Name', 'MetaType', 'Input', 'FullModel',...
    'ExpDesign', 'Display', 'ValidationSet'};

% Retrieve the options
Options = current_model.Options;

%% Initializes Kriging metamodel object
try
    %% Parse global DISPLAY variable, convert to local Kriging module key
    Options = uq_Kriging_init_Display(current_model,Options);

    %% METATYPE
    % Meta Type
    if ~isfield(Options, 'MetaType') || isempty(Options.MetaType)
        error('MetaType must be specified.');
    end

    uq_addprop(current_model, 'MetaType', Options.MetaType);
    uq_addprop(current_model, 'Internal');

    %% Process the Input-related Options (Options.Input)
    % NOTE: Most of the Input-related Options are already processed outside
    % this specific Kriging initialization function.
    Options = uq_Kriging_init_Input(current_model,Options);

    %% Process the Scaling-related Options (Options.Scaling)
    Options = uq_Kriging_init_Scaling(current_model,Options);

    %% Process KeepCache Flag (Options.KeepCache)
    Options = uq_Kriging_init_KeepCache(current_model,Options);

    %% Parse Trend-Related Options (Options.Trend)
    Options = uq_Kriging_init_Trend(current_model,Options);

    %% Process Correlation function-related Options (Options.Corr)
    Options = uq_Kriging_init_Corr(current_model,Options);

    %% Process Estimation method-related Options (Options.EstimMethod)
    Options = uq_Kriging_init_EstimMethod(current_model,Options);

    %% Parse Optimization-related options
    Options = uq_Kriging_init_Optim(current_model,Options);

    %% Generate the initial experimental design
    % Get X and update current_model
    [current_model.ExpDesign.X,current_model.ExpDesign.U] = ...
        uq_getExpDesignSample(current_model);
    % Get Y and update current_model
    current_model.ExpDesign.Y = uq_eval_ExpDesign(current_model,...
        current_model.ExpDesign.X);
    % Update the number of outputs of the model and update current_model
    Nout = size(current_model.ExpDesign.Y,2);
    current_model.Internal.Runtime.Nout = Nout;

    %% Parse and update the Regression options
    Options = uq_Kriging_init_Regression(current_model,Options);

    %% Parse Gaussian Random Field related options
    Options = uq_Kriging_init_GRF(current_model,Options);

    %% Special treatment to check and remove constants if no input is given and yet there are constant coluns in the provided ED
    if ~current_model.Internal.Runtime.InputExists
        if ~isfield(current_model.Internal.ExpDesign,'sigmaX')
            % If there is no scaling, compute the standard deviation anyways as
            % this information will be used to remove constants when ED is given
            % without an Input object
            current_model.Internal.ExpDesign.muX = mean(...
                current_model.ExpDesign.X); % Actually not necessary but evaluated for consistency
            % Update the current_model with *std.dev* of the available data
            current_model.Internal.ExpDesign.sigmaX = std(...
                current_model.ExpDesign.X);
        end
        NonConstIdx = find(current_model.Internal.ExpDesign.sigmaX ~= 0);
        current_model.Internal.Runtime.MnonConst = numel(NonConstIdx);
        current_model.Internal.Runtime.nonConstIdx = NonConstIdx ;
    end
    
    %% Check for unused options
    % Remove some fields that are not processed here:
    fieldsToRemove = skipFields(isfield(Options,skipFields));

    Options = rmfield(Options,fieldsToRemove);

    % Check if there was something else provided.
    uq_options_remainder(...
        Options, current_model.Name, skipFields, current_model);

    %% Update with flag of a custom Kriging model
    current_model.Internal.Runtime.isCustom = false;

    %% Add the property where the main Kriging results are stored
    uq_addprop(current_model,'Kriging');
    success = true;
catch e
    error(e.message)
    success = false;
end

end
