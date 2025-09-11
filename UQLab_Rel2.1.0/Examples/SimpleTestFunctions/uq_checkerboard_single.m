function Y=  uq_checkerboard_single(X)

for ii = 1:size(X,1)
    
    if X(ii,2) >= -1 && X(ii,2) < -0.5
        if X(ii,1) >= 0 && X(ii,1) < 0.25
            Y(ii,:) = 0 ;
        elseif X(ii,1) >= 0.25 && X(ii,1) < 0.5
            Y(ii,:) = 0 ;
        elseif X(ii,1) >= 0.5 && X(ii,1) < 0.75
            Y(ii,:) = 0 ;
            
        elseif X(ii,1) >= 0.75 && X(ii,1) <= 1
            Y(ii,:) = 0 ;
        else
            Y(ii,:) = NaN ;
        end
        
    elseif X(ii,2) >= -0.5 && X(ii,2) < 0
        if X(ii,1) >= 0 && X(ii,1) < 0.25
            Y(ii,:) = 0 ;
        elseif X(ii,1) >= 0.25 && X(ii,1) < 0.5
            Y(ii,:) = 0 ;
        elseif X(ii,1) >= 0.5 && X(ii,1) < 0.75
            Y(ii,:) = 0 ;
            
        elseif X(ii,1) >= 0.75 && X(ii,1) <= 1
            Y(ii,:) = 0 ;
        else
            Y(ii,:) = NaN ;
        end
        
    elseif X(ii,2) >= 0 && X(ii,2) < 0.5
        
        if X(ii,1) >= 0 && X(ii,1) < 0.25
            Y(ii,:) = 0 ;
        elseif X(ii,1) >= 0.25 && X(ii,1) < 0.5
            Y(ii,:) = 0 ;
        elseif X(ii,1) >= 0.5 && X(ii,1) < 0.75
            Y(ii,:) = 0 ;
            
        elseif X(ii,1) >= 0.75 && X(ii,1) <= 1
            Y(ii,:) = 0 ;
        else
            Y(ii,:) = NaN ;
        end
        
    elseif X(ii,2) >= 0.5 && X(ii,2) <= 1
        
        if X(ii,1) >= 0 && X(ii,1) < 0.25
            Y(ii,:) = 0 ;
        elseif X(ii,1) >= 0.25 && X(ii,1) < 0.5
            Y(ii,:) = 0 ;
        elseif X(ii,1) >= 0.5 && X(ii,1) < 0.75
            Y(ii,:) = 1 ;
            
        elseif X(ii,1) >= 0.75 && X(ii,1) <= 1
            Y(ii,:) = 0 ;
        else
            Y(ii,:) = NaN ;
        end
        
    else
        Y(ii,:) = NaN ;
    end
    
end


end