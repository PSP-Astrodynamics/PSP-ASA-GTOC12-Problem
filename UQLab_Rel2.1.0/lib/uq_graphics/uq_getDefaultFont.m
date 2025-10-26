function DefaultFont = uq_getDefaultFont(ax)
%UQ_GETDEFAULTFONT returns the default font properties of UQLab graphics.
%
%   DefaultFont = uq_getDefaultFont(AX) returns the default font properties
%   of UQLab graphics in a structure. For proper flexible sizing, the axes
%   object AX is required.
%
%   The following are the defaults:
%       FontSize                relative to figure size (0.04 * height,
%                               operation in centimeters)

%% Font properties

% FontSize property
% store settings we want to modify in here
fig = get(ax,'Parent');
currFigUnits = get(fig,'Units');
currAxFontUnits = get(ax,'FontUnits');
% Set the units to centimeters, scaling & adjustment are done in this unit
set(fig, 'Units', 'Pixels')
set(ax, 'FontUnits', 'Pixels')

DefaultFont.FontSize = 24;

% Reset the modified 'Units' property
set(fig, 'Units', currFigUnits);
set(ax, 'FontUnits', currAxFontUnits);

