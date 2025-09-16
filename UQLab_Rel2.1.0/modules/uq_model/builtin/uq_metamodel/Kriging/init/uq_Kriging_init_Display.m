function Options = uq_Kriging_init_Display(current_model,Options)
%UQ_KRIGING_INIT_DISPLAY processes the Kriging Display options.
%
%   Options = uq_Kriging_init_Display(current_model,Options) parses the
%   Display options of the Kriging metamodel that controls the verbosity 
%   displayed during the metamodel calculation. The function returns the
%   structure Options with Display according to the global Display
%   variable.
%
%   Note:
%   This function only parses Options.Optim.Display for inconsistent
%   Display options with respect to the selected method. The metamodel
%   object in current_model will not be updated.
%
%   See also uq_Kriging_initialize, uq_Kriging_helper_get_DefaultValues.

%% Set local variables
EVT = [];
% Optimization display default
OptimDefaults = uq_Kriging_helper_get_DefaultValues(current_model,'optim');
% Global verbosity level
DisplayLevel = current_model.Internal.Display; 

%% Set some flags

OptimDisplayExists = isfield(Options,'Optim') && ...
    isfield(Options.Optim, 'Display') && ~isempty(Options.Optim.Display);

OptimMethodNone = isfield(Options,'Optim') && ...
    isfield(Options.Optim,'Method') && ...
    ~isempty(Options.Optim.Method) && ...
    strcmpi(Options.Optim.Method,'none');

%% Remove .Optim.Display for .Optim.Method 'none' as it is not relevant
if OptimMethodNone && OptimDisplayExists
    Options.Optim = rmfield(Options.Optim,'Display');
    OptimDisplayExists = false;
end

%% Set the default Display level
if OptimDisplayExists
    % If Options.Optim is set, then used the valid specified display
    if ~any(strcmpi(Options.Optim.Display,{'none', 'final', 'iter'}))
        EVT.Type = 'W';
        EVT.Message = sprintf(['Unknown display option: %s. ',...
            'Using the default value instead.'], Options.Optim.Display);
        EVT.eventID = 'uqlab:metamodel:kriging:init:display_invalid';
        % Set the default display level
        Options.Optim.Display = OptimDefaults.Display;
    end
else
   % If Options.Optim.Display is not set,
   % use the global verbosity level (Global default: 1) 
   switch lower(DisplayLevel)
       case 0
            if ~OptimMethodNone
                Options.Optim.Display = 'none'; 
            end
        case 1
            if ~OptimMethodNone
                Options.Optim.Display = 'final'; 
            end
        case 2
            if ~OptimMethodNone
               Options.Optim.Display = 'iter'; 
            end
   end
end

if ~isempty(EVT)
    uq_logEvent(current_model,EVT);
end

end