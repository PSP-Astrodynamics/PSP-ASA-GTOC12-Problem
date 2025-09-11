function [dlhdlam1,dlhdlam2,dlhdlam3,dlhdlam4,...
    d2lhdlam11,d2lhdlam12,d2lhdlam13,d2lhdlam14,d2lhdlam22,d2lhdlam23,d2lhdlam24,...
    d2lhdlam33,d2lhdlam34,d2lhdlam44] = uq_GLD_dlhdlam(lam1,lam2,lam3,lam4,U,inv)
if nargin == 5
    inv = false;
end
if inv
    U3=1-U;
    U4=U;
else
    U3 = U;
    U4 = 1-U;
end
D = U3.^(lam3-1) + U4.^(lam4-1);
dUdlam1 = -1*lam2./D;
dUdlam2 = ( ((U3.^lam3-1)./lam3) - (U4.^lam4-1)./lam4 )./lam2./D;
dUdlam3 = ( U3.^lam3-1-lam3.*U3.^lam3.*log(U3) )./lam3.^2./D;
dUdlam4 = ( -U4.^lam4 + lam4.*U4.^lam4.*log(U4) + 1 )./lam4.^2./D;
plhpU = ( (lam3-1).*U3.^(lam3-2) - (lam4-1).*U4.^(lam4-2) )./D;

dlhdlam1 = dUdlam1.*plhpU;
dlhdlam2 = -1./lam2 + dUdlam2.*plhpU;
dlhdlam3 = U3.^(lam3-1).*log(U3)./D + dUdlam3.*plhpU;
dlhdlam4 = U4.^(lam4-1).*log(U4)./D + dUdlam4.*plhpU;

if nargout>4
    D2 = D.^2;
    dDdlam3 = log(U3).*U3.^(lam3-1);
    dDdlam4 = log(U4).*U4.^(lam4-1);
    dDdU = (lam3-1).*U3.^(lam3-2)-(lam4-1).*U4.^(lam4-2);
    
    p2lhplam22 = 1./(lam2.^2);
    p2lhplam33 = ( (log(U3)).^2.*U3.^(lam3-1).*U4.^(lam4-1) )./D2;
    p2lhplam34 = -1*( U3.^(lam3-1).*log(U3) ).*( log(U4).*U4.^(lam4-1) )./D2;
    p2lhplam3U = ( U3.^(lam3-2).*((lam3-1).*log(U3)+1).*D - ...
        U3.^(lam3-1).*log(U3).*((lam3-1).*U3.^(lam3-2) - (lam4-1).*U4.^(lam4-2)) )./D2;
    p2lhplam44 = ( (log(U4)).^2.*U4.^(lam4-1).*U3.^(lam3-1) )./D2;
    p2lhplam4U = ( -U4.^(lam4-2).*((lam4-1).*log(U4)+1).*D + ...
        U4.^(lam4-1).*log(U4).*((lam4-1).*U4.^(lam4-2) - (lam3-1).*U3.^(lam3-2)) )./D2;
    p2lhplamUU = ((lam3-1).*(lam3-2).*U3.^(lam3-3)+(lam4-1).*(lam4-2).*U4.^(lam4-3))./D-...
        plhpU.*dDdU./D;
    
    p2Uplam12 = -1./D;
    p2Uplam13 = lam2.*dDdlam3./D2;
    p2Uplam14 = lam2.*dDdlam4./D2;
    p2Uplam1U = lam2.*dDdU./D2;
    p2Uplam22 = -dUdlam2./lam2;
    p2Uplam23 = -1*dDdlam3.*dUdlam2./D - dUdlam3./lam2;
    p2Uplam24 = -1*dDdlam4.*dUdlam2./D - dUdlam4./lam2;
    p2Uplam2U = -plhpU.*dUdlam2 + 1./lam2;
    p2Uplam33 = -(log(U3)).^2.*U3.^lam3./(D.*lam3) - dUdlam3.*(2*lam3.*D+lam3.^2.*dDdlam3)./(lam3.^2.*D);
    p2Uplam34 = -dUdlam3.*dDdlam4./D;
    p2Uplam3U = -U3.^(lam3-1).*log(U3)./D - dUdlam3.*dDdU./D;
%     p2Uplam43 = -dUdlam4.*dDdlam3./D;
    p2Uplam44 =  (log(U4)).^2.*U4.^lam4./(D.*lam4) - dUdlam4.*(2*lam4.*D+lam4.^2.*dDdlam4)./(lam4.^2.*D);
    p2Uplam4U = -U4.^(lam4-1).*log(U4)./D - dUdlam4.*dDdU./D;
    
    d2lhdlam11 = p2lhplamUU.*dUdlam1.^2 + plhpU.*(p2Uplam1U.*dUdlam1);
    d2lhdlam12 = (p2lhplamUU.*dUdlam2).*dUdlam1 + plhpU.*(p2Uplam12+p2Uplam1U.*dUdlam2);
    d2lhdlam13 = (p2lhplam3U+p2lhplamUU.*dUdlam3).*dUdlam1 + plhpU.*(p2Uplam13+p2Uplam1U.*dUdlam3);
    d2lhdlam14 = (p2lhplam4U+p2lhplamUU.*dUdlam4).*dUdlam1 + plhpU.*(p2Uplam14+p2Uplam1U.*dUdlam4);
    d2lhdlam22 = p2lhplam22+...
        p2lhplamUU.*dUdlam2.^2+plhpU.*(p2Uplam22+p2Uplam2U.*dUdlam2);
    d2lhdlam23 = (p2lhplam3U+p2lhplamUU.*dUdlam3).*dUdlam2 + plhpU.*(p2Uplam23+p2Uplam2U.*dUdlam3);
    d2lhdlam24 = (p2lhplam4U+p2lhplamUU.*dUdlam4).*dUdlam2 + plhpU.*(p2Uplam24+p2Uplam2U.*dUdlam4);
    d2lhdlam33 = (p2lhplam33+p2lhplam3U.*dUdlam3) + ...
        (p2lhplam3U+p2lhplamUU.*dUdlam3).*dUdlam3 + plhpU.*(p2Uplam33+p2Uplam3U.*dUdlam3);
    d2lhdlam34 = (p2lhplam34+p2lhplam3U.*dUdlam4) + ...
        (p2lhplam4U+p2lhplamUU.*dUdlam4).*dUdlam3 + plhpU.*(p2Uplam34+p2Uplam3U.*dUdlam4);
    d2lhdlam44 = (p2lhplam44+p2lhplam4U.*dUdlam4) + ...
        (p2lhplam4U+p2lhplamUU.*dUdlam4).*dUdlam4 + plhpU.*(p2Uplam44+p2Uplam4U.*dUdlam4);
end