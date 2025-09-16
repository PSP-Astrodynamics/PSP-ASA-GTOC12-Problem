function [plotAxs, H] = uq_traceplot(varargin)
%UQ_TRACEPLOT creates trace plots of the series of points with the kernel density-based marginal estimates.
%
%   UQ_TRACEPLOT(X) plots the trace plots of an N-by-M-by-C array X. By
%   default, M figures are created.
%
%   UQ_TRACEPLOT(..., NAME, VALUE) modifies the properties of the trace
%   plots according to the specified NAME/VALUE pairs. The possible pair
%   is:
%
%       Name            VALUE
%       'labels'        string array of labels used for plotting - CHAR
%                       default : {'X_1',...,'X_M'}
%
%   UQ_TRACEPLOT(AXES,...) plots into the cell array of Axes objects AXES.
%
%   PLOTAX = UQ_TRACEPLOT(...) returns the Axes objects of the
%   generated plot in an M-by-2 cell array. In MATLAB R2014a or older,
%   the function returns a cell array with handles to the Axes objects.
%
%   [..., H] = UQ_TRACEPLOT(...) additionally returns the Figure handles.
%
%   See also UQ_MH, UQ_AM, UQ_HMC, UQ_AIES, UQ_DISPLAY_UQ_INVERSION.

%% Verify inputs
if nargin == 0
    error('Not enough input arguments.')
end

%% Parse inputs

% Check if axes object is given as the first argument
if iscell(varargin{1})
    isAxes = uq_isAxes(varargin{1}{1});
    if isAxes
        axesGiven = true;
        plotAx = varargin{1};
        varargin = varargin(2:end);
    else
        error('Cell input must consist of Axes objects.')
    end
else
    axesGiven = false;
end

% get X
if isnumeric(varargin{1})
    X = varargin{1};
    varargin = varargin(2:end);
else
    error('The input is not numeric.')
end

%% DEFAULTS
[N,M,~] = size(X);
for ii = 1:M
    Default.labels{ii} = sprintf('$X_%i$',ii);
end

%% Parse optional input
if ~isempty(varargin)
    % varargin given
    parse_keys = {'labels'};
    parse_types = {'p'};
    % make NAME lower case
    varargin(1:2:end) = lower(varargin(1:2:end));
    [uq_cline, ~] = uq_simple_parser(varargin, parse_keys, parse_types);
else
    % no varargin, use default options
    uq_cline{1} = Default.labels;
end

% 'labels' to be used for each dimension
if ~strcmp(uq_cline{1}, 'false')
    % normal label
    paramLabels = uq_cline{1};
    % pdf label
    for ii = 1:M
        % check if first character is $ (i.e. math mode)
        currLabel = paramLabels{ii};
        if strcmp(currLabel(1),'$')
            % math mode, remove '$' from start and end
            modLabel = currLabel(2:end-1);
            paramPDFLabels{ii} = strcat('$\pi(',modLabel,')$');
        else
            % not math mode
            paramPDFLabels{ii} = strcat('$\pi(\mathrm{',currLabel,'})$');
        end
    end
    plotLabels_flag = true;
else
    plotLabels_flag = false;
end

% INITIALIZE PLOT
% Determine if this is the first time te plot function is called. If not,
% the function will just update the existing plot.
if ~axesGiven
    % Create plot figure(s)
    for ii = 1:M
        H{ii} = uq_figure;
        % FIRST subplot for trace
        plotAx{ii,1} = subplot(1,2,1);
        uq_formatDefaultAxes(plotAx{ii,1})
        % set axes label
        xlabel('Steps')
        ylabel(paramLabels{ii})
        % SECOND subplot for KDE
        plotAx{ii,2} = subplot(1,2,2);
        uq_formatDefaultAxes(plotAx{ii,2})
        % Set axes label
        set(gca,'YTickLabel',[])
        xlabel(paramPDFLabels{ii})
    end
end

% Loop over plot axes and update data and limits
for ii = 1:M
    % Get current X, per dimension.
    Xcurr = squeeze(X(:,ii,:));
    % Kernel smoothing density
    [f,xi] = ksdensity(reshape(Xcurr,[],1));
    
    % Check if plotAx Children are empty
    if isempty(get(plotAx{ii,1},'Children'))
        % Create a new plot, trace
        hold(plotAx{ii,1},'on')
        uq_plot(...
            plotAx{ii,1}, 1:N, Xcurr,...
            'LineWidth', 1,...
            'Color', [0.7 0.7 0.7]);
        hold(plotAx{ii,1},'off')
        % Create a new plot, kernel density
        hold(plotAx{ii,2},'on')
        uq_plot(plotAx{ii,2},f,xi);
        hold(plotAx{ii,2},'off')
    else
        % Just update the data
        % Get the 'Line' children objects
        childObjectsTrace = get(plotAx{ii,1},'Children');
        nChildren = length(childObjectsTrace);
        for jj = 1:nChildren            
            set(childObjectsTrace(jj), 'xdata', 1:N, 'ydata', Xcurr(:,jj))
        end
        childObjectsKDens = get(plotAx{ii,2},'Children');
        set(childObjectsKDens,'xdata',f,'ydata',xi)
    end
    
    % Set limits
    ylim(plotAx{ii,2},get(plotAx{ii,1},'YLim'));
    xlim(plotAx{ii,1},[1 inf])
end

% Drawnow
drawnow()

%% Return output if requested
if nargout > 0
    plotAxs = plotAx;
end

end
