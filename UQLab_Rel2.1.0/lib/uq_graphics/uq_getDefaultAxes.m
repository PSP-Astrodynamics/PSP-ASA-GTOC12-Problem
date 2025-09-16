function DefaultAxes = uq_getDefaultAxes(ax)
%UQ_GETDEFAULTAXES returns the default UQLab Axes object formatting.
%
%   DefaultAxes = UQ_GETDEFAULTAXES(AX) returns the default UQLab Axes
%   object formatting in a structure based on the current Axes handle AX.
%
%   The following Axes object properties are the defaults:
%
%       Property                Value
%       LineWidth               1.5
%       Box                     'on'
%       Layer                   'top'
%       ColorOrder              uq_colorOrder(6)
%       TickLabelInterpreter    'LaTeX'
%       XGrid                   'on'
%       YGrid                   'on'
%       ZGrid                   'on'
%
%   See also uq_formatDefaultAxes, uq_getDefaultFont.

%% Font properties
DefaultAxes = uq_getDefaultFont(ax);

%% Axes properties
DefaultAxes.LineWidth = 1.5;
DefaultAxes.Box = 'on';
DefaultAxes.Layer = 'top';
DefaultAxes.TickLabelInterpreter = 'LaTeX';
% Turn on the grid
DefaultAxes.XGrid = 'on';
DefaultAxes.YGrid = 'on';
DefaultAxes.ZGrid = 'on';

end
