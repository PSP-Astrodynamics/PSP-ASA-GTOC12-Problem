function [U_new, X_new] = uq_SSE_enrichment_uniform(obj, bounds, NEnrich)
% UQ_SSE_ENRICHMENT_UNIFORM enriches the experimental design in an SSE 
%    object uniformly considering the available experimental design.
%
%    [F_NEW, X_NEW] = UQ_SSE_ENRICHMENT_UNIFORM(OBJ, BOUNDS, NENRICH)
%    Creates uniform sample of size NENRICH inside BOUNDS and returns the
%    points in the quantile space F_NEW and sample space X_NEW.
%
% See also: UQ_LHSIFY

% get sampling distribution
samplingDist = uq_uniformDist(bounds, '-private');
% and current indices
currIdx = uq_SSE_inBound(obj.ExpDesign.U, bounds);

% LHSify
U_new = uq_LHSify(obj.ExpDesign.U(currIdx,:), NEnrich, samplingDist);

% transform to physical space
X_new = uq_invRosenblattTransform(U_new, obj.Input.Original.Marginals, obj.Input.Original.Copula);
end