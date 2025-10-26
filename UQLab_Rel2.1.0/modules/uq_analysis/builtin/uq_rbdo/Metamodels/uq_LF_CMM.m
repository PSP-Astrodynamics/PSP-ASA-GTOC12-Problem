function [lf, idx, xadded] = uq_LF_CMM(gmean,xcandidate,XED, K)
% UQ_LF_CMM computes an adpatation of the constrained min-max criterion
% developed in the following reference:
%
%
% Get the closest points to the LSF
Nout = size(gmean,2);
% Select the 1% closest points (should this be an option?)
Nselect = 0.01 * size(xcandidate,1) ;
xadded = [] ;



for j = 1: Nout
    % Sort the points according to their distance to the limit-state surface
    [sortedXG, idXG] = sortrows([xcandidate,gmean(:,j)],size(xcandidate,2)+1, 'ascend', ...
        'ComparisonMethod','abs') ;
    xselect = sortedXG(1:Nselect,1:size(xcandidate,2)) ;
    
    
    for kk = 1:1
        % Get the nearest neighbour of the training points for each of the points
        % in the selected enrichment candidates
        [idx, dist_to_XED] = knnsearch([XED;xadded],xselect) ;
        idx = idXG(idx) ;
        
        % Learning function
        [lf, indlf] = max(dist_to_XED,[],1);
        indlf
        % index of the added point
        idx = idXG(indlf) ;
        xnext = xcandidate(idx,:);
        xadded = [xadded; xnext] ;
        
    end
    
end
end

