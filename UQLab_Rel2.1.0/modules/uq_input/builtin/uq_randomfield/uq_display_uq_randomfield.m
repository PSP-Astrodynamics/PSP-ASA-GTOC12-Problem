function H = uq_display_uq_randomfield(  module, varargin )
% UQ_DISPLAY_UQ_RANDOMFIELD graphically displays properties of a random
% field together with some realizations. By default, it generates some 
% realizations of the random field for 1- and 2-D problems, the error
% variance and the cumulated energy ratio
%
%    H = UQ_DISPLAY_UQ_RANDOMFIELD(...) returns an array of figure handles.
%
% See also: UQ_PRINT_UQ_RANDOMFIELD, UQ_DISPLAY_UQ_DEFAULT_INPUT,
%           UQ_DISPLAY_UQ_INVERSION,


%% 1. Realizations and error variance
% Number of realizations to display for 1-D problems
N = 5 ;

% Obtain the trajectories that will be plotted
Y = uq_getSample(module,N, 'MC');

% Produce the plots
H = {} ;

switch module.Internal.Runtime.Dimension
    
    % One dimensional random fields
    case   1
        
        % Plot the trajectories
        H{1} = uq_figure('name', sprintf('Input Object: %s - Trajectories' , module.Name)) ;
        % Sort the mesh (just in case it is not regular)
        [sortedX, idx] = sort(module.Internal.Mesh);
        % Plot the trajectories and label the figure
        uq_plot (sortedX, Y(:,idx)) ;
        xlabel ('$x$' ,'Interpreter','latex','fontsize',16);
        ylabel('$H(x)$','Interpreter','latex','fontsize',16);
        title('Random field trajectories');
        
        % If there are observations, plot them
        if ~isempty(module.Internal.RFData)
            % Observation marker symbol
            marker_symbol = 'ok';
            hold on ;
            h = uq_plot (module.Internal.RFData.X, module.Internal.RFData.Y, marker_symbol, ...
                'MarkerSize',8);
            legend(h,'Observations');
        end
        
        % Plot the variance
        H{2} = uq_figure('name', sprintf('Input Object: %s - Variance' , module.Name)) ;
        uq_plot (sortedX, module.RF.VarError(:,idx));
        xlabel ('$x$','Interpreter','latex','fontsize',16);
        ylabel('$\textrm{Var}[H(x) - \hat{H}(x)]$','Interpreter','latex','fontsize',16);
        title('Error variance') ;
        
    case 2
        
        % Perform Delaunay triangulation (just in case the mesh is not a
        % regular grid)
        tri=delaunay(module.Internal.Mesh(:,1),module.Internal.Mesh(:,2));
        
        % Plot one trajectory
        H{1} = uq_figure('name', sprintf('Input Object: %s - Trajectory' , module.Name)) ;
        trisurf(tri,module.Internal.Mesh(:,1),module.Internal.Mesh(:,2),Y(1,:));
        shading interp ;
        colormap parula ;
        view(0,90) ;
        xlabel ('$x_1$','Interpreter','latex','fontsize',16) ;
        ylabel('$x_2$','Interpreter','latex','fontsize',16) ;
        set(gca, 'ticklabelInterpreter','latex', 'FontSize',18);
        title('Random field trajectory','fontweight','normal','Interpreter','latex','fontsize',18);
        colorbar ;
        
        % If there are observations, plot them
        if ~isempty(module.Internal.RFData)
            % marker symbol for the observaations
            marker_symbol = 'ow';
            hold on ;
            h = plot3(module.Internal.RFData.X(:,1), module.Internal.RFData.X(:,2), ...
                module.Internal.RFData.Y, marker_symbol, 'MarkerSize',8,'MarkerfaceColor','b');
            legend(h,'Observations');
        end
        
        % Plot the error variance
        H{2} = uq_figure('name', sprintf('Input Object: %s - Variance' , module.Name)) ;
        trisurf(tri,module.Internal.Mesh(:,1),module.Internal.Mesh(:,2),module.RF.VarError(:,1:size(module.Internal.Mesh,1))) ;
        shading interp ;
        view(0,90) ;
        colormap parula ;
        xlabel ('$x_1$','Interpreter','latex','fontsize',16) ;
        ylabel('$x_2$','Interpreter','latex','fontsize',16) ;
        set(gca, 'ticklabelInterpreter','latex', 'FontSize',18);
        title('Error variance','fontweight','normal','Interpreter','latex','fontsize',18);
        colorbar ;
end

%% 2. cumulated eigenvalues
%
% cumulated_eigs = cumsum(module.RF.Eigs)/sum(module.Internal.Runtime.EigsFull) ;
% Note that the trace of a matrix is the sum of all its eigenvalues.
% Therefore TraceCorr = sum_{i=1}^{n} \lambda_i. This allows us to have the
% total variance even without computing the eigenvalues.
if isfield(module.Internal.Runtime,'TraceCorr')
cumulated_eigs = cumsum(module.RF.Eigs)/module.Internal.Runtime.TraceCorr ;
else
    if isfield(module.Internal.Runtime,'EigsFull')
        cumulated_eigs = cumsum(module.RF.Eigs)/sum(module.Internal.Runtime.EigsFull) ;
    else
        cumulated_eigs = cumsum(module.RF.Eigs) ;
    end
end
H{3} = uq_figure('name', sprintf('Input Object: %s - Eigenvalues' , module.Name)) ;
uq_plot(1:length(module.RF.Eigs),cumulated_eigs, 'o');
xlabel ('$k$','Interpreter','latex','fontsize',16) ;
ylabel('$\sum_{i=1}^k \lambda_i/\sum_{i=1}^n \lambda_i$','Interpreter','latex','fontsize',16) ;
title('Energy ratio','fontweight','normal','Interpreter','latex','fontsize',18);

end