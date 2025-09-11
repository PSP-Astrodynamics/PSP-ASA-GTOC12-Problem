function [Y, Yc] = uq_manhattan(X)

for ii = 1 : size(X,1)
    
    if X(ii,1) >= 0 && X(ii,1) <= 1
       [Y(ii,:),Yc(ii,:)] = uq_checkerboard8(X(ii,:)) ; 
    elseif X(ii,1) >= -1 && X(ii,1) < 0 && X(ii,2) >= 0 && X(ii,2) <= 1
        Y(ii,:) = sin(7*X(ii,1)) .* sin(4*X(ii,2)) ;
        Yc(ii,:) = 9 ;
    elseif X(ii,1) >= -1 && X(ii,1) < 0 && X(ii,2) >= -1 && X(ii,2) < 0
        Y(ii,:) =  1 - 2/7*(2*X(ii,1)+1).^2 - (2*X(ii,2)+1).^2 ;
        Yc(ii,:) = 10 ;
    end
    
end