function h = uq_violinplot(varargin)
%UQ_VIOLINPLOT creates violin plots.
%
%   UQ_VIOLINPLOT(Y) generates M violin plots based on the N-by-M data
%   matrix Y.
%
%   UQ_VIOLINPLOT(X,Y) generates violin plots centered on specified points
%   in X. The number of elements in X must be consistent with the number of
%   columns in Y.
%
%   UQ_VIOLINPLOT(..., NAME, VALUE) modifies the properties of the plot
%   according to the specified NAME/VALUE pairs. The complete list of the
%   available NAME/VALUE pairs can be found in the documentation of the <a 
%   href="matlab:help patch">patch</a> function. The commonly used
%   NAME/VALUE pairs are:
%
%      NAME             VALUE
%      'FaceColor'      A vector specifying the filling color of the
%                       violin plot in RGB scale - 1-by-3 DOUBLE.
%                       default: uq_colorOrder(1)
%                       
%      'EdgeColor'      A vector specifying the edge color of the violin
%                       plot in RGB scale - 1-by-3 DOUBLE.
%                       default: 'none'
%
%   Additional NAME/VALUE pairs can be found in the MATLAB <a
%   href="matlab:help patch">patch</a> function.
%
%   UQ_VIOLINPLOT(AX,...) creates the plot into the Axes object AX instead
%   of the current axes.
%
%   H = UQ_VIOLINPLOT(...) returns one or more Patch objects. Use the
%   elements in H to access and modify the properties of a specific violin
%   plot. In MATLAB R2014a or older, the function returns one or more
%   handles to patch objects.
%  
%   See also PATCH, UQ_FORMATDEFAULTAXES, UQ_FORMATGRAPHOBJ.

%% Set the defaults
Defaults.FaceColor = uq_colorOrder(1);
Defaults.EdgeColor = 'none';

%% Verify inputs
if nargin == 0
    error('Not enough input arguments.')
end

isAxes = uq_isAxes(varargin{1});
if ~isnumeric(varargin{1}) && ~isAxes
    error('First argument must either be numeric or axes handle.')
end

%% Parse varargin
vidx = true(size(varargin));
isAxes = uq_isAxes(varargin{1});
if isAxes
    dataIdx = 2;      % The data is on the second position
    vidx(1) = false;  % Remove the first position for further parsing
else
    dataIdx = 1;  % The data is in the first position
end

if numel(varargin) < dataIdx
    error('Not enough input arguments. Violin plot needs data to plot.')
else
    if isnumeric(varargin{dataIdx})
        numArgs = isAxes + 1;  % Min. number of input args with axes obj.
        if numel(varargin) > numArgs && isnumeric(varargin{dataIdx+1})
            X = varargin{dataIdx};
            Y = varargin{dataIdx+1};
            vidx(dataIdx+1) = false;
            % check if size of X matches Y
            if ~(length(X)==size(Y,2))
                error(...
                    ['Dimension mismatch. ',...
                    'The number of columns in Y ',...
                    'have to be the same as the length of X.'])
            end
        else
            Y = varargin{dataIdx};
        end
        vidx(dataIdx) = false;

        % Remove the vector(s) from the parsed inputs
        options = varargin(vidx);
    else
        error(...
            ['Not enough input arguments. ',...
            'Violin plot needs numerical data to plot.'])
    end
end

parseKeys = {'facecolor'};
parseTypes = {'p'};
options(1:2:end) = lower(options(1:2:end));  % make NAME lower case
[uq_cline,~] = uq_simple_parser(options, parseKeys, parseTypes);

% 'facecolor' option
if ~strcmp(uq_cline{1},'false')
    plotColor = uq_cline{1};
else
    % Get the default color for the polygon
    plotColor = Defaults.FaceColor;
end

%% Prepare the figure and axes
ax = uq_getPlotAxes(varargin{:});

hh = [];
%% Create the violin plot
% raise warning if only single point for kernel smoothing
if size(Y,1) == 1
    warning('Only one point provided for violinplot, increase number of supplied points for accurate PDF estimate.')
end
for ii = 1:size(Y,2)
    % Create kernel density
    currRuns = Y(:,ii);
    [f,xi] = ksdensity(currRuns);
    % Scale and shift
    patchF = [f -fliplr(f)];
    patchF = patchF / (2*max(patchF));
    if exist('X','var')
        patchF = patchF + X(ii);
    else
        patchF = patchF + ii;
    end
    % Create the violin plot
    hh = [...
        hh;
        patch(patchF, [xi fliplr(xi)], plotColor,...
            'Parent', ax, options{:})];
end

%% Format the plot
if ~isempty(hh)
    % Format the axes
    if ~ishold
        uq_formatDefaultAxes(ax)
    end

    for ii = 1:numel(hh)
        uq_formatGraphObj(hh(ii), options, Defaults)
    end
end

%% Return output if requested
if nargout > 0
    h = hh;
end

end
