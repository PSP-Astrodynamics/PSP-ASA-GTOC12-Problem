function varargout = uq_reportEvents(module, Filters)

%% OPTION PARSING 
if ~nargin
    error('No object specified');
end

% option parsing
if exist('Filters', 'var') && ~isempty(Filters)
    if ~isa(Filters, 'struct')
       error('The FILTERS option must be a structure') ;
    end
    
    Options = lower(fieldnames(Filters));
    ss = strfind(Options,'type');
    if ~isempty([ss{:}])
        TypeFilter = Filters.Type;
    else
        TypeFilter = '*';
    end
    
    ss = strfind(Options,'eventid');
    if ~isempty([ss{:}])
        eventIDFilter = Filters.eventID;
    else
        eventIDFilter = '*';
    end
end

% define defaults if they were not assigned at this stage
if ~exist('TypeFilter', 'var')
    TypeFilter = '*';
end
if ~exist('eventIDFilter', 'var')
    eventIDFilter = '*';
end

if isfield(module.Internal, 'eventLog')
    EVENTLOG = module.Internal.eventLog;
else EVENTLOG = [];
end


if isempty(EVENTLOG)
   fprintf('No events in the specified object\n');
   varargout{1} = [];
   return;
end


%% NOW APPLY THE FILTERS, IF SPECIFIED
idx = true(size(EVENTLOG));

% select only the specified type
if ~isempty(TypeFilter)
    if ~strcmp('*', TypeFilter)
        TT = {EVENTLOG.Type};
        %TTidx = strfind(TT, TypeFilter);
        for ii = 1:length(TT)
            idx(ii) = idx(ii) && strcmp(TT{ii}, TypeFilter);
        end
    end
end

% select only the specified eventid
if ~isempty(eventIDFilter)
    if ~strcmp('*', eventIDFilter)
        EE = {EVENTLOG.eventID};
        EEidx = strfind(EE, eventIDFilter);
        for ii = 1:length(TTidx)
            idx(ii) = idx(ii) && ~isempty(EEidx{ii});
        end
    end
end

% trim the events
EVENTLOG = EVENTLOG(idx);

%% PRINT OUT THE LIST OF EVENTS AND RETURN IT
% Collect statistics
NEVENTS = length(EVENTLOG);

% warnings
WIDX = true(size(EVENTLOG));
for ii = 1:NEVENTS
    WIDX(ii) = strcmp(EVENTLOG(ii).Type, 'W');
end
NW = sum(WIDX);
WLOG = EVENTLOG(WIDX);

% default substitutions
DIDX = true(size(EVENTLOG));
for ii = 1:NEVENTS
    DIDX(ii) = strcmp(EVENTLOG(ii).Type, 'D');
end
ND = sum(DIDX);
DLOG = EVENTLOG(DIDX);

% Notices
NIDX = true(size(EVENTLOG));
for ii = 1:NEVENTS
    NIDX(ii) = strcmp(EVENTLOG(ii).Type, 'N');
end
NN = sum(NIDX);
NLOG = EVENTLOG(NIDX);

% any other entry
MISCIDX = true(size(EVENTLOG)) & ~DIDX & ~WIDX & ~NIDX;
MISCLOG = EVENTLOG(MISCIDX);
NMISC = sum(MISCIDX);

% print out the collected statistics
fprintf('A total of %d messages were logged in object ''%s'': \n%d warnings \n%d default substitutions\n%d notices\n', NEVENTS, module.Name, NW, ND,NN);
for ii = 1:NEVENTS
    
end

%% ASSIGN THE OUTPUTS
if nargout
    % return the list
   varargout{1} = EVENTLOG;
end

%% PRINT THE WARNINGS/MESSAGES
% warnings:

for ii = 1:NW
    print_logEntry(WLOG(ii));
end

for ii = 1:ND
    print_logEntry(DLOG(ii));
end

for ii = 1:NN
    print_logEntry(NLOG(ii));
end



for ii = 1:NMISC
    print_logEntry(MISCLOG(ii));
end

function print_logEntry(logEntry)
fprintf('%s: %s (eventID: %s)\n', logEntry.Type, logEntry.Message, logEntry.eventID)