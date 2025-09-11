function [h,Axs,bigAx, ScaleMat] = uq_scatterDensity(varargin)
%UQ_SCATTERDENSITY creates a scatter plot matrix of multivariate data.
%    
%   UQ_SCATTERDENSITY(X) creates a scatter plot matrix from each pairs of
%   the columns in X. If X is N-by-M matrix, UQ_SCATTERDENSITY produces a
%   lower triangular matrix of M-by-M plots, in which histograms of each
%   column of X are plotted in the main diagonal and scatter plots of each
%   pair of columns of X are plotted as the off-diagonal elements.
%
%   UQ_SCATTERDENSITY(X,Y) creates a scatter plot matrix using the M-by-N 
%   matrix X and N-by-N cell array Y containing the M-by-1 (diagonal) and 
%   M-by-M (off-diagonal) evaluations of the target function.
%
%   UQ_SCATTERDENSITY(X,Y,ScaleMat) creates a scatter plot matrix using the 
%   M-by-N matrix X and N-by-N cell array Y containing the M-by-1 (diagonal) 
%   and M-by-M (off-diagonal) evaluations of the target function. Scales the
%   colors in the plots according to the M-by-M-by-2 matrix ScaleMat containing
%   the lower scale bounds in ScaleMat(:,:,1) and the upper scale bounds in 
%   ScaleMatS(:,:,2).
%   
%   UQ_SCATTERDENSITY(..., hist_NAME, VALUE, scatter_NAME, VALUE) modifies
%   the scatter plot matrix using additional NAME/VALUE pair arguments. The
%   following convention applies when providing pairs to the corresponding
%   elements of the matrix of plots:
%       - If NAME has the prefix 'hist_', then VALUE is passed to the
%         function <a href="matlab:help uq_histogram"
%         >uq_histogram</a> to create the histograms in the main diagonal.
%       - If NAME has the prefix 'scatter_', then VALUE is passed instead
%         to the <a href="matlab:help uq_plot"
%         >uq_plot</a> function that creates the off-diagonal scatter plots.
%
%   UQ_SCATTERDENSITY(..., NAME, VALUE) modifies the overall plot using 
%   NAME/VALUE pair arguments of which the NAMEs have neither the prefix
%   'hist_' nor 'scatter_'. Available options are:
%   
%      Name               VALUE
%      'points'           A set of N points that are plotted next to the
%                         X points. 
%                         - Numerical N-by-M
%                         - Struct Array with fields X and type
%
%      'labels'           A cell array of labels for subplots
%                         - Cell Array 1-by-M
%
%      'color'            A vector specifying the color of the plotted
%                         elements
%                         - Numerical 1-by-3
%
%      'limits'           A matrix specifying the limits of the subplots
%                         - Numerical 2-by-M
% 
%      'title'            Title string to add to plot
%
%      'gradient'         Should the density be indicated by color gradient
%                         in the univariate marginals
%                         - Boolean
%
%      'baseColor'        A vector specifying the background color of the 
%                         plotted off-diagonal elements
%                         - Numerical 1-by-3
%
%   UQ_SCATTERDENSITY(AX,...) creates the plots into the Axes object AX
%   instead of the current axes.
%
%   H = UQ_SCATTERDENSITY(...) returns the graphics objects of the plot.
%   The main diagonal elements (histograms) are represented by Bar objects
%   and the off-diagonal elements are represented by Line objects. Use the 
%   elements in H to access and modify the properties of specific plots. In
%   MATLAB R2014a or older, the function returns handles to barseries
%   objects (instead of Bar) and lineseries objects (instead of Line).
%
%   [H,AXS] = UQ_SCATTERDENSITY(...) additionally returns the Axes objects
%   (or handles) of all the plots inside the scatter plot matrix.
%
%   [H,AXS,BIGAX] = UQ_SCATTERDENSITY(...) additionally returns the parent
%   axes of the scatter plot matrix.
%
%   [H,AXS,BIGAX,S] = UQ_SCATTERDENSITY(...) additionally returns the
%   scaling matrix S.
%
%   See also UQ_HISTOGRAM, UQ_PLOT.

