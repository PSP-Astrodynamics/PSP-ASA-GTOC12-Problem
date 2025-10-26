function mass = uq_SSE_volume(bounds, varargin)
% UQ_SSE_VOLUME computes the volume of hypercube
%
%   MASS = UQ_SSE_VOLUME(BOUNDS) returns the volume of the M-dimensional
%   hypercube defined by the Mx2 matrix BOUNDS
%
%   MASS = UQ_SSE_VOLUME(BOUNDS, DIMS) includes only the dimensions listed
%   in the vector DIMS

% is DIMS given
if nargin > 1
    dims = varargin{1};
else
    dims = 1:size(bounds,2);
end

% init
mass = 1;

% loop over dimensions
for dd = dims
    % get the input CDF values at the bounds
    %  cdfVals = uq_cdfFun(bounds(:,dd), input.Marginals(dd).Type, input.Marginals(dd).Parameters);
    cdfVals = bounds(:,dd);
    
    % update input mass
    mass = mass*diff(cdfVals);
end
end