function logIdx = uq_SSE_inBound(U, bounds)
% UQ_SSE_INBOUNDIDX determines which points lie inside the supplied bounds
%
%    IDX = UQ_SSE_INBOUNDIDX(U, BOUNDS) returns the vector IDX containing
%    the logical indices of those U that lie inside BOUNDS

% get indices of points that lie inside the supplied bounds
lowerBounds = all(U  > bounds(1,:),2);
upperBounds = all(U  <= bounds(2,:),2);
logIdx = logical(lowerBounds.*upperBounds);
end