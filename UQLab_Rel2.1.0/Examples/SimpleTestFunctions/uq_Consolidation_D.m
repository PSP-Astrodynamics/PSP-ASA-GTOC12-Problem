function Y = uq_Consolidation_D(X)
gw = 9.8 % kN/m^2
S_a = 0.05; % m

for ii = 1:size(X,1)

q = X(ii,1) ;     
H = X(ii,2) ;
ec = X(ii,3) ;
es = X(ii,4) ;
Gc = X(ii,5) ;
Gs = X(ii,6) ;
OCR = X(ii,7) ;
Cc = X(ii,8) 
al = X(ii,9) ;

Cr = 2*al * Cc ;
gss = gw * (Gs + es)/(1+es) ;
gs = gw * (Gs + 0.2*es)/(1+es) ;
gcs = gw *(Gs +ec)/(1+ec) ;


S0 = 0.5 * gs + 1 * (gss - gw) + H/2 * (gcs - gw);
S = S0 + q ;
Sp = OCR * S0 ;



if S >= Sp
    Y(ii,1) = S_a - H/(1+ec) * (Cr * log10(Sp/S0) + Cc * log10(S/Sp) ) ;
    Y(ii,2) = -1 ;
else
    Y(ii,1) = S_a - (H*Cr*log10(S/S0))/(1+ec) ;
    Y(ii,2) = 1 ;
end
end
end