function varargout = uq_display_uq_rbdo(module, outidx, varargin)
% VARARGOUT= UQ_DISPLAY_UQ_RBDO(MODULE,OUTIDX,VARARGIN) displays the
%     main results of the reliability analysis MODULE
%
% See also: UQ_MC_DISPLAY, UQ_SORM_DISPLAY, UQ_IMPORTANCESAMPLING_DISPLAY,
% UQ_SUBSETSIM_DISPLAY, UQ_AKMCS_DISPLAY



% Retrieve the results history
results = module.Results.History ;
% Get number of iteration

if isfield(results,'GlobalOptim')
    iterGO = length(results.GlobalOptim.Score) ;
    iterLO = length(results.LocalOptim.Score) ;
else
    iter = length(results.Score) ;
end
% Number of outputs
Nout = size(results.Constraints,2) ;
% If the user does not specify one specific output, the constraint is plot
% for all of them
if ~exist('outidx', 'var')
    outidx = 1:Nout;
end
% X-label
if any( strcmpi(module.Internal.Method, {'sora','decoupled'}) )
    x_label = 'Cycle $\#$' ;
else
    x_label = 'Iteration $\#$' ;
end
% Y-label
switch lower(module.Internal.Method)
    case {'ria'}
        constraint_label = '$\beta$';
    case {'sora', 'sla', 'decoupled', 'mono-level', 'deterministic', 'pma'}
        constraint_label = '$G$';
        
    case 'two-level'
        constraint_label = '$\beta$';
        switch lower(module.Internal.Reliability.Method)
            case {'mcs','is','subset','form','sorm'}
                switch lower(module.Internal.Optim.ConstraintType)
                    case 'pf'
                        constraint_label = '$P_f$';
                    case 'beta'
                        constraint_label = '$\beta$';
                end
            case 'qmc'
                constraint_label = '$q_\alpha$' ;
            case 'iform'
                constraint_label = '$G$' ;
        end
        
    case 'qmc'
        constraint_label = '$q_\alpha$';
        
end

%% Create the plots
% initialize figure handle container
H = {};

%% 1. Plot the convergence curve of the cost function
if isfield(results,'GlobalOptim')
    % Plot first global optim results
    H{end+1} = uq_figure('Name', 'RBDO: Convergence of the cost - Global');
    ax = gca;
    uq_formatDefaultAxes(ax)
    hold on
    if strcmpi(module.Internal.Optim.Method,{'hccmaes'})
        uq_plot(module.Results.output.NewBestPoint - 1, ...
            results.GlobalOptim.Score(module.Results.output.NewBestPoint), ...
            'o-', 'MarkerSize',6);
    else
        uq_plot(0:iterGO-1, results.GlobalOptim.Score, 'o-', 'MarkerSize',6);
    end
    
    xlabel(x_label)
    ylabel('Cost')
    xlim([0 - 0.05*(iterGO - 1), iterGO - 1 + 0.05*(iterGO - 1)])
    title('RBDO - Convergence of the cost - Global')
    hold off
    
    % Plot first local optim results
    H{end+1} = uq_figure('Name', 'RBDO: Convergence of the cost - Local');
    uq_plot(0:iterLO-1, results.LocalOptim.Score, 'o-', 'MarkerSize', 6)
    
    xlabel(x_label)
    ylabel('Cost')
    xlim([0 - 0.05*(iterLO - 1), iterLO - 1 + 0.05*(iterLO - 1)])
    
    title('RBDO - Convergence of the cost - Local')
    
else
    H{end+1} = uq_figure('Name', 'RBDO: Convergence of the cost');
    ax = gca;
    uq_formatDefaultAxes(ax)
    hold on
    if any(strcmpi(module.Internal.Optim.Method,{'ccmaes','intccmaes'}))
        uq_plot(module.Results.output.NewBestPoint - 1, ...
            results.Score(module.Results.output.NewBestPoint), ...
            'o-', 'MarkerSize',6)
    else
        if strcmpi(module.Internal.Method,'sora')
            uq_plot(1:iter, results.Score, 'o-', 'MarkerSize', 6) ;
        else
            uq_plot(0:iter-1, results.Score, 'o-', 'MarkerSize', 6) ;
        end
    end
    
    xlabel(x_label)
    ylabel('Cost')
    if strcmpi(module.Internal.Method,'sora')
        xlim([1 - 0.05*(iter - 1), iter + 0.05*(iter - 1)])
    else
        xlim([0 - 0.05*(iter - 1), iter - 1 + 0.05*(iter - 1)])
    end
    title('RBDO - Convergence of the cost')
    hold off