%% Verify inputs
if nargin == 0
    error('Not enough input arguments.')
end

%% Default plot properties
DEFAULTS.color = uq_colorOrder(1);
DEFAULTS.gradient = false;
DEFAULTS.baseColor = [1 1 1];

% Histogram defaults
hist_DEFAULTS.EdgeColor = 'none';  % No edge color
hist_DEFAULTS.FaceAlpha = 1;       % No transparancy

% scatter plot defaults
scatter_DEFAULTS.MarkerSize = 5;
scatter_DEFAULTS.Marker = '.';
scatter_DEFAULTS.LineStyle = 'none';

% axes defaults
axes_DEFAULTS = {'LineWidth', 0.5};

% OS-specific properties
if ispc % windows
    
elseif isunix||ismac % linux
    
end

%% Get the axes to plot in
ParentAx = uq_getPlotAxes(varargin{:});
% Set the axes to be invisible
axis(ParentAx,'off')

%% Parse inputs, split NAME/VALUE pairs
isAxes = uq_isAxes(varargin{1});
% set extract start index
if isAxes
    esIdx = 2;
else
    esIdx = 1;
end

if isnumeric(varargin{esIdx}) && nargin >= esIdx + 1 && iscell(varargin{esIdx+1})
    % Y provided
    YProvided = true;
    X = varargin{esIdx};
    Ycell = varargin{esIdx+1};
    if isnumeric(varargin{esIdx+2})
        % Scale provided
        scaleProvided = true;
        ScaleMat = varargin{esIdx+2};
        % extract arguments
        [histArg,scatterArg,uqArg] = uq_splitScatterArgs(varargin(esIdx+3:end));
    else
        % Scale not provided
        scaleProvided = false;
        % Initialize scaling matrix
        ScaleMat = nan(size(X,2),size(X,2),2);
        % extract arguments
        [histArg,scatterArg,uqArg] = uq_splitScatterArgs(varargin(esIdx+2:end));
    end
elseif isnumeric(varargin{esIdx})
    % Scale not provided
    scaleProvided = false;
    % Y not provided
    YProvided = false;
    X = varargin{esIdx};
    [histArg,scatterArg,uqArg] = uq_splitScatterArgs(varargin(esIdx+1:end));
else
    error('Data must be provided.')
end

%% Parse NAME/VALUE pairs other than histogram and scatter
parse_keys = {'points','labels','color','limits','title','gradient','basecolor'};
parse_types = {'p','p','p','p','p','p','p'};
% make NAME lower case
uqArg(1:2:end) = lower(uqArg(1:2:end));
[uq_cline,~] = uq_simple_parser(uqArg, parse_keys, parse_types);

% 'points' option
if ~strcmp(uq_cline{1}, 'false')
    plotPoints_flag = true;
    plotPointsTemp = uq_cline{1};
    % switch between cell and matrix
    if isnumeric(plotPointsTemp)
        % Check dimensions
        if ~(size(X,2) == size(plotPointsTemp,2))
            error('Additional plot points do not have a compatible size')
        end
        % store in struct
        plotPoints.X{1} = plotPointsTemp;
        plotPoints.Type{1} = 'custom';
        plotPoints.Collection = plotPointsTemp;
    elseif isstruct(plotPointsTemp) 
        plotPointsCollection = [];
        % Check dimensions
        for ii = 1:length(plotPointsTemp)
            if ~(size(X,2) == size(plotPointsTemp.X{ii},2))
                error('Additional plot points do not have a compatible size')
            end
            % store in collection
            plotPointsCollection = [plotPointsCollection; plotPointsTemp.X{ii}];
        end
        % store in struct
        plotPoints = plotPointsTemp;
        plotPoints.Collection = plotPointsCollection;
    else
        error('Supplied points don''t have required format.')
    end
        
