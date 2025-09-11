function [xadded, idx, lf] = uq_enrichED(LF,K,xcandidate,MOStrategy, gmean, varargin)

% Evaluate the learning function
switch lower(func2str(LF))
    case {'uq_lf_u'}
        gsigma = varargin{1} ;
        
        lf = LF(gmean,gsigma) ;
    case 'uq_lf_eff'
        gsigma = varargin{1} ;
        Y = varargin{2} ;
        lf = LF(gmean,gsigma) ;
        
    case 'uq_lf_cmm'
        XED = varargin{1} ;
        [lf, idx, xadded] = LF(gmean,xcandidate,XED,K) ;
        % In case of closest point. Everything is alreadyy computed in the
        % function. So just exit the algorithm
        return ;
        
    case 'uq_lf_fbr'
        gboot = varargin{1} ;
        Xadded_idx = varargin{2} ;

        lf = LF(gboot) ;
        
end

% Number of outputs
Nout = size(gmean,2) ;



% Get the composite criterion
if Nout > 1
    if strcmpi(func2str(LF), 'uq_lf_eff')
        % Normalize the criterion
        lf = lf ./ std(Y) ;
    end
    switch lower(MOStrategy)
        case 'max'
            % Composite criterion - Max in all components
            [lf, indcomp] = max(lf, [], length(size(lf))) ;
        case 'mean' 
            % Best of mean value
            lf = mean(lf,2) ;
        case 'oat'
           for jj = 1 : Nout
               
           end
    end
    
    if strcmpi(MOStrategy,'max')
        % Now get the prediction and std corresponding to the constraint where
        % the maximum criterion occured when using EFF or U
        if K > 1 && any( strcmpi(func2str(LF),{'uq_lf_u','uq_lf_eff'} ) )
            gmtmp = zeros(size(gmean,1),1) ; gstmp = zeros(size(gmean,1),1) ;
            for oo = 1:Nout
                gmtmp = gmtmp + gmean(:,oo) .* (indcomp == oo) ;
                gstmp = gstmp + gsigma(:,oo) .* (indcomp == oo) ;
            end
            gmean = gmtmp ;
            gsigma = gstmp ;
        end
    end
end


if strcmpi(MOStrategy, 'oat')
    for jj = 1:Nout
        [~,idx(jj)] = max(lf(:,jj)) ;
        xadded = xcandidate(idx,:) ;

    end
else
    
    if K == 1
        
        [~,idx] = max(lf) ;
        xadded = xcandidate(idx,:) ;
        
    else
        % For multiple enrichment points, use K-means clustering to get the best
        % sample
        
        % Get indices of the point to keep in the margin
        if strcmpi(MOStrategy,'max')
        if any( strcmpi(func2str(LF),{'uq_lf_u','uq_lf_eff'} ) )
            % When using Kriging, one should first compute the
            % First get the margin
            LSMidx = find(gmean-1.96*gsigma < 0 & gmean+1.96*gsigma > 0);
        else
            LSMidx = find(abs(lf)<0.5);
            ia = ismember(LSMidx,Xadded_idx) ;
            LSMidx(ia,:) = [] ;
        end
        else
            
        if any( strcmpi(func2str(LF),{'uq_lf_u','uq_lf_eff'} ) )
            % When using Kriging, one should first compute the
            % First get the margin
            tmpidx = cell(1,Nout) ;
            for jj = 1:Nout
                 tmpidx{jj} = find( gmean(:,jj)-1.96*gsigma(:,jj) < 0 ...
                     & gmean(:,jj)+1.96*gsigma(:,jj) > 0 );
            end
            LSMidx = tmpidx{1} ;
            for jj = 2:Nout
                ia = ~ismember(tmpidx{jj},LSMidx) ;
                LSMidx = [LSMidx ; tmpidx{jj}(ia)] ;
            end
        else
            tmpidx = cell(1,Nout) ;
            for jj = 1:Nout
                tmpidx{jj} = find(abs(lf)>0.5);
            end
            LSMidx = tmpidx{1} ;
            for jj = 2:Nout
                ia = ~ismember(tmpidx{jj},LSMidx) ;
                LSMidx = [LSMidx ; tmpidx{jj}(ia)] ;
            end
            
            ia = ~ismember(LSMidx,Xadded_idx) ;
            LSMidx(ia,:) = [] ;
        end
        end
        % Sometimes the limit state margin is empty. Just take the entire
        % population for this iteration.
        if length(LSMidx) < K
            warning('The limit state margin is too small or empty. The entire sample set is taken as candidate for enrichment.');
            LSMidx = (1:size(xcandidate,1))';
        end
        
        [~, xcentroids] = uq_kmeans( xcandidate(LSMidx,:), K, 'weights', normcdf( lf(LSMidx) ).^2 );
        idx = knnsearch(xcandidate(LSMidx,:), xcentroids);
        idx = LSMidx(idx) ;
        xadded = xcandidate(idx,:) ;
        
    end
end
end