function [Y, Yc]=  uq_checkerboard8(X)

for ii = 1:size(X,1)
    
    if X(ii,2) >= -1 && X(ii,2) < -0.5
        if X(ii,1) >= 0 && X(ii,1) < 0.55
            Y(ii,:) = 1 ;
            Yc(ii,:) = 1 ;
        elseif X(ii,1) >= 0.5 && X(ii,1) <= 1
            Y(ii,:) = 0.1 ;
            Yc(ii,:) = 2 ;
        else
            Y(ii,:) = NaN ;
            Yc(ii,:) = NaN ;
        end
        
    elseif X(ii,2) >= -0.5 && X(ii,2) < 0
        if X(ii,1) >= 0 && X(ii,1) < 0.55
            Y(ii,:) = 0.1 ;
            Yc(ii,:) = 3 ;
        elseif X(ii,1) >= 0.5 && X(ii,1) <= 1
            Y(ii,:) = 1 ;
            Yc(ii,:) = 4 ;
        else
            Y(ii,:) = NaN ;
            Yc(ii,:) = NaN ;
        end
        
    elseif X(ii,2) >= 0 && X(ii,2) < 0.5
        
        if X(ii,1) >= 0 && X(ii,1) < 0.55
            Y(ii,:) = 1 ;
            Yc(ii,:) = 5 ;
        elseif X(ii,1) >= 0.5 && X(ii,1) <= 1
            Y(ii,:) = 0.1 ;
            Yc(ii,:) = 6 ;
        else
            Y(ii,:) = NaN ;
            Yc(ii,:) = NaN ;
        end
        
    elseif X(ii,2) >= 0.5 && X(ii,2) <= 1
        
        if X(ii,1) >= 0 && X(ii,1) < 0.55
            Y(ii,:) = 0.1 ;
            Yc(ii,:) = 7 ;
        elseif X(ii,1) >= 0.5 && X(ii,1) <= 1
            Y(ii,:) = 1 ;
            Yc(ii,:) = 8 ;
        else
            Y(ii,:) = NaN ;
            Yc(ii,:) = NaN ;
        end
        
    else
        Y(ii,:) = NaN ;
    end
    
end


end