else
    plotPoints_flag = false;
end

% 'labels' option
if ~strcmp(uq_cline{2}, 'false')
    plotLabels_flag = true;
    plotLabels = uq_cline{2};
    % Check dimensions
    if ~(size(X,2) == length(plotLabels))
        error('Label length does not match the provided points dimension')
    end
else
    plotLabels_flag = false;
    plotLabels = [];
end

% 'color' option
if ~strcmp(uq_cline{3}, 'false')
    plotColor = uq_cline{3};
else
    plotColor = DEFAULTS.color;
end

% 'limits' option
if ~strcmp(uq_cline{4}, 'false')
    plotLimits = uq_cline{4};
    % check if correct dimensions
    if ~(size(plotLimits,2) == size(X,2))
        error('Supplied limits do not match supplied points')
    end
else
    % infer limits from X
    % Get smallest and largest sample values in each dimension
    if plotPoints_flag
        minSample = min([X;plotPoints.Collection]);
        maxSample = max([X;plotPoints.Collection]);
    else
        minSample = min(X);
        maxSample = max(X);
    end
    plotLimits = [minSample; maxSample];
end

% 'title' option
if ~strcmp(uq_cline{5}, 'false')
    titleString = uq_cline{5};
    TitleProp = get(ParentAx,'Title');
    set(TitleProp,...
        'String', titleString,...
        'FontSize', 16,...
        'Interpreter', 'LaTeX');
end

% 'gradient' option
if ~strcmp(uq_cline{6}, 'false')
    gradientSwitch = uq_cline{6};
else
    gradientSwitch = DEFAULTS.gradient;
end

% 'baseColor' option
if ~strcmp(uq_cline{7}, 'false')
    baseColor = uq_cline{7};
else
    baseColor = DEFAULTS.baseColor;
end

% initialize
labelHandles = [];

%%
% Use specified 'color' in histogram and scatter plot if they are not
% specified.
if isempty(histArg) || ~any(any(strcmpi(histArg,'facecolor')))
    if uq_checkMATLAB('r2017b') && gradientSwitch
        histArg(:,end+1) = {'ColorRange'; [baseColor; plotColor]};
    else
        histArg(:,end+1) = {'FaceColor'; plotColor};
    end
end
if isempty(scatterArg) || ~any(any(strcmpi(scatterArg,'color')))
    if ~gradientSwitch
        scatterArg(:,end+1) = {'MarkerEdgeColor'; plotColor};
    end
end

%% Get the number of plots
[nPoints,nDim] = size(X); % Number of plots and points

%% Compute the font size scaling factor
% Scale font size based on number of plots linearly between 1 (up to 2 
% subplots) and 0.4 (more than 10 subplots)
lowerPlots = 2;
upperPlots = 10;
lowerScale = .4;
upperScale = .6;
fontScale = interp1(...
    [1,lowerPlots,upperPlots], [lowerScale,lowerScale,upperScale],...
    nDim, 'linear', upperScale);  

%% Start plotting
% set scale factor for scatter plot based on number of points
lScaleLim = 300; lNSample = 20; uScaleLim = 1; uNSample = 1e3;
if nPoints > lNSample
    % interpolate linearly
    scatterScale = interp1([lNSample, uNSample],[lScaleLim, uScaleLim],nPoints,...
        'linear',uScaleLim);
else
    % use lower value
    scatterScale = lScaleLim;
end
 
