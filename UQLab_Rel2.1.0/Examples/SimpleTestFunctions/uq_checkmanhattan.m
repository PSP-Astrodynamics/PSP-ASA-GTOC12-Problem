function Y = uq_checkmanhattan(X,class)

for ii = 1:size(X,1)
    switch class{ii}
        case '1'
            Y(ii,:) = 1 ;
        case '2'
            Y(ii,:) = 0 ;
        case '3'
            Y(ii,:) = 0 ;
            
        case '4'
            Y(ii,:) = 1 ;
            
        case '5'
            Y(ii,:) = 1 ;
            
        case '6'
            Y(ii,:) = 0 ;
            
        case '7'
            Y(ii,:) = 0 ;
            
        case '8'
            Y(ii,:) = 1 ;
            
            
        case '9'
            Y(ii,:) = sin(7*X(ii,1)) .* sin(4*X(ii,2)) ;
            
        case '10'
            Y(ii,:) = 0.5 + 2/7*(2*X(ii,1)+1).^2 + (2*X(ii,2)+1).^2 ;
            
    end
    
end

end