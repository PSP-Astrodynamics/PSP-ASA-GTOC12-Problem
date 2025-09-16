function pathChar = uq_Dispatcher_util_writePath(inpChar, os, isLiteral)
%UQ_DISPATCHER_UTIL_WRITEPATH escapes the whitespace characters in a path
%   specification.

%% Parse and verify inputs

if nargin < 3
    isLiteral = false;
end

%% Escape whitespace characters
if any(regexp(inpChar,'\s'))
    switch lower(os)
        case {'linux','unix','mac'}
            if isLiteral
                pathChar = ['''' inpChar ''''];
            else
                pathChar = regexprep(inpChar, '\s', '\\ ');
            end
        case {'windows','pc','win'}
            pathChar = ['"' inpChar '"'];
        otherwise
            error('Unknown system!')
    end
else
    pathChar = inpChar;
end

       
end
