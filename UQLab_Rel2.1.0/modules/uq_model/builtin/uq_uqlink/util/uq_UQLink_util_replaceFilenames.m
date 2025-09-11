function outChar = uq_UQLink_util_replaceFilenames(...
    inpChar, oldBasenames, newBasenames, extensions)    
%UQ_UQLINK_UTIL_REPLACEFILENAMECHAR replaces filenames inside a char-array 
%   with new filenames. If no extensions are specified, it matches without.
%
%   Inputs
%   ------
%   - inpChar: input string, char array
%   - oldBasenames: list of old file basenames to replace, cell array
%   - newBasenames: list of new file basenames to replace with, cell array
%   - extensions: list of extensions of the files (no period), cell array
%       If this is not given then only the filenames are replaced.
%       Providing an extension results in a more specific operation.
%       Sometimes it's only the extension that differentiate between files
%       of the same names.
%
%   Output
%   ------
%   - outChar: string with old filenames replaced with new ones, char array

%% Verify inputs
if nargin < 4
    extensions = '';
end

if ~iscell(extensions)
    extensions = {extensions};
end

%% Replace the filenames
emptyExtension = cellfun(@(x) isempty(x), extensions);

if all(emptyExtension)
    % No file extension provided,
    % directly replace the filename without extension
    outChar = regexprep(inpChar, oldBasenames, newBasenames);
else
    % Create filenames: basename + '.' + respective extension
    % NOTE: filename+extension is used as the pattern in regexprep, 
    %       use '\.' instead of '.' to escape regex '.' special character
    
    % Deal with possible empty extension in the extension cell
    oldBasenames(~emptyExtension) = strcat(...
        oldBasenames(~emptyExtension),...
        strcat('\.',extensions(~emptyExtension)));
    newBasenames(~emptyExtension) = strcat(...
        newBasenames(~emptyExtension),...
        strcat('.',extensions(~emptyExtension)));

    % Replace the old filenames with new ones, both with extension
    outChar = regexprep(inpChar, oldBasenames, newBasenames);
end

end
