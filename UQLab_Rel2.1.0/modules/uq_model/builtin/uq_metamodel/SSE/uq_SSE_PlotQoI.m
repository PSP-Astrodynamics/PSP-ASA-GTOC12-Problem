function uq_SSE_PlotQoI(mySSE,QoI,vargin)

if ~exist('QoI','var')
    QoI = 'domain';
end
myGraph = mySSE.graph;
NNodes = myGraph.numnodes;
CCscale = gray(NNodes+1);
% shuffle color map
CCscale = CCscale(randperm(size(CCscale,1)),:);

plotNodes = 1:NNodes;

switch QoI
    case 'domain'
        % initialize figure
        f1 = figure('Position',[200 400 560 420]); ax1 = axes(f1); hold on
    case 'error'
        % initialize 3 figures
        close all
        f1 = figure('Position',[200 400 560 420]); ax1 = axes(f1); hold on
        f2 = figure('Position',[800 400 560 420]); ax2 = axes(f2); hold on
        f3 = figure('Position',[800 400 560 420]); ax3 = axes(f3); hold on
        
        Pftrue = zeros(NNodes,1);
        Pfest = zeros(NNodes,1);
        for ii = 2:NNodes
            if outdegree(myGraph,ii) == 0
                currBounds = myGraph.Nodes.bounds{ii};
                % get samples in bounds
                [YSSE,~,X] = evalSSEInDomain(mySSE,currBounds);
                % true Pf
                Pfest(ii) = mean(YSSE<0);
                
                % model Pf
                YTrue = mySSE.model(X);
                Pftrue(ii) = mean(YTrue<0);
            end
        end
        
        % precompute some things
        normalizer = max([Pfest(:); Pftrue(:)]);
        Pfest = Pfest/normalizer;
        Pftrue = Pftrue/normalizer;
        Pfdiff = abs(Pfest - Pftrue)/max(abs(Pfest - Pftrue));
    case 'neighbour'
        close all
        f1 = figure('Position',[200 400 560 420]); ax1 = axes(f1); hold on
        subID = vargin;
        plotNodes = mySSE.graph.Nodes.neighbours{subID};
        % add current id
        plotNodes = [plotNodes, subID];
end

for ii = plotNodes
    currBounds = myGraph.Nodes.bounds{ii};
    Xdom = [currBounds(1,1),currBounds(2,1),currBounds(2,1),currBounds(1,1)];
    Ydom = [currBounds(1,2),currBounds(1,2),currBounds(2,2),currBounds(2,2)];
    Zdom = ones(4,1)*myGraph.Nodes.ref(ii);
    switch QoI
        case 'domain'
            % if is a terminal domain, tint
            if outdegree(myGraph,ii) == 0
                % terminal domain
                domcolor = [1 0.549 0];
                CC = domcolor;
            else
                domcolor = [1 1 1]*0.3;
                CC = domcolor;
            end
            fill3(Xdom,Ydom,Zdom,CC)
            %ginput(1);
        case 'error'
            cmap = hot;
            if ~myGraph.outdegree(ii)
                % first plot actual error
                cID = 1+floor(Pftrue(ii)*(size(cmap,1)-1));
                fill3(ax1,Xdom,Ydom,Zdom,cmap(cID,:))
                
                % then the approximation
                cID = 1+floor(Pfest(ii)*(size(cmap,1)-1));
                fill3(ax2,Xdom,Ydom,Zdom,cmap(cID,:))
                
                % then the difference
                cID = 1+floor(Pfdiff(ii)*(size(cmap,1)-1));
                fill3(ax3,Xdom,Ydom,Zdom,cmap(cID,:))
            end
        case 'neighbour'
            CC = [1 1 1]*rand;
            if ii == plotNodes(end)
                fill3(ax1,Xdom,Ydom,Zdom,CC,'EdgeColor','r')
            else
                fill3(ax1,Xdom,Ydom,Zdom,CC)
            end
            ylim([0,1]); xlim([0,1]);
    end
    
end
xticks([]); yticks([]); %zticks([]);
xlabel('$Q_1(X_1)$', 'interpreter', 'latex','FontSize',14)
ylabel('$Q_2(X_2)$', 'interpreter', 'latex','FontSize',14)
zlabel('Level', 'interpreter', 'latex','FontSize',14)
rotate3d on

end