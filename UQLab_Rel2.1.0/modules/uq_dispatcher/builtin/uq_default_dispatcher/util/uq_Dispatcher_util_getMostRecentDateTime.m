function timestamp = uq_Dispatcher_util_getMostRecentDateTime(timestamps)
%UQ_DISPATCHER_UTIL_GETMOSTRECENTDATETIME gets the most recent date time
%   from a list of datetimes in char (dateformat = 'dd/mm/yy HH:MM:SS PM').

%% Parse and verify inputs
numTimestamps = numel(timestamps);

% Only one elements, immediately return
if numTimestamps == 1
    timestamp = timestamps{1};
    return
end

%% Get the largest datenums
% Convert to serial date number
dateFormat = 'dd/mm/yy HH:MM:SS PM';
dateNums = uq_map(@(X,P) datenum(X,P), timestamps,...
    'Parameters', dateFormat, 'ExpandCell', false);
dateNums = [dateNums{:}];

%% Get the most recent date
[~,maxIdx] = max(dateNums);
timestamp = timestamps{maxIdx};

end
