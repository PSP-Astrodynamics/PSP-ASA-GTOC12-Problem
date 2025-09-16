function Y = uq_CompressiveStrenghtBar(X)

for ii = 1: size(X,1)
    
    E = X(ii,1) ; % kN/m^2
    Fy = X(ii,2) ; %kN/m^2
    A = X(ii,3) ;
    L = X(ii,4) ;
    % Slenderness
    sl = L ./(0.4993 * A.^0.6777) ;
    
    % buckling
    Cc = sqrt(2 * pi^2 * E ./ Fy) ;
    
    if sl < Cc
        Y(ii,:) = ( (1 - sl.^2 ./ (2* Cc.^2)) * Fy ) ./ ( 5/3 + 3*sl./(8*Cc) - sl.^3 ./ (8 * Cc.^3)) ;
    else
        Y(ii,:) = 12 * pi^2 * E ./ (23 * sl.^2) ;
    end
end
end