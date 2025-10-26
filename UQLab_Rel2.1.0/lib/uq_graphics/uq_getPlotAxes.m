function [ax,fig] = uq_getPlotAxes(varargin)
%UQ_GETPLOTAXES creates new a axes, get the current one, or the given one to plot in.
%
%   If no axes is provided, the currently active one is taken.
%   If none exist, one is created.

if ~isempty(varargin)
    isAxes = uq_isAxes(varargin{1});
    if isAxes
        ax = varargin{1};
    else
        if isempty(get(0,'CurrentFigure'))
            % No figure, create a new one
            uq_figure()
        end
        ax = newplot;
    end
end

fig = gcf;

end
