function lf = uq_LF_FBR(Gboot)
% UQ_LF_U computes the U-function for AK-MCS
% 
% References:
%
%   Reference to Stefano conference paper...
%
% See also: UQ_AKMCS
if length(size(Gboot)) <= 2
    Bf = sum( Gboot <= 0,2 ) ; % Number of times a given sample is in the failure domain
    Bs = sum( Gboot > 0,2 ) ; % Number of times a given sample is in the safe domain
    lf = - ( abs(Bf - Bs) ./ (Bs + Bf) );
else
    for ii = 1:size(Gboot,3)
        Bf = sum(Gboot(:,:,ii) <= 0, 2) ;
        Bs = sum(Gboot(:,:,ii) > 0, 2) ;
        lf(:,ii) = - ( abs(Bf - Bs) ./ (Bs + Bf) );
        
    end
end