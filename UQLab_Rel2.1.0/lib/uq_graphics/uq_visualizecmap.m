function uq_visualizecmap(cmap)
%UQ_VISUALIZECMAP produces a simple visualization of the provided colormap
%   Next to the uninteresting rgb-plot with the color-values a colorbar of
%   the colormap is displayed.

uq_figure;
colormap(cmap)
colorbar('Ticks',[])
axis('off')
end

