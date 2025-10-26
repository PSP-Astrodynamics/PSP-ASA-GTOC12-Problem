function f = uq_figure(varargin)
%UQ_FIGURE creates a figure window following the default formatting and screen placement of UQLab.
%
%   UQ_FIGURE creates a new formatted figure window.
%
%   UQ_FIGURE(...) wraps the MATLAB <a 
%   href="matlab:help figure">figure</a> command, supporting the same
%   input arguments.
%
%   UQ_FIGURE(..., NAME,VALUE) also sets the properties of the figure
%   according to the specified NAME/VALUE pairs.
%
%   F = UQ_FIGURE(...) returns the Figure object. Use F to access or modify
%   the properties of the figure after it is created. In MATLAB R2014a or
%   older, the function returns the handle to the Figure object.
%
%   See also FIGURE, UQ_FORMATGRAPHOBJ, UQ_GETDEFAULTFIGURE.

%% Verify input
% Preserve the behavior of 'figure' function when 'figure(fig)' is called
if numel(varargin) == 1
    % Get the specified figure
    ff = figure(varargin{1});
    options = {};
else
    % No figure, create a figure with the specified properties
    ff = figure(varargin{:});
    options = varargin;
end

%% Get the default figure formatting
currDefUnits = get(0, 'Units');
currFigUnits = get(ff, 'Units');
% Operates on pixels units during formatting
set(0, 'Units', 'pixels')
set(ff, 'Units', 'pixels')

DefaultFigure = uq_getDefaultFigure(ff);

%% Format the figure according to the defaults given
uq_formatGraphObj(ff, options, DefaultFigure)

% Return the units to the original
set(ff, 'Units', currFigUnits)
set(0, 'Units', currDefUnits)

%% Return values (if asked)
if nargout > 0
    f = ff;
end

end
