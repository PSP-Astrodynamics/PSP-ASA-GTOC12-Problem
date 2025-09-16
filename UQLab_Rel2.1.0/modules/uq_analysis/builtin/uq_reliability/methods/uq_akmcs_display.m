function H = uq_akmcs_display(module,idx,varargin)
% UQ_AKMCS_DISPLAY visualizes AK-MCS analysis and its results
%
% See also: UQ_AKMCS, UQ_DISPLAY_UQ_RELIABILITY

% Retrieve the results
Results = module.Results;
MetaModel = module.Internal.AKMCS.MetaModel;
myKrig = Results.(MetaModel);

% initialize figure handle container
H = {};

%% for each output IDX
for oo = idx
    if length(idx) > 1
        figTitle = sprintf('AK-MCS: Convergence of failure probability estimate, output #%d', oo);
    else
        figTitle = 'AK-MCS: Convergence of failure probability estimate';
    end        
    %plot the convergence curve of the failure probability estimate
    H{end+1} = uq_figure('Name', figTitle);
    hold on
    ax = gca;
    uq_formatDefaultAxes(ax)
    Nstart = Results.History(oo).NInit;
    % Plot confidence interval of Pf estimate
    d = fill(...
            [Results.History(oo).NSamples'+Nstart; flipud(Results.History(oo).NSamples'+Nstart)],...
            [Results.History(oo).PfLower'; flipud(Results.History(oo).PfUpper')],...
            'g');
    set(d, 'FaceColor', [0.9 0.9 0.9])
    % Plot mean estimate of Pf
    a = uq_plot(...
        Results.History(oo).NSamples+Nstart, Results.History(oo).Pf);
    ylimits = get(gca,'ylim');
    xlimits = get(gca,'xlim');
    set(gca,'xlim', [Nstart xlimits(2)])
    c = errorbar(...
            (Results.History(oo).NSamples(end)+Nstart), Results.History(oo).Pf(end),...
                Results.CoV(oo)*norminv(1-module.Internal.Simulation.Alpha/2,0,1)*Results.History(oo).Pf(end),...
            'k',...
            'LineWidth', 2);
    uq_legend(...
        [a d c], '$\mathrm{P_f}$', '$\mathrm{P_f^+, P_f^-}$', 'CI MCS')
    % Set axes labels and titles
    xlabel('Number of samples')
    ylabel('$\mathrm{P_f}$')
    title('AK-MCS - Convergence')
    hold off

    %% for the 2-dimensional case, plot the safe and failed samples of the
    %experimental design
    if module.Internal.SaveEvaluations
        % let's handle constants
        NCidx = module.Internal.Input.nonConst;
        switch length(NCidx)
            case 2
                if length(idx) > 1
                    figTitle = sprintf('AK-MCS: Experimental design, output #%d', oo);
                else
                    figTitle = 'AK-MCS: Experimental design';
                end
                H{end+1} = uq_figure('Name',figTitle);
                ax = gca;
                % NOTE: 'hold on' command in R2014a does not cycle through
                % the color order so it must be set manually. 
                colorOrder = get(ax,'ColorOrder');
                X = Results.(MetaModel)(oo).ExpDesign.X;
                G = Results.(MetaModel)(oo).ExpDesign.Y;
                % Plot failed sample points
                a = uq_plot(X(G<=0,NCidx(1)), X(G<=0,NCidx(2)), 's',...
                        'MarkerFaceColor', colorOrder(1,:),...
                        'Color', colorOrder(1,:));
                hold on
                % Plot safe points
                b = uq_plot(X(G>0, NCidx(1)), X(G>0, NCidx(2)), '+',...
                        'MarkerFaceColor', colorOrder(2,:),...
                        'Color', colorOrder(2,:));
                % Create contour of limit state functions
                minX = min(Results.History(oo).MCSample);
                maxX = max(Results.History(oo).MCSample);
                [xx,yy] = meshgrid(...
                    linspace(minX(NCidx(1)), maxX(NCidx(1)), 200),...
                    linspace(minX(NCidx(2)), maxX(NCidx(2)), 200));
                % handle constants: we need to set the remaining variables
                % to the constant value
                XGrid = repmat(X(1,:),numel(xx),1);
                XGrid(:,NCidx) = [xx(:), yy(:)];
                zz = reshape(...
                    uq_evalModel(myKrig(oo), XGrid), size(xx));
                [~, cp] = contour(...
                    xx, yy, zz, [0 0],...
                    'Color', 'k', 'LineWidth', 2);
                hold off

                % Prepare a legend
                labels = {'$\mathrm{g(X)\leq 0}$',...
                    '$\mathrm{g(X)>0}$',...
                    '$\mathrm{g(X)=0}$'};
                pp = [a b cp];
                % Add legend (only if a point exists in each category)
                uq_legend(...
                    pp, labels([~isempty(a) ~isempty(b) ~isempty(c)]));
                % Set axes labels and title
                xlabel('$\mathrm{x_1}$')
                ylabel('$\mathrm{x_2}$')
                title('AK-MCS - Experimental design')
        end 
    end 
    
end

end
