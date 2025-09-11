function uniqueID = uq_createUniqueID(base)
%UQ_CREATEUNIQUEID creates a unique ID w/ or w/o randomness.
%
%   UNIQUEID = UQ_CREATEUNIQUEID creates a unique
%   name without any randomness every time the function is called. It uses 
%   the time with precision to several digits beyond decimal point.
%
%   UNIQUEID = UQ_CREATUNIQUEID(BASE) creates a unique ID based on BASE:
%   {'datetime'|'uuid'|'mix'}. 'datetime' is based on time, 'uuid' is based
%   on (random) UUID to ensure absolute uniqueness, and 'mix' combines
%   both. The default BASE is 'datetime'. This function uses
%   <a href="matlab:help tempname">tempname</a> function to create UUID.

%%
if nargin < 1
    base = 'datetime';
else
    base = lower(base);
end

%%
if any(strcmp(base,{'datetime','mix'}))
    dayChar = strrep(date, '-', '');  % e.g., '26Mar2020'
    timeNow = clock;
    clockChar = sprintf('%02d%02d%04d',...
        timeNow(4), timeNow(5), round(timeNow(6)*1e2));

    datetimeID = sprintf('%s_at_%s', dayChar, clockChar);
end

if any(strcmp(base,{'uuid','mix'}))
    [~,uuID] = fileparts(tempname);
end

switch base
    case 'datetime'
        uniqueID = datetimeID;
    case 'uuid'
        uniqueID = uuID;
    case 'mix'
        uniqueID = [datetimeID '_' uuID];
    otherwise
        error('Identifier base not supported.')
end

end
