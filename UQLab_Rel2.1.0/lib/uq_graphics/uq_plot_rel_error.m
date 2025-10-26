function rel_error = uq_plot_rel_error(v1, v2, nbins)
% simple pretty plot of the relative error between two arrays that supposedly represent
% the same quantity

if ~exist('nbins', 'var')
    nbins = 1000;
end

rel_error = (v1 - v2)./(v1 + v2);
rel_error(isinf(rel_error)) = [];
rel_error(isnan(rel_error)) = [];

m = mean(rel_error,1);
s = std(rel_error, 0,1);

% one plot per component
for ii = 1:length(s)
    xx(ii,:) = linspace(m(ii)-2*s(ii), m(ii)+2*s(ii), nbins);
    hh(ii,:) = histc(rel_error(ii,:),xx(ii,:));
    figure; b(ii) = bar(xx(ii,:), hh(ii,:), 'histc');
%     set(b(ii), 'edgecolor', 'k', 'facecolor', 'k');
    
    set(gca, 'fontsize', 24);
    xlabel('Relative error');
    ylabel('Count');
        
    figure;
    v1norm = v1(:,ii)/max(abs(v1(:,ii)));
    v2norm = v2(:,ii)/max(abs(v1(:,ii)));
    
    plot(transpose(v1norm), transpose(v2norm), 'ob');
    limits = [min(min(v1norm), min(v2norm)) max(max(v1norm), max(v2norm))];
    axis equal;
    xlim(limits);
    ylim(limits);
    set(gca, 'fontsize', 24);
    xlabel('Full Model');
    ylabel('Metamodel');
    title(sprintf('Vector comparison, component #%d', ii))
end