% save object handles for formatting
HistHandles = [];
ScatterHandles = [];
AxisHandles = [];
% Loop over dimensions to plot
for ii = 1:nDim
    for jj = 1:ii
        % Switch between 'uq_histogram' and 'uq_plot'
        % Create axes
        linIdx = sub2ind([nDim, nDim],ii,jj);
        currSub = uq_subplot(nDim,nDim,linIdx);
        if ii == jj %histogram
            if ~YProvided 
                % Plot histogram 
                [currObj, N] = uq_histogram(currSub, X(:,ii), histArg{:});
                % Scaling
                maxVal = max(N);
                ScaleMat(ii,jj,:) = [0; maxVal];
            else
                % Scaling
                if ~scaleProvided
                    maxVal = max(Ycell{ii,jj}(:));
                    ScaleMat(ii,jj,:) = [0; maxVal];
                else
                    maxVal = ScaleMat(ii,jj,2);
                end
                
                % Plot bars
                Frac = Ycell{ii,jj}/maxVal;
                if min(Frac(:)) < 0
                    warning('Negative values are cut off in plot.')
                    Frac(Frac(:)<0) = 0;
                end
                
                % set bar colors
                options = histArg;
                if any(strcmpi(options,'colorrange'))
                    normIdx = find(strcmpi(options,'colorrange'));
                    colorRange = options{normIdx+1};
                    % compute color for each bar
                    colorFrac = Frac./max(Frac);
                    colorVec = colorFrac*colorRange(2,:) + (1-colorFrac)*colorRange(1,:);
                    % add to options
                    options = [options;{'CData'; colorVec;'FaceColor';'flat'}];
                end
                
                currObj = uq_bar(currSub, X(:,ii), Frac, 1, options{:});
            end
            
            % Additional formatting
            HistHandles = [HistHandles currObj];
            if uq_checkMATLAB('r2019a')
                % Limit panning to x direction
                currSub.Interactions = panInteraction('Dimensions','x');
            end
        elseif jj < ii % scatterplot
            if ~YProvided 
                % Plot scatter
                % NOTE: for backward compatibility with R2015b;
                % However, color scaling of the corresponding
                % histogram is supported only in R2017b
                if uq_checkMATLAB('r2017b')
                    % compute 2D histogram values
                    [N,~,~,binX,binY] = histcounts2(X(:,jj), X(:,ii),'normalization','pdf');
                    
                    % Scaling
                    if ~scaleProvided
                        maxVal = max(N(:));
                        ScaleMat(ii,jj,:) = [0; maxVal];
                    else
                        maxVal = ScaleMat(ii,jj,2);
                    end
                    
                    % SCATTER
                    % Slower but more appealing in large plots
                    % loop over bins
                    CurrColorVec = nan(size(X,1),3);
                    for kk = 1:length(N(:))
                        [xk,yk] = ind2sub(size(N),kk);
                        currFrac = N(xk,yk)/max(N(:));
                        currColor = (currFrac)*plotColor + (1-currFrac)*baseColor;
                        currPointIds = xk == binX & yk == binY;
                        CurrColorVec(currPointIds,:) = repmat(currColor,sum(currPointIds),1);
                    end
                    % plot
                    currObj = scatter(currSub, X(:,jj), X(:,ii), scatterScale, CurrColorVec); 
                    