end


%% 2. Plot the convergence of the constraint
if isfield(results,'GlobalOptim')
    % Plot first global optim results
    % There is no plot when using GA
    if ~strcmpi(module.Internal.Optim.Method,{'hga'})
        H{end+1} = uq_figure('Name', 'RBDO: Convergence of the Constraints - Global');
        ax = gca;
        uq_formatDefaultAxes(ax)
        hold on
        
        constraint = results.Constraints(1:iterGO,:);
        % NOTE: 'hold on' command in R2014a does not cycle through
        % the color order so it must be set manually.
        colorOrder = get(ax,'ColorOrder');
        ii = 1;
        for oo = outidx
            if any( strcmpi(module.Internal.Optim.Method,{'hccmaes'}) )
                h2(oo,:) = uq_plot(module.Results.output.NewBestPoint - 1, ...
                    constraint(module.Results.output.NewBestPoint,oo), ...
                    's:','MarkerSize',6);
            else
                h2(oo,:) = uq_plot(0:length(constraint)-1, constraint(:,oo), 's:','MarkerSize',6);
            end
            % Set color manually for compatibility
            colIdx = max(mod(ii, size(colorOrder,1)), 1);
            set(...
                h2(oo),...
                'MarkerFaceColor', colorOrder(colIdx,:),...
                'Color', colorOrder(colIdx,:))
            ii = ii+1;
            
            constraint_legend{oo} = sprintf('Constraint $%d$',oo) ;
        end
        uq_legend(h2, constraint_legend)
        
        xlabel(x_label);
        ylabel(constraint_label)
        xlim([0 - 0.05*(iterGO - 1), iterGO - 1 + 0.05*(iterGO - 1)])
        
        title('RBDO - Convergence of the Constraints - Global')
        hold off
    end
    
    constraint = results.Constraints( iterGO+1 : iterGO+iterLO,: );
    H{end+1} = uq_figure('Name', 'RBDO: Convergence of the Constraints - Local');
    ax = gca;
    uq_formatDefaultAxes(ax)
    hold on
    
    % NOTE: 'hold on' command in R2014a does not cycle through
    % the color order so it must be set manually.
    colorOrder = get(ax,'ColorOrder');
    ii = 1;
    for oo = outidx
        h2(oo,:) = uq_plot(0:length(constraint)-1, constraint(:,oo), 's:','MarkerSize',6);
        constraint_legend{oo} = sprintf('Constraint $%d$',oo);
        % Set color manually for compatibility
        colIdx = max(mod(ii, size(colorOrder,1)), 1);
        set(...
            h2(oo),...
            'MarkerFaceColor', colorOrder(colIdx,:),...
            'Color', colorOrder(colIdx,:))
        ii = ii+1;
        
    end
    uq_legend(h2, constraint_legend)
    
    xlabel(x_label)
    ylabel(constraint_label)
    xlim([0 - 0.05*(iterLO - 1), iterLO - 1 + 0.05*(iterLO - 1)])
    
    title('RBDO - Convergence of the Constraints - Local')
    hold off
