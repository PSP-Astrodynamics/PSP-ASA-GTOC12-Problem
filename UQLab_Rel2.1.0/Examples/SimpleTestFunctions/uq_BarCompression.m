function Y = uq_BarCompression(X)

Y = ones(size(X,1),1) ;
for ii = 1:size(X,1)
L = X(ii,1) ;
A = X(ii,2) ;
E = X(ii,3) ;
Fy = X(ii,4) ;

l = L / (0.4993 * A^0.6777) ;
Cc = sqrt(2*pi^2 * E / Fy) ;

if l < Cc
    Y(ii,1) = ((1 - l^2 / (2*Cc^2))*Fy) / (5/3 + 3*l /(8*Cc) - l^3 / (8*Cc^3)) ; 
    Y(ii,2) = -1 ;
else
   Y(ii,1) = 12 * pi^2 * E / (23*l^2) ; 
   Y(ii,2) = 1 ;

end
end

end