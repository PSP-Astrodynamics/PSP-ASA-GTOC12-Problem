function H = uq_importancesampling_display( module, idx, varargin )
% UQ_IMPORTANCESAMPLING_DISPLAY visualizes importance sampling analysis and 
% its results
%
% See also: UQ_SR_IMPORTANCE_SAMPLING, UQ_DISPLAY_UQ_RELIABILITY

Results = module.Results;

% initialize figure handle container
H = {};

% for each output index
for oo = idx
    
    %% Plot the convergence curve for the failure probability estimate
    iter = length(Results.History(oo).Pf);
    if iter ~=1
        if length(idx) > 1
            figTitle = sprintf('IS: Convergence of failure probability estimate, output #%d', oo);
        else
            figTitle = 'IS: Convergence of failure probability estimate';
        end        
        N = (1:iter)*module.Internal.Simulation.BatchSize;
        H{end+1} = uq_figure('Name',figTitle);
        h1 = uq_plot(N, Results.History(oo).Pf);
        hold on
        f1 = fill(...
            [N, fliplr(N)],...
            [Results.History(oo).Pf+Results.History(oo).Conf,...
                fliplr(Results.History(oo).Pf-Results.History(oo).Conf)],...
            'g');
        set(f1, 'FaceColor', [0.9 0.9 0.9])
        set(gca, 'xtick', unique(round(get(gca, 'xtick'))))
        % Bring the line plot forward
        cc = get(gca,'Children');
        set(gca,'Children',cc(end:-1:1));
        % Set title and axes labels
        xlabel('$\mathrm N$')
        ylabel('$\mathrm{P_f}$')
        title('IS - Convergence')
        % Add legend
        uq_legend([h1,f1], '$\mathrm{P_f}$', 'CI')
        xlim([N(1), N(end)]);
        hold off
    end
    
    %% display design point, cloud of points in 2 dimensions
    switch length(module.Internal.Input.Marginals)
        case 2
            if length(idx) > 1
                figTitle = sprintf('IS: FORM design point and failure plane, output #%d', oo);
            else
                figTitle = 'IS: FORM design point and failure plane';
            end             
            H{end+1} = uq_figure('Name',figTitle);
            % NOTE: 'hold on' command in R2014a does not cycle through
            % the color order so it must be set manually.
            ax = gca;
            colorOrder = get(ax,'ColorOrder');
            % Plot the cloud of failed and save importance sampling samples
            if module.Internal.SaveEvaluations
                USamples = Results.History(oo).U;
                LSF = Results.History(oo).G;
                a1 = uq_plot(...
                    USamples(LSF<=0,1), USamples(LSF<=0,2), 'o',...
                    'MarkerSize', 3,...
                    'MarkerFaceColor', colorOrder(1,:),...
                    'Color', colorOrder(1,:));
                hold on
                a2 = uq_plot(...
                    USamples(LSF>0,1), USamples(LSF>0,2), 'o',...
                    'MarkerSize', 3,...
                    'MarkerFaceColor', colorOrder(2,:),...
                    'Color', colorOrder(2,:));
            end
            
            % Plot the algorithm steps
            UstarValues = Results.FORM.History(oo).U;  % FORM steps
            h1 = uq_plot(UstarValues(:,1), UstarValues(:,2), 'r->');
            hold on
            
            % Highlight in black the starting point
            % and in green the ending point:
            uq_plot(UstarValues(1,1), UstarValues(1,2), '>k');
            uq_plot(UstarValues(end,1), UstarValues(end,2), '>g');
            
            % Plot the FORM limit state surface
            axis equal
            h2 = uq_plot(...
                UstarValues(end,1)+[UstarValues(end,2), -UstarValues(end,2)],...
                UstarValues(end,2)+[-UstarValues(end,1), +UstarValues(end,1)],...
                'k');
            
            % Set title and axes labels
            title('IS - FORM design point and failure plane')
            xlabel('$\mathrm u_1$')
            ylabel('$\mathrm u_2$')
            
            if module.Internal.SaveEvaluations
                uq_legend(...
                    [h1 h2 a1 a2],...
                    'FORM iterations', 'FORM limit state surface',...
                    '$\mathrm g(X)\leq 0$', '$\mathrm g(X)>0$');
            else
                uq_legend(...
                    [h1 h2],...
                    'FORM iterations', 'FORM limit state surface');
            end
    end
end

end
