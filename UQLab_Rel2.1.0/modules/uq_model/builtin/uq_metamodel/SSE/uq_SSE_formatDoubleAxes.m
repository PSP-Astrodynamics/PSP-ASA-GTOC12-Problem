function uq_SSE_formatDoubleAxes(ax, ref)
% Helper function for formatting double axes used in the SSE module
%
% See also: UQ_SSE_DISPLAY, UQ_SSER_DISPLAY
% beautify
    for ii = 1:length(ax)
        uq_formatDefaultAxes(ax(ii))
        xlim(ax(ii),[min(ref), max(ref)])
        set(ax(ii),'TickLabelInterpreter','latex')
        % for upper plot
        if ii == 1
            set(ax(ii),'XLabel',[],'XTickLabels',[])
        elseif ii == 2
            xlabel(ax(ii),'Refinement steps','Interpreter','latex')
            ylabel(ax(ii),'$N_{\mathcal{X}}$','Interpreter','latex')
        end
    end    
    % link axes x-limits together for zooming
    linkaxes(ax,'x')
end
