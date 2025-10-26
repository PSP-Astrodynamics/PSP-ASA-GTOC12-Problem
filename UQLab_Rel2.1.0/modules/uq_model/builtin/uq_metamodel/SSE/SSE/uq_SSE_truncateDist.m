function truncatedDist = uq_SSE_truncateDist(Dist, bounds)
% OBJ = UQ_SSE_TRUNCATEDIST(DIST, BOUNDS): truncate distribution to bounds
%     specified by BOUNDS

% init
InputDim = size(bounds,2);

% truncate a UQLab input object
truncOpts.Marginals = Dist.Options.Marginals;
for mm = 1:InputDim
    truncOpts.Marginals(mm).Bounds = bounds(:,mm);
end
truncatedDist = uq_createInput(truncOpts, '-private');
end