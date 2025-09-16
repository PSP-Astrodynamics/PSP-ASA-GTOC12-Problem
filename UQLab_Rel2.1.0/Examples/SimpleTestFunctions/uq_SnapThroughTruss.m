function Y = uq_SnapThroughTruss(X)
alpha_0 = 10 ;

for ii = 1:size(X,1)
P = X(ii,1) ;
E = X(ii,2) ;
S = X(ii,3) ;

Pmax = 2 * E * S * (1 - cosd(alpha_0)^(2/3))^(3/2) ;
fun = @(a) P + 2 * E * S * tand(a) .* (cosd(alpha_0) - cosd(a) ) ;

if P < Pmax
    a0 = 10 ;
else
    a0 = -10 ;
end
a = fzero(fun,a0) ;

Y(ii,:) = 5* cosd(alpha_0) * ( tand(alpha_0) - tand(a) );
end
end