else
    if ~strcmpi(module.Internal.Optim.Method,{'ga'})
        H{end+1} = uq_figure('Name', 'RBDO: Convergence of the Constraints');
        ax = gca;
        uq_formatDefaultAxes(ax)
        hold on
        
        constraint = results.Constraints;
        % NOTE: 'hold on' command in R2014a does not cycle through
        % the color order so it must be set manually.
        colorOrder = get(ax,'ColorOrder');
        ii = 1;
        for oo = outidx
            if any( strcmpi(module.Internal.Optim.Method,{'ccmaes','intccmaes'}) )
                h2(oo,:) = uq_plot(module.Results.output.NewBestPoint - 1, ...
                    constraint(module.Results.output.NewBestPoint,oo), ...
                    's:','MarkerSize',6,'LineWidth', 2);
            else
                if strcmpi(module.Internal.Method, 'sora')
                    h2(oo,:) = uq_plot(1:length(constraint), constraint(:,oo), 's:','MarkerSize',6);
                else
                    h2(oo,:) = uq_plot(0:length(constraint)-1, constraint(:,oo), 's:','MarkerSize',6);
                end
            end
            % Set color for compatibility
            colIdx = max(mod(ii, size(colorOrder,1)), 1);
            set(...
                h2(oo),...
                'MarkerFaceColor', colorOrder(colIdx,:),...
                'Color', colorOrder(colIdx,:))
            ii = ii + 1;
            
            constraint_legend{oo} = sprintf('Constraint $%d$',oo) ;
        end
        uq_legend(h2, constraint_legend)
        
        xlabel(x_label)
        ylabel(constraint_label)
        if strcmpi(module.Internal.Method,'sora')
            xlim([1 - 0.05*(iter - 1), iter + 0.05*(iter - 1)])
        else
            xlim([0 - 0.05*(iter - 1), iter - 1 + 0.05*(iter - 1)])
        end
        title('RBDO - Convergence of the Constraints')
        hold off
    end
end

%% 3. Optimal design
M_d = module.Internal.Runtime.M_d ;
if  M_d > 2
    
    lb = module.Internal.Optim.Bounds(1,:) ;
    ub = module.Internal.Optim.Bounds(2,:) ;
    H{end+1} = uq_figure('Name', 'RBDO: Relative position of optimal solution');
    ax = gca;
    uq_formatDefaultAxes(ax)
    hold on
    
    t = (0:1/M_d:1)'*2*pi;
    x = cos(t);
    y = sin(t);
    %     uq_plot(x,y, 'color',[176 23 31]/255)
    uq_plot(x,y)
    
    uq_plot(0.75*x,0.75*y, ':k','linewidth',1)
    uq_plot(0.5*x,0.5*y,':k','linewidth',1)
    uq_plot(0.25*x,0.25*y,':k','linewidth',1)
    
    hold on
    for ii = 1: length(x)-1
        aa = [0 0; x(ii), y(ii)] ;
        uq_plot(aa(:,1),aa(:,2),'--k','linewidth',1) ;
    end
    coef = (module.Results.Xstar - lb) ./ (ub - lb) ;
    coef = [coef coef(1)] ;
    %     uq_plot(x.*(coef)', y.*(coef)','color',[25 25 112]/255,'linewidth',2) ;
    uq_plot(x.*(coef)', y.*(coef)') ;
    
    %     uq_plot(x.*(coef)', y.*(coef)','dk','MarkerSize',8,'MarkerfaceColor',[0 139 69]/255)
    c = get(gca,'colororder') ;
    uq_plot(x.*(coef)', y.*(coef)','dk','MarkerSize',10, 'MarkerFaceColor',c(5,:));
    
    VarNames = {} ;
    for ii = 1:M_d
        VarNames{ii} = module.Internal.Input.DesVar(ii).Name ;
    end
    posx = 1.1*x ;
    posy = 1.1*y ;
    for fn = 1:length(x)-1
        text(posx(fn), posy(fn), VarNames{fn}, ...
            'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center', ...
            'Color', 'k', 'FontSize', 16, 'FontWeight', 'bold','Interpreter','latex');
    end
    minx = min(posx) ; maxx = max(posx) ;
    miny = min(posy) ; maxy = max(posy) ;
    % Center axis
    axis([minx - 0.1*(maxx-minx) , maxx + 0.1*(maxx-minx) , miny - 0.1*(maxy-miny) , maxy + 0.1*(maxy-miny)])
    % Remove ticks latbels
    set(gca,'YTickLabel',[]);
    set(gca,'XTickLabel',[]);
    %     xlim([1.5*minx, 1.5*maxx]);
    %     ylim([1.5*miny, 1.5*maxy]);
    title('RBDO - Relative position of optimal solution')
    hold off
end

varargout{1} = H;
end