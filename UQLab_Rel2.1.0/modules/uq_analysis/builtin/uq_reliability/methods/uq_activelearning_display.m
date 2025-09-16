function H = uq_activelearning_display(module,idx,varargin)
% UQ_ACTIVELEARNING_DISPLAY visualizes AK-MCS analysis and its results
%
% See also: UQ_AKMCS, UQ_DISPLAY_UQ_RELIABILITY

% Retrieve the results
Results = module.Results;
myMetamodel = Results.Metamodel;

% initialize figure handle container
H = {};

%% for each output IDX
for oo = idx
    if length(idx) > 1
        figTitle = sprintf('ALR: Convergence of failure probability estimate, output #%d', oo);
    else
        figTitle = 'ALR: Convergence of failure probability estimate';
    end    
    %plot the convergence curve of the failure probability estimate
    H{end+1} = uq_figure('Name',figTitle); 
    hold on
    ax = gca;
    uq_formatDefaultAxes(ax)
    Nstart = Results.History(oo).NInit;
        
    % Plot confidence interval of Pf estimate w.r.t. surrogate uncertainty
    if isfield(Results.History(oo), 'PfLower')
        d = fill([Results.History(oo).NCurrent; flipud(Results.History(oo).NCurrent)],...
            [Results.History(oo).PfLower; flipud(Results.History(oo).PfUpper)], 'g');
        set(d, 'FaceColor', [0.9 0.9 0.9])
    end
        set(gca,'Yscale','log') ;
        
    % Plot Pf history
    a = uq_plot(Results.History(oo).NCurrent, Results.History(oo).Pf);
    xlimits = get(gca,'xlim');
    set(gca,'xlim', [Nstart xlimits(2)])
    % Plot confidence 
    if isfield(Results, 'CoV')
        c = errorbar((Results.History(oo).NCurrent(end)), Results.History(oo).Pf(end), ...
            Results.CoV(oo) * norminv(1-module.Internal.Simulation.Alpha/2,0,1) * Results.History(oo).Pf(end), ...
            'k', 'LineWidth', 2);
    end
    % Legend
    if isfield(Results.History(oo),'PfLower') && ~isfield(Results, 'CoV')
        l = uq_legend([a,d], '$\mathrm{P_f}$', '$\mathrm{P_f^+, P_f^-}$');
    elseif ~isfield(Results.History(oo),'PfLower') && isfield(Results, 'CoV')
        l = uq_legend([a,c], '$\mathrm{P_f}$', 'CI SIM');
    elseif ~isfield(Results.History(oo),'PfLower') && ~isfield(Results, 'CoV')
        l = uq_legend(a, '$\mathrm{P_f}$');
    else
        l = uq_legend([a,d,c], '$\mathrm{P_f}$', '$\mathrm{P_f^+, P_f^-}$', 'CI SIM');
    end

    % Set axes labels and titles
    xlabel('Number of samples')
    ylabel('$\mathrm{P_f}$')
    title('Active learning - Convergence')

    %% for the 2-dimensional case, plot the safe and failed samples of the
    %experimental design
    if module.Internal.SaveEvaluations
        switch length(module.Internal.Input.nonConst)
            case 2
                if length(idx) > 1
                    figTitle = sprintf('ALR - %s+%s, output #%d',myMetamodel.MetaType, Results.Reliability.Internal.Method, oo);
                else
                    figTitle = sprintf('ALR - %s+%s',myMetamodel.MetaType, Results.Reliability.Internal.Method);
                end
                H{end+1} = uq_figure('Name', figTitle);
                ax = gca;
                % NOTE: 'hold on' command in R2014a does not cycle through
                % the color order so it must be set manually. 
                colorOrder = get(ax,'ColorOrder');
                
                X = myMetamodel.ExpDesign.X;
                G = myMetamodel.ExpDesign.Y;
                % Plot failed sample points
                a = uq_plot(X(G(:,oo)<=0,1), X(G(:,oo)<=0,2), 's',...
                        'MarkerFaceColor', colorOrder(1,:),...
                        'Color', colorOrder(1,:));
                hold on
                % Plot safe points
                b = uq_plot(X(G(:,oo)>0, 1), X(G(:,oo)>0, 2), '+',...
                        'MarkerFaceColor', colorOrder(2,:),...
                        'Color', colorOrder(2,:));
                
                
                minX = min(Results.History(oo).ReliabilitySample);
                maxX = max(Results.History(oo).ReliabilitySample);
                [xx, yy] = meshgrid(linspace(minX(1), maxX(1), 200), ...
                    linspace(minX(2), maxX(2), 200));
                zz = uq_evalModel(myMetamodel, [xx(:), yy(:)]) ;
                zz = reshape( zz(:,oo),size(xx));
                [~, cp] = contour(xx,yy,zz, [0 0], 'k', 'linewidth', 2);
                
                % Format the figure
                labels = {'$\mathrm{g(X)\leq 0}$', '$\mathrm{g(X)>0}$', '$\mathrm{g(X)=0}$'};
                pp = [a,b,cp];
                l = uq_legend(pp,labels([~isempty(a) ~isempty(b) ~isempty(c)]) );
                set(l, 'interpreter', 'latex')
                uq_setInterpreters(gca)
                box on
                xlabel('$\mathrm{x_1}$')
                ylabel('$\mathrm{x_2}$')
                title(figTitle)
        end 
    end 
    
end