function H = uq_limitState(module, outIdx)
%UQ_LIMITSTATE creates a plot showing the failure and safe regions of a 2D
%   metamodel-based reliability analysis.
%    
%   UQ_LIMITSTATE(MODULE, OUTIDX) uses the results in MODULE to display the 
%   limit state function for output OUTIDX.
%
%   H = UQ_LIMITSTATE(...) returns the figure handle
%
%   See also UQ_DISPLAY_UQ_RELIABILITY.

%% validate input
myAnalysis = module;
if ~isa(myAnalysis, 'uq_analysis')
    error('Input needs to be a UQ_ANALYSIS object.')
end
if ~strcmpi(myAnalysis.Type, 'uq_reliability')
    error('Analysis needs to be a reliability analysis.')
end
if ~any(strcmpi(myAnalysis.Options.Method,{'sser','activelearning','alr','akmcs'}))
    error('Reliability analysis needs to be metamodel-based.')
end
if length(myAnalysis.Internal.Input.nonConst) ~= 2
    error('Works only for 2-dimensional problems.')
end

% extract Results
Results = module.Results;

% extract metamodel and history
switch lower(myAnalysis.Options.Method)
    case 'sser'
        myMetamodel = module.Results.SSER(outIdx);
        % get extremes
        minX = []; maxX = [];
        for dd = 1:numnodes(myMetamodel.SSE.Graph)
            Ucurr = myMetamodel.SSE.Graph.Nodes.History(dd).U;
            if ~isempty(Ucurr)
                Xcurr = uq_invRosenblattTransform(Ucurr, myMetamodel.SSE.Input.Original.Marginals, myMetamodel.SSE.Input.Original.Copula);
                minX = min([minX; Xcurr]);
                maxX = max([maxX; Xcurr]);
            end
        end
    otherwise
        % non SSER
        minX = min(Results.History(outIdx).ReliabilitySample);
        maxX = max(Results.History(outIdx).ReliabilitySample);
end

% extract experimental design
X = myMetamodel.ExpDesign.X;
G = myMetamodel.ExpDesign.Y;

%% Init
colorOrder = uq_colorOrder(2);

% compute grid
NGrid = 200;
[xx, yy] = meshgrid(linspace(minX(1), maxX(1), NGrid), linspace(minX(2), maxX(2), NGrid));
zz = uq_evalModel(myMetamodel, [xx(:), yy(:)]) ;
zz = reshape( zz(:,outIdx),size(xx));

%% open figure
H{1} = uq_figure('Name', 'Limit-state approximation');

% Plot failed sample points
failedED = uq_plot(X(G(:,outIdx)<=0,1), X(G(:,outIdx)<=0,2), 's',...
        'MarkerFaceColor', colorOrder(1,:),...
        'Color', colorOrder(1,:));
hold on
% Plot safe points
safeED = uq_plot(X(G(:,outIdx)>0, 1), X(G(:,outIdx)>0, 2), '+',...
        'MarkerFaceColor', colorOrder(2,:),...
        'Color', colorOrder(2,:));

% plot limit-state surface
[~, limitStateSurface] = contour(xx,yy,zz, [0 0], 'k', 'linewidth', 2);

% beautify
labels = {'$g(X)\leq 0$', '$g(X)>0$', '$g(X)=0$'};
pp = [failedED,safeED,limitStateSurface];
myLegend = uq_legend(pp,labels([~isempty(failedED) ~isempty(safeED) ~isempty(limitStateSurface)]) );
set(myLegend, 'interpreter', 'latex')
xlabel(module.Internal.Input.Marginals(1).Name)
ylabel(module.Internal.Input.Marginals(2).Name)
title(sprintf('%s - limit state approximation', myAnalysis.Options.Method))
end