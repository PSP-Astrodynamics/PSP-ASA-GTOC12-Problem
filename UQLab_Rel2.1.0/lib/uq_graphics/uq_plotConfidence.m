function handles = uq_plotConfidence(X, Y, Conf, varargin)
%UQ_PLOTCONFIDENCE plots a line plot with its confidence bounds.
% 
% See also: UQ_KRIGING_DISPLAY, UQ_PCK_DISPLAY, UQ_SVR_DISPLAY.

%% Set default color
% Set to default the coloring options:
lineColor = uq_colorOrder(1);
lineWidth = 2;

boundColor = [128 128 128]/255;  % Gray in RGB scale
alphaN = 0.3;

%% Parse optional inputs
if nargin > 3
    if mod(length(varargin),2)
        error('Incorrect number of options.')
    end
    for ii = 1:2:length(varargin) - 1
        switch(lower(varargin{ii}))
            case 'linecolor'
                lineColor = varargin{ii+1};
            case 'boundcolor'
                boundColor = varargin{ii+1};
            case 'alpha'
                alphaN = varargin{ii+1};
            case 'linewidth'
                lineWidth = varargin{ii+1};
        end
    end
end

%% Create the plot
% Plot the mean as a line
handles(1) = uq_plot(X, Y, 'Color', lineColor, 'LineWidth', lineWidth);
hold on
% Plot the confidence bound
if size(Conf,2)==1
    handles(2) = fill(...
        [X(:); flipud(X(:))], [Y(:)+Conf(:); flipud(Y(:)-Conf(:))], boundColor,...
        'LineStyle', 'none');
elseif size(Conf,2)==2
    handles(2) = fill(...
        [X(:); flipud(X(:))], [Conf(:,1); flipud(Conf(:,2))], boundColor,...
        'LineStyle', 'none');
end
alpha(alphaN)
hold off

end
