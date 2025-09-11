function h = uq_bar(varargin)
%UQ_BAR creates a bar graph following the default formatting of UQLab.
%
%   UQ_BAR(Y) creates a set of bar graphs, one for each element in Y,
%   following the default formatting of UQLab.
%
%   UQ_BAR(X,Y) creates a set of bar graphs, one for each column of Y
%   at locations specified in X.
%
%   UQ_BAR(...) wraps the MATLAB <a href="matlab:help bar"
%   >bar</a> function, supporting the same input arguments.
%
%   The following defaults are set (as NAME/VALUE pairs):
%          'EdgeColor'           'none'
%
%   UQ_BAR(..., NAME, VALUE) modifies the properties of the plot according
%   to the specified NAME/VALUE pairs. The complete list of the available
%   NAME/VALUE pairs can be found in the documentation of the <a 
%   href="matlab:help bar">bar</a> function.
%
%   UQ_BAR(AX,...) creates the plot into the axes AX instead of the current
%   axes.
%
%   H = UQ_BAR(...) returns one or more Bar objects. Use the elements in H
%   to access and modify the properties of a specific Bar object after it
%   has
%   been created. In MATLAB R2014a or older, the function returns one or
%   more handles to barseries objects.
%   
%   See also BAR.

%% Verify inputs
if nargin == 0
    error('Not enough input arguments.')
end

%% Set default bar properties

% Common properties
Defaults.EdgeColor = 'none';  % no outline

% OS-specific properties
if ispc % windows
    
elseif isunix||ismac % linux
    
end

%% Prepare the figure and axes
ax = uq_getPlotAxes(varargin{:});

%% Create a bar plot with the specified properties
isAxes = uq_isAxes(varargin{1});
if isAxes
    hh = bar(ax,varargin{2:end});
else
    hh = bar(ax,varargin{:});
end

%% Parse the NAME/VALUE pairs as option from varargin

options = [];

barStyles = {'grouped', 'stacked', 'hist', 'histc'};
colorAbbr = {'b', 'r', 'g', 'b', 'c', 'm', 'y', 'k', 'w'};
isBarColorSet = false;
isFaceColorSet = false;

for i = 1:numel(varargin)
    % uq_bar(Y), uq_bar(X,Y), uq_bar(Y,Width), and uq_bar(X, Y, Width)
    isNumeric = isnumeric(varargin{i});
    % uq_bar(X,...) with categorical X
    isCategorical = iscategorical(varargin{i});
    % uq_bar(ax,...)
    isAxes = uq_isAxes(varargin{i});
    % uq_bar(...,style)
    isBarStyles = any(strcmpi(barStyles,varargin{i}));
    % uq_bar(...,bar_color)
    isColorSet = any(strcmpi(colorAbbr,varargin{i}));
    if isColorSet
        isBarColorSet = true;
    end
    
    isNameValue = any(...
        [isNumeric isCategorical isAxes isBarStyles isColorSet]);
    
    % uq_bar(..., NAME, VALUE)
    if ~isNameValue
        options = varargin(i:end);
        break
    end
end

% If uq_bar(...,bar_color) is used, then 'FaceColor' is ignored
if isBarColorSet
    if any(strcmpi(options,'FaceColor'))
        faceColorIdx = find(strcmpi(options,'FaceColor'));
        options(faceColorIdx:faceColorIdx+1) = [];
    end
else
    if any(strcmpi(options,'FaceColor'))
        isFaceColorSet = true;
    end
end

%% Format the plot
if ~isempty(hh)
    % Format the figure and axes
    if ~ishold
        uq_formatDefaultAxes(ax);
    end
    
    % Set bar FaceColor
    % NOTE: R2014a does not support using color from the axes 'ColorOrder'
    % property, so it must be set manually.
    if ~ishold
        colorOrder = get(ax,'ColorOrder');
        if ~isBarColorSet
            if ~isFaceColorSet
                for ii = 1:numel(hh)
                    % Cycle through color but periodically reset
                    % when the maximum number of colors is reached.
                    jj = mod(ii, size(colorOrder,1));
                    if jj == 0
                        jj = size(colorOrder,1);
                    end
                    set(hh(ii), 'FaceColor', colorOrder(jj,:))
                end
            end
        end
    end

    % Set other properties according to Defaults,
    % Skip if 'options' overrides the 'Defaults'
    for ii = 1:numel(hh)
        uq_formatGraphObj(hh(ii), options, Defaults);
    end
end

%% Return outputs if requested
if nargout > 0  
   h = hh; 
end

end
