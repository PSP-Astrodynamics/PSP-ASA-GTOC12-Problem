function DefaultFigure = uq_getDefaultFigure(fig)
%UQ_DEFAULTFIGURE returns the default UQLab Figure object formatting.
%
%   DefaultFigure = UQ_GETDEFAULTFIGURE(FIG) returns the default UQLab
%   Figure object formatting in a structure DefaultFigure based on the
%   current Figure handle FIG.
%
%   The following defaults are set:
%       Color                   white
%       Position                centered (depends on the screen size)
%       Renderer                painters
%       Name                    uq_figure_(figure number)
%       Filename                uq_figure_(figure number).fig
%       DefaultAxesColorOrder   uq_colorOrder(7)
%
%   Note:
%
%   - If a figure does not exist, then by default the function creates the
%     figure window at the center of the screen. This center position is
%     calculated assuming the default units is already set to 'Pixels'.
%
%   See also uq_figure.

%% Common properties
DefaultFigure.Color = 'w';   % white background
DefaultFigure.Renderer = 'opengl';

%% Figure position
% Get the screen size
scrSize = get(0,'ScreenSize');  % in pixels
% Fig. Height = 1/3 * Screen Width; Fig. Height = 1/2 * Screen Height
refL = 600;
sides = round([refL*1.33 refL]);
% Get the center of the screen
mid = round(scrSize(3:4)/2);
% Set the position of the figure (centered)
DefaultFigure.Position = [mid(1)-sides(1)/2 mid(2)-sides(1)/2,...
    sides(1) sides(2)];

%% Axes Color Order
% NOTE: The Axes 'ColorOrder' is set at the figure level so the plotting
% can use the set color order. Otherwise, the colors have to be changed
% after the plot is created.
DefaultFigure.DefaultAxesColorOrder = uq_colorOrder(7);

%% Figure name and filename

% Get the figure number
if isprop(fig,'Number')
    figNo = get(fig,'Number');  % >= R2014b
else
    figNo = fig;  % <= R2014a, the current handle is the figure number.
end

DefaultFigure.Name = sprintf('uq_figure_%i',figNo);
DefaultFigure.Filename = sprintf('uq_figure_%i.fig',figNo);

%% Other OS-specific properties
if ispc % windows
    
elseif isunix||ismac % linux + mac
    
end

end