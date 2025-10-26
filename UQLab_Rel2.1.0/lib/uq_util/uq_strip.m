function newChar = uq_strip(inpChar,varargin)
%UQ_STRIP removes the leading and trailing whitespaces from a char array(s).
%
%   The function is to mimic the built-in MATLAB function 'strip' that is
%   only available in MATLAB >=R2016b.

%% Verify inputs
if nargin > 3
    error('Too many input arguments.')
end

padChar = '\s*';
side = 'both';

if nargin > 1
    switch lower(varargin{1})
        case 'both'
            side = 'both';
        case 'left'
            side = 'left';
        case 'right'
            side = 'right';
        otherwise
            side = 'both';
            padChar = varargin{1};
    end
end

if nargin > 2
    padChar = varargin{2};
end

%%
switch side
    case 'both'
        newChar = regexprep(inpChar, [padChar '$'], '');
        newChar = regexprep(newChar, ['^' padChar], '');
    case 'left'
        newChar = regexprep(inpChar, ['^' padChar], '');
    case 'right'
        newChar = regexprep(inpChar, [padChar '$'], '');
end
    
end