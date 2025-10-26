function h = uq_plot(varargin)
%UQ_PLOT creates a 2-dimensional line plot following the default formatting of UQLab.
%
%   UQ_PLOT(X,Y) plots vector Y versus vector X following the default
%   formatting of UQLab.
%
%   UQ_PLOT(...) wraps the MATLAB <a
%   href="matlab:help plot">plot</a> function, supporting the same input
%   arguments.
%
%   The following properties are set (as NAME/VALUE pairs):
%       'LineWidth'           2
%       'MarkerFaceColor'     same as 'Color'
%
%   UQ_PLOT(..., NAME, VALUE) modifies the properties of the plot according
%   to the specified NAME/VALUE pairs. The complete list of NAME/VALUE
%   pairs can be found in <a href="matlab:help plot">plot</a> function.
%
%   UQ_PLOT(AX,...) creates the plot into the Axes object AX instead of the
%   current axes.
%
%   H = UQ_PLOT(...) returns a column vector of Line objects.
%   Use the elements in H to access and modify the properties of specific
%   plot elements after they are created. In MATLAB R2014a or older, the
%   function returns one or more handles to lineseries objects.
%
%   See also PLOT, UQ_GETPLOTAXES, UQ_FORMATDEFAULTAXES.

%% Verify inputs
if nargin == 0
    error('Not enough input arguments.')
end

%% Prepare the figure and axes
ax = uq_getPlotAxes(varargin{:});    

%% Create the plot
hh = plot(varargin{:});

%% Set default 2-D line plot properties
Defaults.LineWidth = 2;  % Thicker lines

%% Format the plot

% Format the axes
if ~ishold
    uq_formatDefaultAxes(ax)
end

for ii = 1:numel(hh)
    % Fill in color of a marker, the same as the principal 'Color'
    Defaults.MarkerFaceColor = get(hh(ii),'Color');
    
    % Remove varargin fields from Defaults
    DefaultFieldNames = fieldnames(Defaults);
    for ff = 1:length(DefaultFieldNames)
        idx = strcmpi(DefaultFieldNames{ff},varargin);
        if any(idx)
            % remove from Defaults
            Defaults= rmfield(Defaults, DefaultFieldNames{ff});
        end
    end
    % Format graphic objects following defaults,
    uq_formatGraphObj(hh(ii), [], Defaults)
end

%% Gives output only if requested
if nargout > 0
   h = hh;
end

end
