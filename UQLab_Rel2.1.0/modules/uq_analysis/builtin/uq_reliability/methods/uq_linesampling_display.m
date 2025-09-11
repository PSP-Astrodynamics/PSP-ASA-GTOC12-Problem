function H = uq_linesampling_display(module, idx, varargin)
% UQ_LINESAMPLING_DISPLAY visualizes line sampling analysis and 
% its results
%
% See also: UQ_LINESAMPLING, UQ_DISPLAY_UQ_RELIABILITY

Results = module.Results;

% initialize figure handle container
H = {};

%for each response quantity
for oo = idx
    %only plot when more than one iteration has been done in LS
    iter = length(Results.History(oo).Pf);
    if iter ~=1
        %% Plot the convergence curve for the failure probability estimate 
        if length(idx) > 1
            figTitle = sprintf('LS: Convergence of failure probability estimate, output #%d', oo);
        else
            figTitle = 'LS: Convergence of failure probability estimate';
        end  

        N = Results.History(oo).NLines;
        H{end+1} = uq_figure('Name', figTitle);
        hold on
        ax = gca;
        uq_formatDefaultAxes(ax)
        PfPlus = Results.History(oo).Pf+Results.History(oo).Conf;
        PfMinus = max(1e-16, Results.History(oo).Pf - Results.History(oo).Conf);
        f1 = fill(...
            [N; flipud(N)],...
            [PfMinus; flipud(PfPlus)],...
            'g');
        set(f1, 'FaceColor', [0.9 0.9 0.9])
        set(gca,'Yscale','log') ;

        h1 = uq_plot(N, Results.History(oo).Pf);
        uq_legend([h1,f1], '$\mathrm{P_f}$', 'CI');
        xlabel('Number of Lines $\mathrm{N}$')
        ylabel('$\mathrm{P_f}$')
        title('LS - Convergence of $\mathrm{P_f}$')
        xlim([N(1), N(end)])
        hold off

        %% Plot the convergence curve for the reliability index (beta)
        if length(idx) > 1
            figTitle = sprintf('LS: Convergence of the reliability index, output #%d', oo);
        else
            figTitle = 'LS: Convergence of the reliability index';
        end  

        H{end+1} = uq_figure('Name', figTitle);
        hold on
        ax = gca;
        uq_formatDefaultAxes(ax)
        f2 = fill(...
            [N; flipud(N)],...
            [-icdf('normal', PfMinus, 0, 1);...
            -icdf('normal', flipud(PfPlus), 0, 1)],...
            'g');
        set(f2, 'FaceColor', [0.9 0.9 0.9])
        h2 = uq_plot(N, -icdf('normal', Results.History(oo).Pf, 0, 1));
        uq_legend([h2,f2], '$\mathrm{\beta_{LS}}$', 'CI');
        xlabel('Number of Lines $\mathrm{N}$')
        ylabel('$\mathrm{\beta_{LS}}$')
        title('LS - Convergence of $\mathrm{\beta_{LS}}$')        
        xlim([N(1), N(end)])
        hold off
    end
    
    if (length(module.Internal.Input.Marginals) == 2) && module.Internal.SaveEvaluations  
        % Add plot of evaluated lines, intersections and limit state
        if length(idx) > 1
            figTitle = sprintf('LS: Samples and Intersects in the standard normal space, output #%d', oo);
        else
            figTitle = 'LS: Samples and Intersects in the standard normal space';
        end 
        H{end+1} = uq_figure('Name', figTitle);
        ax = gca;
        % NOTE: 'hold on' command in R2014a does not cycle through
        % the color order so it must be set manually. 
        colorOrder = get(ax,'ColorOrder');

        ImportantDirection = Results.ImportantDirection(oo,:);
       
        IntersectPoints = Results.History(oo).LineData.Intersects;
        HyperplanePoints = Results.History(oo).LineData.Hyperplane;

        l = scatter(IntersectPoints(:,1), IntersectPoints(:,2), ...
             50, colorOrder(1,:), 'o', 'filled');
        hold on
        
        axis equal
        h = scatter(HyperplanePoints(:,1), HyperplanePoints(:,2), ...
             50, colorOrder(2,:), 'o', 'filled');
        
        uq_formatDefaultAxes(ax);
        
        if module.Internal.LS.Direction.Adaptive
            if any(Results.History(oo).LineData.ImportantDirection(1,:)...
                ~= Results.History(oo).LineData.ImportantDirection(end,:))

                IntialIDirection = Results.History(oo).LineData.ImportantDirection(1,:);
                % Initial important Direction
                ii = quiver(0,0,IntialIDirection(1),IntialIDirection(2), 0,...
                    'filled', 'LineWidth', 2, 'Color', colorOrder(4,:),...
                    'MaxHeadSize', 10);
            
                % Final important Direction
                fi = quiver(0,0,ImportantDirection(1),ImportantDirection(2), 0,...
                    'filled', 'LineWidth', 2, 'Color', colorOrder(3,:),...
                    'MaxHeadSize', 10);

                labels = {'Intersection', 'Hyperplane', 'Initial Direction', 'Final Direction'};
                pp = [l,h,ii,fi];
                l = uq_legend(pp, labels([~isempty(l) ~isempty(h) ~isempty(ii) ~isempty(fi)]) );
            else
        
                % Final important Direction
                fi = quiver(0,0,ImportantDirection(1),ImportantDirection(2), 0,...
                    'filled', 'LineWidth', 2, 'Color', colorOrder(3,:),...
                    'MaxHeadSize', 10);

                labels = {'Intersection', 'Hyperplane', 'Final Direction'};
                pp = [l,h,fi];
                l = uq_legend(pp, labels([~isempty(l) ~isempty(h) ~isempty(fi)]) );

            end
                
            set(l, 'interpreter', 'latex')
            uq_setInterpreters(gca)
            box on
            xlabel('$\mathrm{u_1}$')
            ylabel('$\mathrm{u_2}$')
            title('Line Sampling Intersects')
        else
            % Important Direction
            i = quiver(0,0,ImportantDirection(1),ImportantDirection(2), 0,...
                'filled', 'LineWidth', 2, 'Color', colorOrder(3,:),...
                'MaxHeadSize', 10);
            
            % Format the figure
            labels = {'Intersection', 'Hyperplane', 'Direction'};
            pp = [l,h,i];
            l = uq_legend(pp, labels([~isempty(l) ~isempty(h) ~isempty(i)]) );
            set(l, 'interpreter', 'latex')
            uq_setInterpreters(gca)
            box on
            xlabel('$\mathrm{u_1}$')
            ylabel('$\mathrm{u_2}$')
            title('Line Sampling Intersects')
        end

    end     

end

end