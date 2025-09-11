function [U_new, X_new] = uq_SSE_enrichment_LSS(obj, bounds, NEnrich)
% UQ_SSE_ENRICHMENT_LSS enriches the experimental design in an SSE 
%    object near the limit state surface.
%
%    [U_NEW, X_NEW] = UQ_SSE_ENRICHMENT_LSS(OBJ, BOUNDS, NENRICH)
%    Creates sample of size NENRICH in proximity of the limit state surface
%    inside BOUNDS and returns the points in the quantile space U_NEW and 
%    sample space X_NEW.

% init
currIdx = uq_SSE_inBound(obj.ExpDesign.U, bounds);
NCurrPoints = sum(currIdx);
NCand = 1e5;

% get sampling distribution
samplingDist = uq_uniformDist(bounds, '-private');

% global
U_cand = uq_getSample(samplingDist, NCand);

% transform to physical space
X_cand = uq_invRosenblattTransform(U_cand, obj.Input.Original.Marginals, obj.Input.Original.Copula);

% evaluate SSE and U function
[Y_cand, ~, ~, Yrepl] = evalSSE(obj, X_cand);

% determine number of required points
nLHS = floor((NCurrPoints + NEnrich)/2) - NCurrPoints;
if nLHS < 0; nLHS = 0; end
nLSS = NEnrich-nLHS;

% get misclassified Idx
p0 = 0.01;
misclassIdx = uq_SSE_misclassSample(Y_cand,Yrepl,p0);

% extract misclassified U_cand
U_cand = U_cand(misclassIdx,:);

% remove the points that lie directly at the global boundary
atDomainBoundary = any(U_cand == 0,2) | any(U_cand == 1, 2);
U_cand(atDomainBoundary,:) = [];

% actual enrichment
if ~isempty(U_cand) && ~all(misclassIdx)
    % get nLSS samples from U_cand
    if size(U_cand,1) <= nLSS
        % if fewer U_cand than nLSS, reduce nLSS and directly use the 
        % available points
        U_new = U_cand;
        % update LHS
        nLHS = NEnrich - size(U_cand,1);
    else
        % take first nLSS points (they are random)
        U_new = U_cand(1:nLSS,:);
        
        % update LHS
        nLHS = NEnrich - size(U_new,1);
    end
    
    % get nLHS samples from uq_LHSify
    U_LHS = uq_LHSify([obj.ExpDesign.U(currIdx,:); U_new], nLHS, samplingDist);
    U_new = [U_new; U_LHS];
else
    % Do just LHS
    U_new = uq_LHSify(obj.ExpDesign.U(currIdx,:), nLHS+nLSS, samplingDist);
end          

% transform to physical space
X_new = uq_invRosenblattTransform(U_new, obj.Input.Original.Marginals, obj.Input.Original.Copula);
end