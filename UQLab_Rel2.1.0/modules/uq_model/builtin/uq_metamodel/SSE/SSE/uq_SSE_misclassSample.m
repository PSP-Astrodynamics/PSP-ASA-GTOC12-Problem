function [idx, usedThresh, Pm] = uq_SSE_misclassSample(Y, Yrepl, p0)
% UQ_SSE_MISCLASSSAMPLE determines which of the provided sample has a
%   nonzero misclassification probability
%   
%   [IDX, USEDTHRESH, PM] = UQ_SSE_MISCLASSSAMPLE(Y, YREPL, P0) returns the
%   indices IDX of the sample Y that has a nonzero misclassification
%   probability according to the replications in YREPL. If no samples have
%   a nonzero misclassification probability, the function returns the
%   indices IDX of the sample Y that are close to the limit state surface
%   according to P0. The function also returns a boolean stating whether
%   the threshold has been used and the sample-wise misclassification
%   probability

% compute misclassification probability and indices
Pm = mean(abs(double(Y<0) - double(Yrepl<0)),2);
Pm = Pm./max(Pm);
idx = Pm > 0;

% compute Y variance
varY = var(Y);

% initialize usedThresh as false
usedThresh = false;

if sum(idx) == 0 && varY > 0
   % if no sample points have a nonzero misclassification probability, and
   % the sample is nonconstant, use threshold
   
   % compute threshold
   threshold = quantile(abs(Y), p0);

   % compute misclassification probability and indices
   Pm = mean(double(abs(Yrepl)<threshold),2);
   Pm = Pm./max(Pm);
   idx = Pm > 0;
   
   % say that threshold was used
   usedThresh = true;
elseif varY == 0
    % sample is constant, return all points as idx
    idx = true(size(idx));
end
end