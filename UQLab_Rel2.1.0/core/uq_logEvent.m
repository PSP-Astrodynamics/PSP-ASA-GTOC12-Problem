function EVENT = uq_logEvent(module, eventInfo)


%% Input argument checks and parsing (if necessary)

if nargin < 2
   error('uq_logEvent(module, eventInfo) must be called with at least two input arguments: module and eventInfo');
end

if ~(isa(module, 'uq_model') || isa(module, 'uq_analysis') || isa(module, 'uq_input') || isa(module, 'uq_dispatcher') || isa(module, 'uq_workflow'))
    error('The module argument must be a valid UQLab object');
end

if ~isa(eventInfo, 'struct')
    error('eventInfo must be a structure')
end

if ~isfield(eventInfo, 'Type')
    eventInfo.Type = 'II';
end

if ~isfield(eventInfo, 'eventID')
    eventInfo.eventID = ['uqlab:' module.Type ':unspecified_ID'];
end

if ~isfield(eventInfo, 'Message')
    eventInfo.Message = 'Unspecified message';
end

%% Event processing

% now add all of the necessary information to the EVENT output
EVENT = eventInfo;
% add the event field if not existing, add a new one if existing
if ~isfield(module.Internal, 'eventLog') 
    EVENT.ID = 1;
    module.Internal.eventLog = EVENT;
else
    EVENT.ID = length(module.Internal.eventLog)+1;
    ff = fieldnames(EVENT);
    
    for ii = 1:numel(ff)
        module.Internal.eventLog(EVENT.ID).(ff{ii}) = EVENT.(ff{ii});
    end
end