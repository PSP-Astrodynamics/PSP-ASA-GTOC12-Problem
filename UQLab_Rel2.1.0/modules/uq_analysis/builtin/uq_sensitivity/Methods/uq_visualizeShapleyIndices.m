function H = uq_visualizeShapleyIndices(Results, Outputs, varargin)
% H = UQ_VISUALIZESHAPLEYINDICES(RESULTS,OUTIDX,VARARGIN): graphical
%     representation of the Shapley indices in the results structure
%     RESULTS.
%
% See also: UQ_DISPLAY_UQ_SENSITIVITY

%% Universal options for the Sobol' Indices Plots
GlobalOptions.NIndices = 10; % max. number of Indices to plot (total and 1st order)
GlobalOptions.NIndicesHigh = 5; % max number of indices to plot (higher orders)
GlobalOptions.YTicks = 0:0.2:1; % Ticks of y-axis in plots
GlobalOptions.AxisFontSize = 14; 
GlobalOptions.NumOfColors = 6;
GlobalOptions.IdxSorting = 'descend'; % How to sort high-order indices

%% parse varargin options
% initialization
pie_flag = false;
hist_flag = true;

if nargin > 2
    parse_keys = {'pie', 'hist'};
    parse_types = {'f', 'f'};
    [uq_cline, varargin] = uq_simple_parser(varargin, parse_keys, parse_types);
    % 'coefficients' option additionally prints the coefficients
    if strcmp(uq_cline{1}, 'true')
        pie_flag = true;
        hist_flag = false;
    end
    
    % 'tolerance' option sets the default tolerance to plot coefficients
    if strcmp(uq_cline{2}, 'true')
        hist_flag = true;
    end

end



%% Parse Input Arguments
if ~exist('Outputs', 'var') || isempty(Outputs)
    Outputs = 1;
end

Tag = '';

if nargin < 3
    if isfield(Results, 'Bootstrap') && ~isempty(Results.Bootstrap)
        Bootstrap = 1;
    else
        Bootstrap = 0;
    end
else
    Bootstrap = 0 ;
end

if nargin < 4 % Maybe some consistency checks...
    MyColors = uq_colorOrder(GlobalOptions.NumOfColors);
else
    MyColors = varargin{2} ;
end
%% Produce plot(s)
% initialize figure handle container
H = {};

% Check how many outputs are there:
NOuts = length(Outputs);
OutputTag = '';
for oo = Outputs
    % Get the number of indices
    NumOfIndices = length(Results.Shapley(:,oo));
    if NOuts > 1
        OutputTag = sprintf(', output #%d', oo);
    end
    
    % --- SHAPLEY INDICES --- %
    if hist_flag
        % create the figure
        H{end+1} = uq_figure('name', sprintf('%Shapley indices%s', Tag,OutputTag), 'Position', [50 50 500 400]);
        hold on
        % create the bar plot
        x = 1:NumOfIndices;
        uq_bar(x, Results.Shapley(:,oo), 'facecolor', MyColors(1, :), 'edgecolor', 'none');
        % add error bars if Bootstrap option is set
%         if Bootstrap
%             lb = Results.Bootstrap.Total.Mean(:,oo) - Results.Bootstrap.Total.CI(:,oo,1);
%             ub = Results.Bootstrap.Total.CI(:,oo,2) - Results.Bootstrap.Total.Mean(:,oo);
%             errorbar(x, Results.Bootstrap.Total.Mean(:,oo), lb,ub, ...
%                 'kx', 'linestyle', 'none', 'linewidth', 2);
%         end
        % fix labels, title and axis properties of the plot
        customize_Sobol_plot(gca, oo, Results, 'total', GlobalOptions );
    end
    
    if pie_flag
        % create the figure
        H{end+1} = uq_figure('name', sprintf('%sShapley indices (pie)%s', Tag,OutputTag), 'Position', [50 50 500 400]);
        % create the bar plot
        x = zeros(size(Results.Total(:,oo)));
        pp = pie3(Results.Total(:,oo), x, cellstr(Results.VariableNames'));
        set(findobj(pp, 'type', 'surface'), 'edgecolor', 'k')
        set(findobj(pp, 'type', 'patch'), 'edgecolor', 'k')
        material metal
        camlight
        rotate3d on
    end
end





function customize_Sobol_plot(ax, oo, Results, IndType, ...
    GlobalOptions, current_order,idx  )

switch lower(IndType)
    case 'total'
       NumOfIndices = length(Results.Shapley(:,oo));
       title('Shapley indices', ...
           'fontweight', 'normal');
       ylabel('Sh_i', 'interpreter', 'tex');
       customize_axes(ax, oo, Results, IndType, GlobalOptions);
       ylim([0, 1]);
end

xlim([0, NumOfIndices + 1]);
box on;


function customize_axes(ax, oo, Results, IndType, GlobalOptions,current_order,idx)
% Helper function for setting the xticks of an axis object used for plotting 
% of Sobol' indices
NIndices = GlobalOptions.NIndices;
YTicks = GlobalOptions.YTicks;
fs = GlobalOptions.AxisFontSize ;

switch lower(IndType)
    case 'total'
        NumOfIndices = length(Results.Shapley(:,oo));
        XTicks = ceil(linspace(1,NumOfIndices, min(NumOfIndices,NIndices)));
        TickNames = Results.VariableNames(XTicks);        
end
set(ax, 'xtick', XTicks, 'xticklabel', TickNames, 'ytick', YTicks,...
            'fontsize', fs);