function Y = uq_SlidingWedge(X)

P = 500 ; 
H = 10 ;
al = X(:,1) ;
be = X(:,2) ;
ph = X(:,3) ;
g = X(:,4) ;

W = 0.5*H * (H * tand(90-al) - H * tand(be)) ;

R = W .* cosd(al) .* tand(ph) + P .* sind(al+be) .* tand(ph) + P.*cosd(al+be) ;
T = W .*sind(al) ;

Y = R - T ;
end