function H = uq_sorm_display( module, idx, varargin ) 
% UQ_SORM_DISPLAY visualizes the analysis and results of SORM and FORM
% analyses
%
% See also: UQ_DISPLAY_UQ_RELIABILITY

Results = module.Results(end);

% initialize figure handle container
H = {};

% for each idx
for oo = idx

%% Display the evolution of the reliability index
if length(idx) > 1
    figTitle = sprintf('FORM: Convergence of reliability index, output #%d', oo);
else
    figTitle = 'FORM: Convergence of reliability index';
end
H{end+1} = uq_figure('Name',figTitle);
uq_plot(Results.History(oo).BetaHL,'-s')
hold on
if Results.Iterations(oo)==1
    xlim([1 2]);
else
    xlim([1 Results.Iterations(oo)]);
end
xlabel('number of iterations')
ylabel('$\mathrm{\beta_{HL}}$')
title('FORM - Convergence')
set(gca, 'xtick', unique(round(get(gca, 'xtick'))))
hold off

%% Display iterations, design point and FORM plane
switch length(module.Internal.Input.Marginals)
    case 2
        if length(idx) > 1
            figTitle = sprintf('FORM: Design point, failure plane, output #%d', oo);
        else
            figTitle = 'FORM: Design point, failure plane';
        end
        % Plot the algorithm steps
        H{end+1} = uq_figure('Name', figTitle);
        UstarValues = Results.History(oo).U; % Form steps
        h1 = uq_plot(UstarValues(:,1), UstarValues(:,2), '->');
        hold on
        
        % Highlight in black the starting point
        % and in green the ending point:
        uq_plot(UstarValues(1,1), UstarValues(1,2), '>k');
        uq_plot(UstarValues(end,1), UstarValues(end,2), '>g');
        
        % Plot the FORM limit state surface
        h2 = uq_plot(...
            UstarValues(end,1)+[UstarValues(end,2) -UstarValues(end,2)],...
            UstarValues(end,2)+[-UstarValues(end,1), +UstarValues(end,1)],...
            'k');
        % Set axis etc
        xlimits = get(gca, 'XLim');
        axis equal
        xlim(xlimits)
        title('FORM - Design point, failure plane');
        xlabel('$\mathrm u_1$');
        ylabel('$\mathrm u_2$');
        uq_legend([h1 h2], 'Iterations', 'FORM limit state surface')
    otherwise
        % visualization so far only for 2-dimensional input vectors
end

end
