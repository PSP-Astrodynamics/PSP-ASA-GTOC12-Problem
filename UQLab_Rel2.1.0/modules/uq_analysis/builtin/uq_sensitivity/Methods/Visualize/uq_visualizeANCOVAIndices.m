function H = uq_visualizeANCOVAIndices(Results, Outputs, varargin)
% H = UQ_VISUALIZEANCOVAINDICES(RESULTS,OUTIDX,VARARGIN): graphical
%     representation of the ANCOVA indices in the results structure
%     RESULTS.
%
% See also: UQ_DISPLAY_UQ_SENSITIVITY

%% Universal options for the ANCOVA Indices Plots
GlobalOptions.NIndices = 10; % max. number of Indices to plot (total and 1st order)
GlobalOptions.YTicks = 0:0.2:10; % Ticks of y-axis in plots

%% Parse Input Arguments
if ~exist('Outputs', 'var') || isempty(Outputs)
    Outputs = 1;
end
% 
Tag = '';

%% Produce plot(s)
% initialize figure handle container
H = {};

% Check how many outputs are there:
NOuts = length(Outputs);
OutputTag = '';

% Grab earlier specifications
NIndices = GlobalOptions.NIndices;
YTicks = GlobalOptions.YTicks;

for oo = Outputs
    % Get the number of indices
    NumOfIndices = length(Results.FirstOrder(:,oo));
    XTicks = ceil(linspace(1,NumOfIndices, min(NumOfIndices,NIndices)));
    TickNames = Results.VariableNames(XTicks);
    
    if NOuts > 1
        OutputTag = sprintf(', output #%d', oo);
    end
    
    % Set the y-axis limits and make sure to have two different values
    round_limit = 0.15;
    ylimitunc = ([floor(min(Results.Uncorrelated(:,oo))/round_limit)*round_limit,...
        ceil(max(Results.Uncorrelated(:,oo))/round_limit)*round_limit]);
    if ylimitunc(1)==ylimitunc(2)
        ylimitunc(2) = ylimitunc(1)+0.3;
    end
    ylimitint = ([floor(min(Results.Interactive(:,oo))/round_limit)*round_limit,...
        ceil(max(Results.Interactive(:,oo))/round_limit)*round_limit]);
    if ylimitint(1)==ylimitint(2)
        ylimitint(2) = ylimitint(1)+0.3;
    end
    ylimitcor = ([floor(min(Results.Correlated(:,oo))/round_limit)*round_limit,...
        ceil(max(Results.Correlated(:,oo))/round_limit)*round_limit]);
    if ylimitcor(1)==ylimitcor(2)
        ylimitcor(2) = ylimitcor(1)+0.3;
    end
    ylimitfis = ([floor(min(Results.FirstOrder(:,oo))/round_limit)*round_limit,...
        ceil(max(Results.FirstOrder(:,oo))/round_limit)*round_limit]);
    if ylimitfis(1)==ylimitfis(2)
        ylimitfis(2) = ylimitfis(1)+0.3;
    end
    
    % --- UNCORRELATED INDICES --- %
    % Create the figure
    H{end+1} = uq_figure('name',...
        sprintf('%sUncorrelated ANCOVA indices%s', Tag, OutputTag));
    hold on
    ax = gca;
    uq_formatDefaultAxes(ax)
    % Create the bar plot
    x = 1:NumOfIndices;
    uq_bar(x, Results.Uncorrelated(:,oo))
    ylim(ylimitunc)

    % Fix labels, title and axis properties of the plot
    title('Uncorrelated ANCOVA indices')
    ylabel('$\mathrm{S_i^{U}}$')
    set(ax, 'XTick', XTicks, 'XTickLabel', TickNames, 'YTick', YTicks)
    hold off

    % --- INTERACTIVE indices --- %
    % Create the figure
    H{end+1} = uq_figure('name',...
        sprintf('%sInteractive ANCOVA indices%s', Tag, OutputTag));
    hold on
    ax = gca;
    uq_formatDefaultAxes(ax)
    % Create the bar plot
    x = 1:NumOfIndices;
    % NOTE: R2014a does not support axes property 'ColorOrderIndex',
    % so the color of the bar in the subsequent plot needs to be set
    % manually.
    colorOrder = get(ax,'ColorOrder');
    uq_bar(x, Results.Interactive(:,oo), 'FaceColor', colorOrder(2,:))
    ylim(ylimitint) 
    
    % Fix labels, title and axis properties of the plot
    title('Interactive ANCOVA indices')
    ylabel('$\mathrm{S_i^{I}}$')
    set(ax, 'XTick', XTicks, 'XTickLabel', TickNames, 'YTick', YTicks);
    hold off

    % --- CORRELATED INDICES --- %
    % Create the figure
    H{end+1} = uq_figure('name',...
        sprintf('%sCorrelated ANCOVA indices%s', Tag, OutputTag));
    hold on
    ax = gca;
    uq_formatDefaultAxes(ax)
    % Create the bar plot
    x = 1:NumOfIndices;
    uq_bar(x, Results.Correlated(:,oo), 'FaceColor', colorOrder(3,:))
    ylim(ylimitcor)

    % Fix titles, labels, and axis properties of the plot
    title('Correlated ANCOVA indices')
    ylabel('$\mathrm{S_i^{C}}$')
    set(ax, 'XTick', XTicks, 'XTickLabel', TickNames, 'YTick', YTicks)
    
    % --- SUMMED UP FIRST ORDER INDICES --- %
    % Create the figure
    H{end+1} = uq_figure('name',...
        sprintf('%sFirst order ANCOVA indices%s', Tag, OutputTag));
    hold on
    ax = gca;
    uq_formatDefaultAxes(ax)
    % Create the bar plot
    x = 1:NumOfIndices;
    uq_bar(x, Results.FirstOrder(:,oo), 'FaceColor', colorOrder(4,:))
    ylim(ylimitfis)
    
    % Fix title, labels, and axis properties of the plot
    title('First-order ANCOVA indices')
    ylabel('$\mathrm{S_i}$')
    set(ax, 'XTick', XTicks, 'XTickLabel', TickNames, 'YTick', YTicks)
    hold off

end