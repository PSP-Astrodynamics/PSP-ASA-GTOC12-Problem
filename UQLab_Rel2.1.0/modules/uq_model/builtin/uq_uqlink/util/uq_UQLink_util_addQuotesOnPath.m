function fullnameMod = uq_UQLink_util_addQuotesOnPath(fullname,fileSep)
%UQ_UQLINK_UTIL_ADDQUOTESONPATH adds double quotes on a fullpath w/ spaces.
%
%   Inputs
%   ------
%   - fullname: fullname of a file (path/to/filename), char array
%   - fileSep: directory separator of the path, char
%
%   Output
%   ------
%   - fullnameMod: modified fullname, char array
%       Enclose the path part of the fullname with double quotes if there's
%       whitespace(s) in it.
%
%   Examples
%   --------
%       inpChar = '/usr/bin/My Apps/myExecutable
%       uq_UQLink_util_assertChar(outChar,refChar)
%       %    "/usr/bin/My Apps"/myExecutable

%% Verify inputs
if nargin < 2
    fileSep = filesep;
end

%% Add the double quotes if necessary
splittedFullPath = strsplit(fullname,fileSep);

% Check if path already under double quotes:
if ~isempty(regexp(fullname, '".*?"', 'match'))
    fullnameMod = fullname;
    return
end

% Remove the last element (assumed to be the executable part)
addQuotes = false;
for i = 1:numel(splittedFullPath)-1
    
    spaceExpr = '\s+'; % whitespace (one or more)
    spacesInFullname = regexp(splittedFullPath{i}, spaceExpr, 'match');
    
    if ~isempty(spacesInFullname)
        % Check for linux special character escaping whitespaces
        if isempty(regexp(splittedFullPath{i}, '\\ ', 'match'))
            addQuotes = true;
            break
        end
    end
end

if addQuotes
    fullnameMod = ['"' strjoin(splittedFullPath(1:end-1),fileSep) '"'];
    fullnameMod = strcat(fullnameMod, fileSep, splittedFullPath{end});
else
    fullnameMod = strjoin(splittedFullPath,fileSep);
end

end
