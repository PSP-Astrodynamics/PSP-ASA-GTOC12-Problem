function plotAx = uq_SSE_display_partition_physical2D(mySSE, maxRef, varargin)
%UQ_SSE_DISPLAY_PARTITION_PHYSICAL2D displays the partition of a 2D SSE in
%   the physical space
%    
%   UQ_SSE_DISPLAY_PARTITION_PHYSICAL2D(MYSSE, MAXREF) displays the SSE 
%   partition of MYSSE up to refinement MAXREF
%
%   UQ_SSE_DISPLAY_PARTITION_PHYSICAL2D(...,AX) displays the SSE partition 
%   inside the axis AX
%
%   AX = UQ_SSE_DISPLAY_PARTITION_PHYSICAL2D(...) returns the axis handle AX

%% Verify inputs
% set to maximum available refinement 
if  maxRef > max(mySSE.Graph.Nodes.ref)
    maxRef = max(mySSE.Graph.Nodes.ref);
end

%% Default plot properties
termDomIdx = mySSE.Runtime.termDomEvolution{maxRef+1};
fs = 16;
zSpacingDomain = 1e-2;
myInput = mySSE.Input.Original;

% get experimental design at requested maxRef
currX = mySSE.ExpDesign.X(mySSE.ExpDesign.ref <= maxRef,:);  

% get labels for parameters
for ii = 1:mySSE.Input.Dim
    currLabel = mySSE.Input.Original.Marginals(ii).Name;
    % assign to container
    paramLabels{ii} = currLabel;
end

% prepare grid
NPoints = 100;
U_limits = repmat([0.001,0.999].',1,2);
X_limits = uq_invRosenblattTransform(U_limits, myInput.Marginals, myInput.Copula);
x1 = linspace(X_limits(1,1),X_limits(2,1), NPoints);
x2 = linspace(X_limits(1,2),X_limits(2,2), NPoints);
[X1,X2] = meshgrid(x1,x2);

% transform to quantile space
X = [X1(:),X2(:)];
U = uq_RosenblattTransform(X, myInput.Marginals, myInput.Copula);

% evaluate input PDF
pdfVals = reshape(uq_evalPDF([X1(:),X2(:)],myInput),size(X1));

%% Get the axes to plot in
plotAx = uq_getPlotAxes(varargin{:});
% Set the axes to be invisible
axis(plotAx,'on')
hold on

%% PHYSICAL SPACE
% axis labels
xlabel(paramLabels{1},'Interpreter','latex','FontSize',fs)
ylabel(paramLabels{2},'Interpreter','latex','FontSize',fs)

set(plotAx,'XLim',X_limits(:,1),'YLim',X_limits(:,2),'TickLabelInterpreter','latex')%,'Xtick',[],'YTick',[])

% plot pdf if non-constant
if var(pdfVals) ~= 0
    contour(X1,X2,pdfVals,'b--')
end

% add point plot
plot(currX(:,1),currX(:,2),'or','MarkerFaceColor','r','MarkerSize',2);

% plot terminal domains
for dd = termDomIdx'
    % current level and Idx
    currLevel = mySSE.Graph.Nodes.level(dd);
    currIdx = mySSE.Graph.Nodes.idx(dd);
    
    % current bounds
    currBounds = mySSE.Graph.Nodes.bounds{dd};
    
    % create points on bound
    pointsOnBound = createPointsOnBound(currBounds,U);
    
    % transform to physical space
    pointsOnBound_X = uq_invRosenblattTransform(pointsOnBound, myInput.Marginals, myInput.Copula);
    
    % overwrite bounds with truncated bounds
    pointsOnBound_X = truncatePoints(pointsOnBound_X, X_limits);
    
    % draw subdomain
    fill(pointsOnBound_X(:,1),pointsOnBound_X(:,2),'w','LineWidth',0.001,'FaceAlpha',0);

    % add domain name
    domName = sprintf('$\\mathcal{D}_{\\mathbf{X}}^{%i,%i}$',currLevel,currIdx);
    % determine position
    insidePointIdx = uq_SSE_inBound(U,currBounds);
    textPos = median(X(insidePointIdx,:));
    text(textPos(1),textPos(2), domName,...
        'Interpreter','latex','HorizontalAlignment','center','VerticalAlignment','middle','FontSize',fs-6)
end
  
hold off
end

function pointsOnBound = createPointsOnBound(bounds,U)
% creates points in the quantile space that are apporoximately equally 
% spaced in the physical space 

% get points spaced equally in physical space
u1 = sort(unique([bounds(1,1);U(U(:,1)>bounds(1,1) & U(:,1)<bounds(2,1),1);bounds(2,1)]));
u2 = sort(unique([bounds(1,2);U(U(:,2)>bounds(1,2) & U(:,2)<bounds(2,2),2);bounds(2,2)]));
pointsOnBound = [u1, bounds(1,2)*ones(size(u1));...
                 bounds(2,1)*ones(size(u2)), u2;...
                 flipud(u1), bounds(2,2)*ones(size(u1));...
                 bounds(1,1)*ones(size(u2)), flipud(u2)];
end

function points = truncatePoints(points, limits)
% truncates points to specified limits
% init
lowerLimitsMatrix = ones(size(points,1),1)*limits(1,:);
underflowIdx = points < lowerLimitsMatrix;
points(underflowIdx) = lowerLimitsMatrix(underflowIdx);
upperLimitsMatrix = ones(size(points,1),1)*limits(2,:);
overflowIdx = points > upperLimitsMatrix;
points(overflowIdx) = upperLimitsMatrix(overflowIdx);
end