%                     % IMAGESC
%                     % transpose to correct axes
%                     N = N';
%                     ColorMat = nan(size(N,1),size(N,2),3);
%                     for xk = 1:size(N,1)
%                         for yk = 1:size(N,2)
%                             currFrac = N(xk,yk)/maxVal;
%                             currColor = (currFrac)*plotColor + (1-currFrac)*baseColor;
%                             ColorMat(xk,yk,:) = currColor;
%                         end
%                     end
%                     currObj = imagesc(xEdges,yEdges,ColorMat);
%                     set(gca,'YDir','normal')
                    
                    % set background to base color
                    set(currSub, 'color', baseColor)
                else
                    % use plotColor
                    currObj = uq_plot(currSub, X(:,jj), X(:,ii), scatterArg{:});
                end       
                
                % format with scatter arguments
                ScatterHandles = [ScatterHandles currObj];
                
            else
                % Scaling
                if ~scaleProvided
                    maxVal = max(Ycell{ii,jj}(:));
                    ScaleMat(ii,jj,:) = [0; maxVal];
                else
                    maxVal = ScaleMat(ii,jj,2);
                end
                
                % Plot an image
                Frac = Ycell{ii,jj}'/maxVal;
                Frac(Frac>1)=1;
                if min(Frac(:)) < 0
                    warning('Negative values are cut off in plot.')
                    Frac(Frac(:)<0) = 0;
                end
                Color = nan(size(Frac,1),size(Frac,2),3);
                for kk = 1:size(Frac,1)
                    for ll = 1:size(Frac,2)
                        Color(kk,ll,:) = Frac(kk,ll)*plotColor + (1-Frac(kk,ll))*baseColor;
                    end
                end
                currObj = imagesc(X(:,jj),X(:,ii),Color);
                set(gca,'YDir','normal')
            end
            
            % default formatting for axes
            uq_formatDefaultAxes(currSub)
            AxisHandles = [AxisHandles currSub];
        else
            % hide axes
            set(currSub,'visible','off')
        end        
        
        if uq_checkMATLAB('r2018b')
            % modify exploration toolbar
            axtoolbar(currSub, {'zoomin','zoomout','restoreview'});
        end
                
        % some more formatting
        currSubFontSize = get(currSub,'FontSize');
        if any(strcmpi(axes_DEFAULTS,'FontSize'))
            idx = find(strcmpi(axes_DEFAULTS,'FontSize'));
            axes_DEFAULTS{idx + 1} = fontScale*currSubFontSize;
        else
            axes_DEFAULTS = [axes_DEFAULTS(:)',{'FontSize'}, {fontScale*currSubFontSize}];
        end
        AxisHandles = [AxisHandles currSub];
        
        
        % format ticks
        labelHandles = formatTicks(currSub, plotLimits, plotLabels, plotLabels_flag, ii, jj, nDim, labelHandles);
       
        % Display point estimate if requested
        if plotPoints_flag
            nPointGroups = length(plotPoints.X);
            % store legend name
            pointsLegend = plotPoints.Type;
            % get colors
            pointColors = uq_colorOrder(nPointGroups+1);
            pointColors = pointColors(2:end,:);
            for pp = 1:nPointGroups
                plotPointsCurr = plotPoints.X{pp};
                if ii == jj
                    % histogram
                    hold on
                    for xx = 1:size(plotPointsCurr,1)
                        uq_plot(currSub,...
                            [plotPointsCurr(xx,ii) plotPointsCurr(xx,ii)],...
                            get(gca,'ylim'), 'Color', pointColors(pp,:))
                    end
                    hold off
                elseif jj < ii
                    % scatterplot
                    hold on
                    pointPlot(pp) = uq_plot(...
                        plotPointsCurr(:,jj), plotPointsCurr(:,ii), '+',...
                        'MarkerSize', 8, 'LineStyle', 'none','Color',pointColors(pp,:));
                    hold off
                end   
            end
        end     
        
        % Store axes and objects
        AX(ii,jj) = currSub;
        S(ii,jj) = currObj;
    end
end

% add listeners and callbacks to all axes to link limits
for ii = 1:nDim
    for jj = 1:ii
        % add listener to change XLim of all other plots in same column
        addlistener(AX(ii,jj),'XLim','PostSet',@(src,evnt) changeAxLimits(src,evnt,AX,ii,jj));
        if ii ~= jj
            % 2D marginals, change also YLim of other plots in same row
            addlistener(AX(ii,jj),'YLim','PostSet',@(src,evnt) changeAxLimits(src,evnt,AX,ii,jj));
        end 
    end
end

if plotPoints_flag
    % Add callback for figure change to scale point estimate line
    try
        % add callback to figure
        set(currFig,'SizeChangedFcn',{@resizeui, pointLine, AX});
        notify(currFig,'SizeChanged')
    catch
        % not supported
    end
    % add legend
    if logical(exist('pointPlot','var'))
        % Create dummy axes in upper right corner
        linIdx = sub2ind([nDim, nDim],1,nDim);
        currSub = uq_subplot(nDim,nDim,linIdx);
        set(currSub,'visible','off')
        uq_legend(currSub, pointPlot, pointsLegend, 'Location', 'northeast','FontSize', 16)
    end
end


if nDim > 1
    % place labels at correct position after all plots have been created
    % loop over labels and determine minimum x/y positions
    if plotLabels_flag
        yPos = zeros(nDim,1); xPos = zeros(nDim,1);
        for ii = 1:nDim
            yPos(ii) = labelHandles.X(ii).Position(2); % y-coordinate
            xPos(ii) = labelHandles.Y(ii).Position(1); % x-coordinate
        end
        minYPos = max(min(yPos), 0); minXPos = max(min(xPos),0);
        for ii = 1:nDim
            % first X labels
            labelHandles.X(ii).Position(2) = minYPos;
            labelHandles.X(ii).Position(3) = 1;
            % then Y labels
            labelHandles.Y(ii).Position(1) = minXPos;
            labelHandles.Y(ii).Position(3) = 1;
        end
    end
end


%% Format the plots in one go
uq_formatDefaultAxes(AxisHandles,axes_DEFAULTS{:});
uq_formatGraphObj(HistHandles, [], hist_DEFAULTS);
uq_formatGraphObj(ScatterHandles, scatterArg, scatter_DEFAULTS);
%% Return the output if requested
if nargout > 0
    h = S;
    Axs = AX;
    bigAx = ParentAx;
end

end

%% ------------------------------------------------------------------------
function resizeui(hObject ,event, LineContainer, AxesContainer)
% loop over lines and set y limit dynamically if the figure is resized

for ii = 1:length(LineContainer)
    yLimCurr = AxesContainer(ii,ii).YLim;
    set(LineContainer(ii), 'YData', yLimCurr);
end

end

function labelHandles = formatTicks(currSub, plotLimits, plotLabels, plotLabels_flag, ii, jj, nDim, labelHandles)
% Take care of axis labels and ticks
[xTicks, yTicks] = getTicks(plotLimits, ii, jj);
currFontSize = get(currSub,'FontSize');

% plot labels
if ii == nDim
    if plotLabels_flag
        labelHandles.X(jj) = xlabel(currSub,plotLabels{jj},'FontSize',2.*currFontSize,'Units','normalized');
    end
end
if jj == 1
    if plotLabels_flag
        labelHandles.Y(ii) = ylabel(currSub,plotLabels{ii},'FontSize',2.*currFontSize,'Units','normalized');
    end
end
    

if ii == jj
    % Diagonal elements
    set(currSub,...
        'XTick', xTicks,...
        'YTick', [],...
        'XTickLabel', [],...
        'YTickLabel', [],...
        'XLim', plotLimits(:,ii)');
    if jj == nDim
        % Last element of the diagonal
        % NOTE: for backward compatibility with R2014a
        if isprop(currSub.XAxis,'Exponent')
            currSub.XAxis.Exponent = 0;
        end
        % NOTE: for backward compatibility with R2014a
        if which('xtickformat')
            custTickFormat('x', xTicks)
        end
        % NOTE: for backward compatibility with R2014a
        if which('xtickangle')
            xtickangle(45)
        end
    end
elseif jj < ii
    % Off-Diagonal elements
    set(currSub,...
        'YTick',yTicks,...
        'XTick',xTicks,...
        'XTickLabel', [],...
        'YTickLabel', [],...
        'XLim', plotLimits(:,jj)',...
        'YLim', plotLimits(:,ii)');
    if jj == 1
        % First column (axes and tick labels on the left)
        % NOTE: for backward compatibility with R2014a
        if isprop(currSub.YAxis,'Exponent')
            currSub.YAxis.Exponent = 0;
        end
        % NOTE: for backward compatibility with R2014a
        if which('ytickformat')
            custTickFormat('y', yTicks)
        end
        % NOTE: for backward compatibility with R2014a
        if which('ytickangle')
            ytickangle(45)
        end
    end
    if ii == nDim
        % Last row (axes and tick labels on the bottom)
        % NOTE: for backward compatibility with R2014a
        if isprop(currSub.XAxis,'Exponent')
            currSub.XAxis.Exponent = 0;
        end
        % NOTE: for backward compatibility with R2014a
        if which('xtickformat')
            custTickFormat('x', xTicks)
        end
        % NOTE: for backward compatibility with R2014a
        if which('xtickangle')
            xtickangle(45)
        end
    end
end
end

function [xTicks, yTicks] = getTicks(plotLimits, ii, jj)
% return padded ticks for plots
plotPadding = 0.05;
NumTicks = 2;

% compute ticks
rangeSample = plotLimits(2,:) - plotLimits(1,:);
plotLimitsPadd = [plotLimits(1,:) + plotPadding*rangeSample;...
              plotLimits(2,:) - plotPadding*rangeSample;]; 
xTicks = linspace(plotLimitsPadd(1,jj),plotLimitsPadd(2,jj),NumTicks);
yTicks = linspace(plotLimitsPadd(1,ii),plotLimitsPadd(2,ii),NumTicks);
end

function custTickFormat(axDir, axTicks)
% Custom tick label formatting
% Cut off exponent for label formatting
cutOffExp = 2;
% format axis ticks
switch axDir
    case 'x'
        if log(max(axTicks)) >= cutOffExp
            xtickformat('%8.2e')
        else
            xtickformat('%8.2e')
        end
    case 'y'
        if log(max(axTicks)) >= cutOffExp
            ytickformat('%8.2e')
        else
            ytickformat('%8.2e')
        end
end
end         

%% Callbacks
function changeAxLimits(src,evnt,AX,ii,jj)
% change the axis limits of all relevant axes
currAx = AX(ii,jj);
NDim = size(AX,1);
% compute new ticks
currXLim = currAx.XLim;
currYLim = currAx.YLim;
[xTicks, yTicks] = getTicks([currXLim.', currYLim.'], 2, 1);

% change X limits of column (without diagonal)
for kk = jj+1:NDim
    ax = AX(kk,jj);
    % don't set AX(ii,jj) again
    if ~(kk == ii)
        % disable listener, set property, reenable listener
        ax.AutoListeners__{1}.Enabled = 0;
        set(ax, 'XLim', currXLim)
        ax.AutoListeners__{1}.Enabled = 1;
    end
    % set axis ticks
    set(ax, 'XTick', xTicks)
end

% change Y limits of row (without diagonal)
for ll = 1:ii-1
    ax = AX(ii,ll);
    % don't set AX{ii,jj} again
    if ~(ll == jj)
        % disable listener, set property, reenable listener
        ax.AutoListeners__{2}.Enabled = 0;
        set(ax, 'YLim', currXLim)
        ax.AutoListeners__{2}.Enabled = 1;
    end
    % set axis ticks
    set(ax, 'YTick', xTicks)
end

% change X limits of diagonal
% don't set limits of AX{ii,jj} again if ii == jj
if ~(ii == jj)
    % first the row-diagonal
    ax = AX(ii,ii);
    % do not disable the listener to allow cascading of callbacks
    set(ax, 'XLim', currYLim)
    % set axis ticks
    set(ax, 'XTick', yTicks)
    
    % then the column-diagonal
    ax = AX(jj,jj);
    % do not disable the listener to allow cascading of callbacks
    set(ax, 'XLim', currXLim)
    % set axis ticks
    set(ax, 'XTick', xTicks)
else
    % current axis is a diagonal
    ax = AX(ii,ii);
    % set axis ticks
    set(ax, 'XTick', xTicks)
end
end