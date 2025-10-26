function [xadded, idx, lf] = uq_addEDPoints(LF,K,xcandidate,gmean, MOStrategy, varargin)

% Evaluate the learning function
switch lower(func2str(LF))
    case 'uq_lf_u'
        gsigma = varargin{1} ;
        
        lf = LF(gmean,gsigma) ;
    case 'uq_lf_eff'
        gsigma = varargin{1} ;
        %         Y = varargin{2} ;
        lf = LF(gmean,gsigma) ;
        
    case 'uq_lf_cmm'
        XED = varargin{end} ;
        [lf, idx, xadded] = LF(gmean,xcandidate,XED,K) ;
        % In case of closest point. Everything is alreadyy computed in the
        % function. So just exit the algorithm
        return ;
        
    case 'uq_lf_fbr'
        gboot = varargin{1} ;
        if nargin > 6
            Xadded_idx = varargin{2} ;
        end
        lf = LF(gboot) ;
        
end

% Number of outputs
Nout = size(gmean,2) ;

if Nout > 1
    % Composite criterion - Max in all components
    switch lower(MOStrategy)
        case 'series'
            [gcomp, indcomp] = max( gmean, [], length(size(gmean)) ) ;
            gscomp = zeros(size(gmean,1),1) ;
            lfcomp = zeros(size(gmean,1),1) ;
            for oo = 1:Nout
                gscomp = gscomp + gsigma(:,oo) .* (indcomp == oo) ;
                lfcomp = lfcomp + lf(:,oo).* (indcomp == oo) ;
                
            end
            
        case 'parallel'
            [gcomp, indcomp] = min( gmean, [], length(size(gmean)) ) ;
            gscomp = zeros(size(gmean,1),1) ;
            lfcomp = zeros(size(gmean,1),1) ;
            for oo = 1:Nout
                gscomp = gscomp + gsigma(:,oo) .* (indcomp == oo) ;
                lfcomp = lfcomp + lf(:,oo).* (indcomp == oo) ;
            end
            
        case 'bestlf'
            [lfcomp, indcomp] = max(lf, [], length(size(lf))) ;
            gcomp = zeros(size(gmean,1),1) ;
            gscomp = zeros(size(gmean,1),1) ;
            for oo = 1:Nout
                gcomp = gcomp + gmean(:,oo) .* (indcomp == oo) ;
                gscomp = gscomp + gsigma(:,oo).* (indcomp == oo) ;
            end
    end
    
    gmean = gcomp ;
    gsigma = gscomp ;
    lf = lfcomp ;
    
end


if K == 1
    
    [~,idx] = max(lf) ;
    xadded = xcandidate(idx,:) ;
    
else
    % For multiple enrichment points, use K-means clustering to get the best
    % sample
    
    % Get indices of the point to keep in the margin
    switch lower(func2str(LF))
        
        case {'uq_lf_u','uq_lf_eff'}
        % When using Kriging, one should first compute the
        % First get the margin
        LSMidx = find(gmean-1.96*gsigma < 0 & gmean+1.96*gsigma > 0);
        
        case 'uq_lf_fbr'
            % Restrict to samples whose U > -0.5 
            LSMidx = find(lf > -0.5);

        otherwise
            % SVR and others 
        LSMidx = find(abs(lf)<0.5);
        if nargin > 5
            ia = ismember(LSMidx,Xadded_idx) ;
            LSMidx(ia,:) = [] ;
        end
    end
    
    % Sometimes the limit state margin is empty. Just take a random subset 
    % of the population for this iteration.
    if length(LSMidx) < K
%         warning('The limit state margin is too small or empty. A random subset of 1e4 samples is taken as candidate for enrichment.');
        LSMidx = uq_subsample((1:size(xcandidate,1))',1e4, 'random') ;
    end
    % If K larger than 2 take the best point and do weighted K-means on the
    % remaining K-1 samples
    if K > 2
        [~,idx1] = max(lf) ;
        xadded1 = xcandidate(idx1,:) ;
        % Remaining points
        [~, xcentroids] = uq_kmeans( xcandidate(LSMidx,:), K-1, 'weights', normcdf( lf(LSMidx) ).^2 );
        idx2 = knnsearch(xcandidate(LSMidx,:), xcentroids);
        idx2 = LSMidx(idx2) ;
        xadded2 = xcandidate(idx2,:) ;
        
        idx = [idx1;idx2] ;
        xadded = [xadded1;xadded2] ;
    else
    [~, xcentroids] = uq_kmeans( xcandidate(LSMidx,:), K, 'weights', normcdf( lf(LSMidx) ).^2 );
    idx = knnsearch(xcandidate(LSMidx,:), xcentroids);
    idx = LSMidx(idx) ;
    xadded = xcandidate(idx,:) ;
    end
    
end