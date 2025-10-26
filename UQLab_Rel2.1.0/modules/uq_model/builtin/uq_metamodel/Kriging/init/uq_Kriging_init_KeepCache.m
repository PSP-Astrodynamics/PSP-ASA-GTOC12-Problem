function Options = uq_Kriging_init_KeepCache(current_model,Options)
%UQ_KRIGING_INIT_KEEPCACHE processes the flag to cache important matrices.
%
%   Options = uq_Kriging_init_KeepCache(current_model,Options) parses the
%   flag to keep the important auxiliary matrices used to speed up some
%   Kriging metamodel evaluations. The function updates the current_model
%   and returns the structure Options not parsed by the function.
%
%   Side-effect:
%   The function will change the current state of current_model,
%   by adding the valid KeepCache flag to the fields of the current_model.
%
%   See also uq_Kriging_initialize, uq_Kriging_helper_get_DefaultValues.

%% Set local variable
logicalStr = {'false','true'};

%% Get the default values for KeepCache flag
keepCacheDefault = uq_Kriging_helper_get_DefaultValues(...
    current_model,'KeepCache');

%% Keep cache?
[KeepCache, Options] = uq_process_option(...
    Options, 'KeepCache', keepCacheDefault, {'logical','double'});

% If *KeepCache* is invalid, log an event and assign default value
if KeepCache.Invalid 
    msg = sprintf(...
        'KeepCache option is invalid and set to (default): %s',...
        logicalStr{KeepCache.Default+1});
    EVT.Message = msg;
    EVT.Type = 'W';
    EVT.eventID = ['uqlab:metamodel:kriging:init:keepcache:',...
        'invalid_defaultsub'];
    uq_logEvent(current_model,EVT);
end

% If *KeepCache* is missing, log an event and assign default value
if KeepCache.Missing
    msg = sprintf(...
        'KeepCache option is missing and set to (default): %s',...
        logicalStr{KeepCache.Default+1});
    EVT.Message = msg;
    EVT.Type = 'D';
    EVT.eventID = ['uqlab:metamodel:kriging:init:keepcache:',...
        'missing_defaultsub'];
    uq_logEvent(current_model,EVT);
end

% If *KeepCache* is empty, log an event and assign default value
if isempty(KeepCache.Value)
    msg = sprintf(...
        'KeepCache option is empty and set to (default): %s',...
        logicalStr{KeepCache.Default+1});
    EVT.Message = msg;
    EVT.Type = 'D';
    EVT.eventID = ['uqlab:metamodel:kriging:init:keepcache:',...
        'empty_defaultsub'];
    uq_logEvent(current_model,EVT);
    KeepCache.Value = KeepCache.Default;
end

% Update the current_model with the *KeepCache* flag
current_model.Internal.KeepCache = KeepCache.Value;

end