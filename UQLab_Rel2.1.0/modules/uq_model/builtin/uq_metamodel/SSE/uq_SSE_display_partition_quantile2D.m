    function plotAx = uq_SSE_display_partition_quantile2D(mySSE, maxRef, varargin)
%UQ_SSE_DISPLAY_PARTITION_QUANTILE2D displays the partition of a 2D SSE in
%   the quantile space
%    
%   UQ_SSE_DISPLAY_PARTITION_QUANTILE2D(MYSSE, MAXREF) displays the SSE 
%   partition of MYSSE up to refinement MAXREF
%
%   UQ_SSE_DISPLAY_PARTITION_QUANTILE2D(...,AX) displays the SSE partition 
%   inside the axis AX
%
%   AX = UQ_SSE_DISPLAY_PARTITION_QUANTILE2D(...) returns the axis handle AX

%% Verify inputs
% set to maximum available refinement 
if  maxRef > max(mySSE.Graph.Nodes.ref)
    maxRef = max(mySSE.Graph.Nodes.ref);
end

%% Default plot properties
termDomColor = [1.0000    0.6471    0.1882];
termDomIdx = mySSE.Runtime.termDomEvolution{maxRef+1};
maxLevel = max(mySSE.Graph.Nodes.level(termDomIdx));
fs = 16;
zSpacingDomain = 1e-2;
pointZShift = 0;
domLabelZShift = zSpacingDomain*0.3;

% get experimental design at requested maxRef
currU = mySSE.ExpDesign.U(mySSE.ExpDesign.ref <= maxRef,:);  

%% Get the axes to plot in
plotAx = uq_getPlotAxes(varargin{:});
% Set the axes to be invisible
axis(plotAx,'off')
hold on

%% QUANTILE SPACE
% setup camera
camproj('perspective')
set(plotAx,'CameraTarget',[0.5000    0.5000    maxLevel*zSpacingDomain/2],...
    'CameraPosition',[-2.5   -3    maxLevel*zSpacingDomain*4.5],...
    'CameraUpVector',[0     0     1],...
    'CameraViewAngle',15)

% axis labels
text(0.5, -0.1,0, '$U_1$','Interpreter','latex','FontSize',fs)
text(-0.1, 0.5,0, '$U_2$','Interpreter','latex','FontSize',fs)

for rr = 0:maxRef
    % get vector of current domain idx
    currDomIdx = find(mySSE.Graph.Nodes.ref == rr);
    % loop over current domains
    for dd = currDomIdx'
        % curr domain z-Coordinate
        currLevel = mySSE.Graph.Nodes.level(dd);
        currIdx = mySSE.Graph.Nodes.idx(dd);
        currZ = currLevel*zSpacingDomain;
        
        % curr bounds
        currBounds = mySSE.Graph.Nodes.bounds{dd};
        
        % plot current domain
        domCorners = [  currBounds(1,1), currBounds(1,2);...
                        currBounds(2,1), currBounds(1,2);...
                        currBounds(2,1), currBounds(2,2);...
                        currBounds(1,1), currBounds(2,2);];

        % plot domain
        domPlotsCurr = fill3(plotAx, domCorners(:,1)',domCorners(:,2)',ones(4,1)*currZ,'w','LineWidth',0.0001);
        
        if any(termDomIdx == dd)
            % is terminal domain
            
            % color terminal domains
            set(domPlotsCurr,'FaceColor',termDomColor,'FaceAlpha',0.9)
            
            % plot experimental design in current terminal domain
            currIndices = uq_SSE_inBound(currU, currBounds);
            plot3(plotAx,...
                  currU(currIndices,1),...
                  currU(currIndices,2),...
                  ones(size(currU(currIndices,:),1),1)*currZ+pointZShift,'or','MarkerFaceColor','r','MarkerSize',2);
              
            % add domain name
            domName = sprintf('$\\mathcal{D}_{\\mathbf{U}}^{%i,%i}$',currLevel,currIdx);
            text(mean(currBounds(:,1)),mean(currBounds(:,2)),currZ+domLabelZShift, domName,...
                'Interpreter','latex','HorizontalAlignment','center','VerticalAlignment','middle','FontSize',fs-6)
        end
    end
end
  
hold off
end