function foundPattern = uq_UQLink_util_checkForPatternInFiles(filenames,patterns)
%UQ_UQLINK_UTIL_CHECKFORPATTERNINFILES checks if a pattern is found in a 
%   set of files (return, once found in *any* of the files).
%
%   Inputs
%   ------
%   - filenames: a set of filenames, cell array.
%       Any of these files should be openable (either given with fullpath
%       or the files are in the path).
%   - patterns: the patterns to look for in the files, char or cell array.
%       The pattern can either be a char array or a cell array of char
%       array. In the latter, all will be look for in the files.
%
%   Output
%   ------
%   - foundPattern: flag that indicates the pattern is found, logical.
%       The flag is set to true if *any* of the pattern is found in *any* 
%       of the files.

%% Verify inputs

% Make filenames always a cell array of char
if ~iscell(filenames)
    filenames = {filenames};
end

%% Find the pattern
% return, once a pattern found in *any* of the file
foundPattern = false;
for i = 1:numel(filenames)
    
    ftemp = fopen(filenames{i});

    while ~feof(ftemp)
        lineChar = fgetl(ftemp);
        matched = regexp(lineChar, patterns, 'match');
        if any(cellfun(@(x) ~isempty(x),matched))
            foundPattern = true;
            fclose(ftemp);
            return
        end

    end

    fclose(ftemp);

end

end
