function [plotAxFun, plotAxDom] = uq_SSE_display_partition_physical1D(mySSE, maxRef, varargin)
%UQ_SSE_DISPLAY_PARTITION_PHYSICAL1D displays the partition of a 1D SSE
%    
%   UQ_SSE_DISPLAY_PARTITION_PHYSICAL1D(MYSSE, MAXREF) displays the SSE 
%   partition of MYSSE up to refinement MAXREF
%
%   UQ_SSE_DISPLAY_PARTITION_PHYSICAL1D(...,AX) displays the SSE partition 
%   inside the axis AX
%
%   [AXFUN, AXDOM] = UQ_SSE_DISPLAY_PARTITION_PHYSICAL1D(...) returns the 
%   axis handle to the function AXFUN and domain AXDOM plots

%% Verify inputs
% set to maximum available refinement 
if  maxRef > max(mySSE.Graph.Nodes.ref)
    maxRef = max(mySSE.Graph.Nodes.ref);
end

%% Default plot properties
termDomColor = [1.0000    0.6471    0.1882];
termDomIdx = mySSE.Runtime.termDomEvolution{maxRef+1};
maxLevel = max(mySSE.Graph.Nodes.level(termDomIdx));
domFs = 8;
domLabelZShift = 0.5;
maxDomNamesPerLevel = 4;
myInput = mySSE.Input.Original;

% get experimental design at requested maxRef
currX = mySSE.ExpDesign.X(mySSE.ExpDesign.ref <= maxRef,:);
currY = mySSE.ExpDesign.Y(mySSE.ExpDesign.ref <= maxRef,:);

% get label
paramLabel = myInput.Marginals.Name;

% prepare grid
NPoints = 100;
U_limits = [0.001,0.999].';
X_limits = uq_all_invcdf(U_limits, myInput.Marginals);
X = linspace(X_limits(1),X_limits(2), NPoints).';

% determine which domains get a label
for ll = 0:max(mySSE.Graph.Nodes.level)
    NDomsCurrLevel = sum(mySSE.Graph.Nodes.level == ll);
    if NDomsCurrLevel > maxDomNamesPerLevel
        % too many domains on ll-th level
        domainNamesIdx = round(linspace(1,NDomsCurrLevel,maxDomNamesPerLevel));
        domainNamesBool{ll+1} = false(NDomsCurrLevel,1);
        domainNamesBool{ll+1}(domainNamesIdx) = true(maxDomNamesPerLevel,1);
    else
        % not too many domains on ll-th level
        domainNamesBool{ll+1} = true(NDomsCurrLevel,1);
    end
end

% evaluate input PDF
pdfVals = uq_evalPDF(X,myInput);

% evaluate SSE
ySSE = evalSSE(mySSE,X);

%% Function
% Get the axes to plot in
plotAxFun = uq_subplot(2,1,1);
uq_formatDefaultAxes(plotAxFun)
hold on

% plot SSE 
uq_plot(X,ySSE)

% plot ED
uq_plot(currX, currY, 'ro','MarkerSize',2)

% legend
uq_legend({'$\mathcal{M}_{\mathrm{SSE}}$','$\mathcal{X}$'}');

% beautify
xlabel([])
ylabel([])
xlim([X_limits(1), X_limits(2)])
set(plotAxFun,'XTick',[])

%% DOMAINS
% Get the axes to plot in
plotAxDom = uq_subplot(2,1,2);
uq_formatDefaultAxes(plotAxDom)
hold on

% plot PDF
PDFplot = uq_plot(X,pdfVals/max(pdfVals)*maxLevel+domLabelZShift,'b--');

for rr = 0:maxRef
    % get vector of current domain idx
    currDomIdx = find(mySSE.Graph.Nodes.ref == rr);
    % loop over current domains
    for dd = currDomIdx'
        bounds = mySSE.Graph.Nodes.bounds{dd};
        bounds_X = uq_all_invcdf(bounds,myInput.Marginals);
        % take care of infinite bounds
        if bounds_X(1) < X_limits(1); bounds_X(1) = X_limits(1); end
        if bounds_X(2) > X_limits(2); bounds_X(2) = X_limits(2); end

        % plot as line
        x = bounds_X;
        y = mySSE.Graph.Nodes.level(dd)*[1 1];
        domPlot(1) = uq_plot(x,y,'k','Linewidth',1);
        domPlot(2) = uq_plot([x(1);x(1)],[y(1)-0.2;y(1)+0.2],'k','Linewidth',1);
        domPlot(3) = uq_plot([x(2);x(2)],[y(1)-0.2;y(1)+0.2],'k','Linewidth',1);

        % check if current domain is terminal domain
        if any(dd == termDomIdx)
            for pp = 1:length(domPlot)
                set(domPlot(pp), 'Color', termDomColor)
            end

            % add domain name
            currLevel = mySSE.Graph.Nodes.level(dd);
            currIdx = mySSE.Graph.Nodes.idx(dd);
            % check whether it gets a name label
            if domainNamesBool{currLevel+1}(currIdx)
                domName = sprintf('$\\mathcal{D}_{\\mathbf{X}}^{%i,%i}$',currLevel,currIdx);
                text(mean(x),y(1)+domLabelZShift,domName,'Color',termDomColor,'FontSize',domFs,'Interpreter','latex','HorizontalAlignment','center','VerticalAlignment','middle');
            end
        end
    end
end
% beautify
set(plotAxDom,'YTick',unique(round(plotAxDom.YTick)))
xlim([X_limits(1), X_limits(2)])
ylim([0, maxLevel*1.4])
ylabel('Levels')
xlabel(paramLabel)

% add legend with dummy lines for color
domain = uq_plot([NaN,NaN], 'color', [0 0 0],'Linewidth',1);
term = uq_plot([NaN,NaN], 'color', termDomColor,'Linewidth',1);

if uq_checkMATLAB('r2018a')
    % for 2018a and later
    uq_legend([domain, term,PDFplot],{'$\mathcal{K}\setminus\mathcal{T}$','$\mathcal{T}$','Input PDF'},'location','northoutside','NumColumns',3)
else
    % for 2017b and before
    uq_legend([domain, term,PDFplot],{'$\mathcal{K}\setminus\mathcal{T}$','$\mathcal{T}$','Input PDF'},'location','best')
end

hold off

% make upper plot gca
axes(plotAxFun)
end