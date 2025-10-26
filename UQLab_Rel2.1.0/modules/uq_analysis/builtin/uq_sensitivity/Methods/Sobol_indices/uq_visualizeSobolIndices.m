function H = uq_visualizeSobolIndices(Results, Outputs, varargin)
% UQ_VISUALIZESOBOLINDICES(RESULTS,OUTIDX,VARARGIN): graphical
%     representation of the Sobol' indices in the results structure
%     RESULTS.
%
% See also: UQ_DISPLAY_UQ_SENSITIVITY

%% Universal options for the Sobol' Indices Plots
GlobalOptions.NIndices = 10; % max. number of Indices to plot (total and 1st order)
GlobalOptions.NIndicesHigh = 5; % max number of indices to plot (higher orders)
GlobalOptions.YTicks = 0:0.2:1; % Ticks of y-axis in plots
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
    if isfield(Results,'Total')
        NumOfIndices = length(Results.Total(:,oo));
        if NOuts > 1
            OutputTag = sprintf(', output #%d', oo);
        end

        % --- TOTAL INDICES --- %
        if hist_flag
            % Create the figure
            H{end+1} = uq_figure('name',...
                sprintf('%sTotal Sobol'' indices%s', Tag, OutputTag));
            hold on
            ax = gca;
            uq_formatDefaultAxes(ax)
            % Create the bar plot
            x = 1:NumOfIndices;

            uq_bar(x, Results.Total(:,oo),'FaceColor', MyColors(1,:));
            % Add error bars if Bootstrap option is set
            if Bootstrap
                lb = Results.Bootstrap.Total.Mean(:,oo) -...
                    Results.Bootstrap.Total.CI(:,oo,1);
                ub = Results.Bootstrap.Total.CI(:,oo,2) -...
                    Results.Bootstrap.Total.Mean(:,oo);
                errorbar(x, Results.Total(:,oo), lb, ub,...
                    'kx', 'LineStyle', 'none', 'LineWidth', 2);
            end
            % Fix labels, title and axis properties of the plot
            customize_Sobol_plot(gca, oo, Results, 'total', GlobalOptions );
        end

        if pie_flag
            % Create the figure
            H{end+1} = uq_figure('name',...
                sprintf('%sTotal Sobol'' indices (pie)%s', Tag, OutputTag));
            % Create the pie chart
            x = zeros(size(Results.Total(:,oo)));
            pp = pie3(Results.Total(:,oo), x, cellstr(Results.VariableNames'));
            set(findobj(pp, 'type', 'surface'), 'EdgeColor', 'k')
            set(findobj(pp, 'type', 'patch'), 'EdgeColor', 'k')
            material metal
            camlight
            rotate3d on
        end
    end
    
    % --- i-th ORDER INDICES: only print the first few --- %
    coloridx = 1;
    if isfield(Results,'AllOrders')
        for ii = 1:length(Results.AllOrders)
            coloridx = mod(coloridx, length(MyColors)) + 1;
            if ii > 1
                % Higher-order Indices : plot at most  GlobalOptions.NIndices
                % indices
                NumOfIndices = min(length(Results.AllOrders{ii}(:,oo)),...
                    GlobalOptions.NIndicesHigh);
                [CurIndices, idx]= sort(Results.AllOrders{ii}(:,oo),...
                    GlobalOptions.IdxSorting);
                idx = idx(1:NumOfIndices);
                CurIndices = CurIndices(1:NumOfIndices);
            else
                % First-order Indices : plot all indices
                NumOfIndices = length(Results.AllOrders{ii}(:,oo));
                CurIndices = Results.AllOrders{ii}(:,oo);
                idx = 1:length(CurIndices);
            end

            if hist_flag
                % Create the figure
                fname = sprintf('Sobol'' indices Order %d', ii);
                H{end+1} = uq_figure('name', sprintf('%s%s%s', Tag, fname, OutputTag));
                hold on
                ax = gca;
                uq_formatDefaultAxes(ax)
                % Create the bar plot
                x = 1:length(idx);
                uq_bar(x, CurIndices, 'FaceColor', MyColors(1,:))
                % Add error bars if Bootstrap option is set
                if Bootstrap
                    lb = Results.Bootstrap.AllOrders{ii}.Mean(idx,oo) -...
                        Results.Bootstrap.AllOrders{ii}.CI(idx,oo,1);
                    ub = Results.Bootstrap.AllOrders{ii}.CI(idx,oo,2) -...
                        Results.Bootstrap.AllOrders{ii}.Mean(idx,oo);
                    errorbar(x,...
                        Results.AllOrders{ii}(idx,oo), lb, ub,...
                        'kx', 'LineStyle', 'none', 'LineWidth', 2)
                end
                % Fix labels, title and axis properties of the plot
                customize_Sobol_plot(gca, oo, Results, 'i-th order',...
                    GlobalOptions, ii, idx)
            end

            if pie_flag && ii == 1
                % Create the figure
                fname = sprintf('Sobol'' indices Order %d (pie)', ii);
                H{end+1} = uq_figure('name', sprintf('%s%s%s ', Tag, fname, OutputTag));
                % Create the bar plot
                x = zeros(size(CurIndices));
                pp = pie3(CurIndices/sum(CurIndices), x,...
                    cellstr(Results.VariableNames(Results.VarIdx{ii})'));
                set(findobj(pp, 'type', 'surface'), 'EdgeColor', 'k')
                set(findobj(pp, 'type', 'patch'), 'EdgeColor', 'k')
                set(findobj(pp, 'type', 'surface'), 'FaceAlpha', 0.95)
                set(findobj(pp, 'type', 'patch'), 'FaceAlpha', 0.95)
                rotate3d on
            end
        end
    end
end

end

function customize_Sobol_plot(ax, oo, Results, IndType, ...
    GlobalOptions, current_order,idx  )

switch lower(IndType)
    case 'total'
       NumOfIndices = length(Results.Total(:,oo));
       title('Total Sobol'' indices')
       ylabel('$\mathrm{S_i^{Tot}}$')
       customize_axes(ax, oo, Results, IndType, GlobalOptions)
       ylim([0, 1])
    case 'i-th order'
        NumOfIndices = length(Results.AllOrders{current_order}(:,oo));
        if current_order > 1
            % For high order indices make sure
            % that maximally GlobalOptions.NIndices are going to be plotted
            NumOfIndices = min(NumOfIndices, GlobalOptions.NIndicesHigh);
        end
        fname = sprintf('Sobol'' indices Order %d', current_order);
        title(fname)
        ylabel(sprintf('$\\mathrm{S_{u}^{(%d)}}$', current_order))
        customize_axes(ax, oo, Results, IndType, GlobalOptions,...
            current_order,idx)
        if current_order == 1
           ylim([0, 1]); 
        end
        set(ax, 'YTickMode', 'auto')
end

xlim([0, NumOfIndices + 1]);

end

function customize_axes(ax, oo, Results, IndType, GlobalOptions,...
        current_order, idx)
% Helper function for setting the xticks of an axis object used for plotting 
% of Sobol' indices
NIndices = GlobalOptions.NIndices;
YTicks = GlobalOptions.YTicks;

switch lower(IndType)
    case 'total'
        NumOfIndices = length(Results.Total(:,oo));
        XTicks = ceil(linspace(1, NumOfIndices,...
            min(NumOfIndices,NIndices)));
        TickNames = Results.VariableNames(XTicks);
    case 'i-th order'
        if current_order == 1
            NumOfIndices = length(Results.AllOrders{current_order}(:,oo));
            XTicks = ceil(linspace(1,NumOfIndices,...
                min(NumOfIndices,NIndices)));
            TickNames = Results.VariableNames(XTicks);
        else
            NIndices = GlobalOptions.NIndicesHigh;
            NumOfIndices = length(Results.AllOrders{current_order}(:,oo));
            XTicks = 1:min(NumOfIndices,NIndices);
            CurrentVarIdx = Results.VarIdx{current_order}(idx,:);
            
            TickNames = cell(length(XTicks),1);
            for jj = 1:length(XTicks)
                TickNames{jj} = sprintf('%s ',...
                    [Results.VariableNames{CurrentVarIdx(jj,:)}]);
            end
        end
        
end

set(ax, 'XTick', XTicks, 'XTickLabel', TickNames, 'YTick', YTicks)

end