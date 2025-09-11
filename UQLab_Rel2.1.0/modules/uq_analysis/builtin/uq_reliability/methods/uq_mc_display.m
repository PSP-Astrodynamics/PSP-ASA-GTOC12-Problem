function H = uq_mc_display( module, idx, varargin )
% UQ_MC_DISPLAY visualizes analysis and results of the  Monte Carlo
% simulation
% 
% See also: UQ_DISPLAY_UQ_RELIABILITY

Results = module.Results;

% initialize figure handle container
H = {};

%for each response quantity
for oo = idx
    %only plot when more than one iteration has been done in MCS
    iter = length(Results.History(oo).Pf);
    if iter ~=1
        %% Plot the convergence curve for the failure probability estimate
        if length(idx) > 1
            figTitle = sprintf('MCS: Convergence of failure probability estimate, output #%d', oo);
        else
            figTitle = 'MCS: Convergence of failure probability estimate';
        end

        N = (1:iter)*module.Internal.Simulation.BatchSize;
        H{end+1} = uq_figure('Name', figTitle);
        hold on
        ax = gca;
        uq_formatDefaultAxes(ax)
        f1 = fill([N, fliplr(N)],...
            [Results.History(oo).Pf+Results.History(oo).Conf;...
            flipud(Results.History(oo).Pf - Results.History(oo).Conf) ],...
            'g');
        set(f1, 'FaceColor', [0.9 0.9 0.9])
        h1 = uq_plot(N, Results.History(oo).Pf);
        uq_legend([h1,f1], '$\mathrm{P_f}$', 'CI');
        xlabel('$\mathrm{N}$')
        ylabel('$\mathrm{P_f}$')
        title('MCS - Convergence of $\mathrm{P_f}$')
        xlim([N(1), N(end)])
        hold off

        %% Plot the convergence curve for the reliability index (beta)
        if length(idx) > 1
            figTitle = sprintf('MCS: Convergence of reliability index, output #%d', oo);
        else
            figTitle = 'MCS: Convergence of reliability index';
        end        
        H{end+1} = uq_figure('Name', figTitle);
        hold on
        ax = gca;
        uq_formatDefaultAxes(ax)
        f2 = fill(...
            [N, fliplr(N)],...
            [-icdf('normal',...
                Results.History(oo).Pf+Results.History(oo).Conf, 0, 1);...
            -icdf('normal',...
                flipud(Results.History(oo).Pf-Results.History(oo).Conf), 0, 1)],...
            'g');
        set(f2, 'FaceColor', [0.9 0.9 0.9])
        h2 = uq_plot(N, -icdf('normal', Results.History(oo).Pf, 0, 1));
        uq_legend([h2,f2], '$\mathrm{\beta_{MC}}$', 'CI');
        xlabel('$\mathrm{N}$')
        ylabel('$\mathrm{\beta_{MC}}$')
        title('MCS - Convergence of $\mathrm{\beta_{MC}}$')        
        xlim([N(1), N(end)])
        hold off
    end
    
    switch length(module.Internal.Input.Marginals)
        case 2
            % Plot safe/fail sample points only for 2-dimensional problem
            if length(idx) > 1
                figTitle = sprintf('MCS: Samples, output #%d', oo);
            else
                figTitle = 'MCS: Samples';
            end                
            if module.Internal.SaveEvaluations                
                nplot = min(size(module.Results.History(end).G,1),1e4);
                LSF = module.Results.History(end).G(1:nplot,oo);
                XSamples = module.Results.History(end).X(1:nplot,:);
                % Plot failed sample points
                H{end+1} = uq_figure('Name', figTitle);
                ax = gca;
                % NOTE: 'hold on' command in R2014a does not cycle through
                % the color order so it must be set manually. 
                colorOrder = get(ax,'ColorOrder');
                a1 = uq_plot(...
                        XSamples(LSF<=0,1), XSamples(LSF<=0,2), 'o',...
                        'MarkerSize', 3,...
                        'MarkerFaceColor', colorOrder(1,:),...
                        'Color', colorOrder(1,:));
                hold on
                % Plot safe sample points
                a2 = uq_plot(...
                        XSamples(LSF>0, 1), XSamples(LSF>0, 2), 'o',...
                        'MarkerSize', 3,...
                        'Color', colorOrder(2,:),...
                        'MarkerFaceColor', colorOrder(2,:),...
                        'Color', colorOrder(2,:));
                hold off
                % Set title and axes labels
                title('MCS - Samples')
                xlabel('$\mathrm{x_1}$')
                ylabel('$\mathrm{x_2}$')
                
                % Add legend (only if necessary)
                if isempty(a2)
                    % No safe points
                    uq_legend(a1,'$\mathrm{g(X)\leq 0}$');
                elseif isempty(a1)
                    % No failed points
                    uq_legend(a2,'$\mathrm{g(X)>0}$');
                else
                    uq_legend(...
                        [a1,a2],...
                        '$\mathrm{g(X)\leq 0}$', '$\mathrm{g(X)>0}$');
                end
            end
    end     
end

end
