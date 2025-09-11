function H = uq_visualizeKucherenkoIndices(Results, Outputs, varargin)
% H = UQ_KUCHERENKOINDICES(RESULTS,OUTIDX,VARARGIN): graphical
%     representation of the Kucherenko indices in the results structure
%     RESULTS.
%
% See also: UQ_DISPLAY_UQ_SENSITIVITY

%% Universal options for the ANCOVA Indices Plots
GlobalOptions.NIndices = 10; % max. number of Indices to plot (total and 1st order)
% GlobalOptions.NIndicesHigh = 5; % max number of indices to plot (higher orders)
GlobalOptions.YTicks = 0:0.2:10; % Ticks of y-axis in plots
% GlobalOptions.NumOfColors = 6;
% GlobalOptions.IdxSorting = 'descend'; % How to sort high-order indices

%% Parse Input Arguments
if ~exist('Outputs', 'var') || isempty(Outputs)
    Outputs = 1;
end

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
    NumOfIndices = length(Results.Total(:,oo));
    XTicks = ceil(linspace(1,NumOfIndices, min(NumOfIndices,NIndices)));
    TickNames = Results.VariableNames(XTicks);
    if NOuts > 1
        OutputTag = sprintf(', output #%d', oo);
    end
    
    % --- TOTAL INDICES --- %
    % Create the figure
    H{end+1} = uq_figure('name', sprintf('%sTotal Kucherenko indices%s', Tag, OutputTag));
    hold on
    ax = gca;
    uq_formatDefaultAxes(ax)
    % Create the bar plot
    x = 1:NumOfIndices;
    uq_bar(x, Results.Total(:,oo))
    
    % Fix title, labels, and axis properties of the plot
    title('Total Kucherenko indices')
    ylabel('$\mathrm{S_i^{T}}$')
    set(ax, 'XTick', XTicks, 'XTickLabel', TickNames, 'YTick', YTicks)
    hold off
    
    % --- FIRST ORDER INDICES --- %
    % Create the figure
    H{end+1} = uq_figure('name', sprintf('%sFirst-order Kucherenko indices%s', Tag, OutputTag));
    hold on
    ax = gca;
    uq_formatDefaultAxes(ax)
    % Create the bar plot
    x = 1:NumOfIndices;
    uq_bar(x, Results.FirstOrder(:,oo))

    % Fix title, labels, axis properties of the plot
    title('First-order Kucherenko indices')
    ylabel('$\mathrm{S_i}$');
    set(ax, 'XTick', XTicks, 'XTickLabel', TickNames, 'YTick', YTicks)
    hold off

end
