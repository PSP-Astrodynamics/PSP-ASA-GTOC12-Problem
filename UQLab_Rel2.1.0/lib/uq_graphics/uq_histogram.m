function [H,N,X] = uq_histogram(varargin)
%UQ_HISTOGRAM creates a histogram using the default formatting style of UQLab.
%
%   UQ_HISTOGRAM(Y) plots a histogram of a column- or row-vector Y with
%   normalized values (i.e., the total area under the histogram is 1.0).
%   UQ_HISTOGRAM uses an automatic binning algorithm that returns bins
%   with a uniform width.
%
%   UQ_HISTOGRAM(X,Y) plots a histogram of Y among bins with the centers
%   specified by vector X.
%
%   UQ_HISTOGRAM(..., 'Normalized', false) plots an unnormalized (i.e., raw
%   counts) histogram. By default the value of named argument 'Normalized'
%   is true.
%
%   UQ_HISTOGRAM(..., 'ColorRange', RANGE) colors the histogram bars
%   according to their height by linearly interpolating between the color
%   pair passed in RANGE. This option is only supported in MATLAB R2017b or
%   newer; In older MATLAB, the option is ignored.
%
%   UQ_HISTOGRAM(..., NAME, VALUE) modifies the properties of the plot
%   according to the specified NAME/VALUE pairs. The complete list of the
%   available NAME/VALUE pairs can be found in the documentation of the <a 
%   href="matlab:help bar">bar</a> function.
%
%   UQ_HISTOGRAM(AX,...) creates the plot into the Axes object AX instead
%   of the current axes.
%
%   H = UQ_HISTOGRAM(...) returns the Bar object. Use H to access and
%   modify the properties of the underlying bar object after it has been
%   created. In MATLAB R2014a or older, the function returns the handle to
%   a barseries object.
%
%   [H,N] = UQ_HISTOGRAM(...) additionally returns the number of elements
%   per bins (containers). The values might be normalized depending on the
%   option set by the named argument 'Normalized'.
%
%   [H,N,X] = UQ_HISTOGRAM(...) additionally returns the center position of
%   the bins along the x-axis.
%
%   See also UQ_BAR, HIST.

%% Verify inputs
if nargin == 0
   error('Not enough input arguments.')
end

% Check histogram normalization
pdfMode = true;
if any(strcmpi(varargin,'normalized'))
    normIdx = find(strcmpi(varargin,'normalized'));
    pdfMode = varargin{normIdx+1};
    varargin([normIdx normIdx+1]) = [];
end

% Check color range 
colorRangeDefined = false;
if any(strcmpi(varargin,'colorrange'))
    % Parse 'ColorRange' option
    normIdx = find(strcmpi(varargin,'colorrange'));
    colorRange = varargin{normIdx+1};
    varargin([normIdx normIdx+1]) = [];
    
    % Check MATLAB version
    % 'ColorRange' is only supported in R2017b or newer
    colorRangeSupport = uq_checkMATLAB('r2017b');
    if colorRangeSupport
        colorRangeDefined = true;
        % check input
        if ~(size(colorRange) == [2,3])
            error('ColorRange has to be passed as 2-by-3 matrix')
        end
    else
        colorRangeDefined = false;
    end
end

%% Set default histogram properties
Defaults = struct;  % Currently there is none

%% Prepare the figure and axes
ax = uq_getPlotAxes(varargin{:});

%% Parse the inputs
vidx = true(size(varargin));
isAxes = uq_isAxes(varargin{1});
if isAxes
    dataIdx = 2;      % The data is on the second position
    vidx(1) = false;  % Remove the first position for further parsing
else
    dataIdx = 1;  % The data is in the first position
end

if numel(varargin) < dataIdx
    error('Not enough input arguments. Histogram needs data to plot.')
else
    if isnumeric(varargin{dataIdx})
        numArgs = isAxes + 1;  % Min. number of input args with axes obj.
        if numel(varargin) > numArgs && isnumeric(varargin{dataIdx+1})
            X = varargin{dataIdx};    % X-axis centers specified
            Y = varargin{dataIdx+1};  % Data vector
            vidx(dataIdx+1) = false;
        else
            Y = varargin{dataIdx};    % Just the data vector
        end
        vidx(dataIdx) = false;

        % Check Y
        if ~isrow(Y) && ~iscolumn(Y)
            error('uq_histogram(Y) only works with row or column vectors.')
        end

        % Remove the vector(s) from the parsed inputs
        options = varargin(vidx);
    else
        error(...
            ['Not enough input arguments. ',...
            'Histogram needs numerical data to plot.'])
    end
end

%% Create the histogram variables
if exist('X','var')
    [hY,hX] = hist(Y,X);  % X are the centers of the histogram elements
else
    % The width of a histogram element is computed by the Scott's rule
    w = 3.49*std(Y(:))*numel(Y)^(-1/3);  % Width of a histogram element
    nBins = max(ceil(range(Y)/w),1);     % Number of histograms
    [hY,hX] = hist(Y,nBins);
end

%% If normalization is required, calculate the relevant quantities
if pdfMode
    normfac = 1/(sum(hY*mean(diff(hX))));
    hY = hY*normfac;
end

% If colorRange is defined, modify the options cell array
if colorRangeDefined
    % compute color for each bar
    colorFrac = hY./max(hY);
    colorVec = colorFrac'*colorRange(2,:) + (1-colorFrac')*colorRange(1,:);
    % add to options
    options = [options;{'CData'; colorVec;'FaceColor';'flat'}];
end

%% Create the bar plot with the specified properties
hh = uq_bar(ax, hX, hY, 1, options{:});

%% Format the figure according to the defaults given
uq_formatGraphObj(hh, options, Defaults);

%% Return outputs if requested
if nargout > 0
   H = hh;  % Handle to the barseries objects
   N = hY;  % Number of elements per container (might be normalized)
   X = hX;  % The position of the bin centers for numeric data
end

end
