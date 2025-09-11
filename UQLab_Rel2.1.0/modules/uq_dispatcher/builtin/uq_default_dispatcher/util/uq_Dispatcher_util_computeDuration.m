function durationStr = uq_Dispatcher_util_computeDuration(datetime1,datetime2)
%UQ_DISPATCHER_UTIL_COMPUTEDURATION computes the duration between two dates
%   and return the duration as a char.
%
%   Inputs
%   ------
%   - datetime1: char, the first date and time
%       The format is 'dd/mm/yy HH:MM:SS PM'.
%   - datetime2: char, the second date and time
%       The format is 'dd/mm/yy HH:MM:SS PM'.
%       If datetime2 is earlier than datetime1, the duration is set to 0.
%
%   Output
%   ------
%   - duration: char, the duration in formatted char
%       The format is 'dd days hh hours mm mins ss secs' if dd > 0,
%       otherwise 'hh hours mm mins and ss secs'. Note that dd is not
%       limited to two characters, but however many characters the number 
%       required.
%
%   Example
%   -------
%       datetime1 = '06/03/20 10:29:29 AM';
%       datetime2 = '06/03/20 10:57:19 AM';
%       uq_Dispatcher_util_computeDuration(datetime1,datetime2)
%       % 00 hrs 27 mins 20 secs
%
%       datetime1 = '13/01/20 10:24:50 AM';
%       datetime2 = '06/02/21 11:29:59 PM';
%       uq_Dispatcher_util_computeDuration(datetime1,datetime2)
%       % 390 days 13 hrs 05 mins 09 secs

%% Convert to a date vector ([Y,MO,D,H,MI,S])
dateFormat = 'dd/MM/uu hh:mm:ss aa';
d2 = datetime(datetime2,'InputFormat',dateFormat);
d1 = datetime(datetime1,'InputFormat',dateFormat);
dt = d2-d1;

%% Compute the difference (in seconds)

if d2 < d1
    % Make sure there won't be a negative duration
    dt = duration([0 0 0]);
end

%% Compute days, hours, minutes, and seconds

[durationHours,durationMinutes,durationSeconds] = hms(dt);
durationHours = mod(durationHours,24);

durationDays = floor(days(dt));

durationStr = '';
if durationDays > 0
    durationStr = sprintf('%s days ',num2str(durationDays));
end

durationStr = sprintf('%s%02d hrs %02d mins %02d secs',...
    durationStr, durationHours, durationMinutes, durationSeconds);

end
