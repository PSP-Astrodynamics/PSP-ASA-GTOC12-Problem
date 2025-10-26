function H = uq_SSE_display(SSEModel, outArray, varargin)
% UQ_SSE_DISPLAY(SSEModel,OUTARRAY,VARARGIN): graphically displays an SSE 
%    surrogate model for the outputs specified by OUTARRAY.
%
%    UQ_SSE_DISPLAY(SSEModel, OUTARRAY, NAME, VALUE) allows to choose
%    more advanced plot functions by specifying Name/Value pairs:
%
%       Name                   VALUE
%       'partitionQuantile'    Plots the partition up to a specified 
%                              reference in the quantile space 
%                              (1D and 2D functions only).
%                              - Integer or false
%                              default, M = 1 or M = 2 : inf
%                              default, M > 2: false
%
%       'partitionPhysical'    Plots the partition up to a specified 
%                              reference in the physical space 
%                              (1D and 2D functions only).
%                              - Integer or false
%                              default, M = 1 or M = 2 : inf
%                              default, M > 2: false
%
%       'refineScore'          Plots the refinement score for the terminal
%                              domains of a specified reference.
%                              - Integer or false
%                              default : false
%
%       'errorEvolution'       Plots the error estimate evolution as a 
%                              function of algorithm refinement steps
%                              - Logical
%                              default : false
%
%       'plotGraph'            Plots the SSE graph
%                              - Integer or false
%                              default : inf
%
%    H = UQ_SSE_DISPLAY(...) returns an array of figure handles.
%                          
% See also: UQ_SSE_PRINT

% 
% See also: UQ_DISPLAY_UQ_METAMODEL

%% CONSISTENCY CHECKS
if ~SSEModel.Internal.Runtime.isCalculated
    fprintf('SSE module %s is not yet initialized!\nGiven Configuration Options:', SSEModel.Name);
    SSEModel.Options
    return;
end

%% INITIALIZE
nDim = SSEModel.SSE(1).Input.Dim;
% figure handle array
H = {};
% title fontsize
fs = 18;

%% Default behavior
% partition
if nDim == 2
    Default.plotPartitionQuantileRef = inf;
    Default.plotPartitionPhysicalRef = inf;
elseif nDim == 1
    Default.plotPartitionQuantileRef = 'false';
    Default.plotPartitionPhysicalRef = inf;
else
    Default.plotPartitionQuantileRef = false;
    Default.plotPartitionPhysicalRef = false;
end
% refineScore
Default.plotRefineScoreRef = 'false';
% errorEvolution
Default.plotErrorEvolution_flag = false;
% plotGraph
Default.plotGraph_flag = true;
Default.plotGraphRef = inf;

%% Check for input arguments
% set optional arguments
if nargin > 2
    % vargin given
    parse_keys = {'partitionquantile','partitionphysical','refinescore',....
        'errorevolution','plotgraph'};
    parse_types = {'p','p','p','p','p'};
    % make NAME lower case
    varargin(1:2:end) = lower(varargin(1:2:end));
    [uq_cline, ~] = uq_simple_parser(varargin, parse_keys, parse_types);
else
    % no varargin, use default options
    uq_cline{1} = Default.plotPartitionQuantileRef;
    uq_cline{2} = Default.plotPartitionPhysicalRef;
    uq_cline{3} = Default.plotRefineScoreRef;
    uq_cline{4} = Default.plotErrorEvolution_flag;
    uq_cline{5} = Default.plotGraphRef;
end

% 'partitionQuantile' plots the domain partition in the quantile space
if ~strcmp(uq_cline{1}, 'false')
    if islogical(uq_cline{1}) 
        % only admits false
        plotPartitionQuantile_flag = uq_cline{1};
    else
        plotPartitionQuantile_flag = true;
        plotPartitionQuantileRef = uq_cline{1};
    end
else
    plotPartitionQuantile_flag = false;
end

% 'partitionPhysical' plots the domain partition in the physical space
if ~strcmp(uq_cline{2}, 'false')
    if islogical(uq_cline{2}) 
        % only admits false
        plotPartitionPhysical_flag = uq_cline{2};
    else
        plotPartitionPhysical_flag = true;
        plotPartitionPhysicalRef = uq_cline{2};
    end
else
    plotPartitionPhysical_flag = false;
end

% 'refinescore' plots the error estimates for the terminal domains
if ~strcmp(uq_cline{3}, 'false')
    plotRefineScore_flag = true;
    plotRefineScoreRef = uq_cline{3};
else
    plotRefineScore_flag = false;
end

% 'errorEvolution' plots the error estimator evolution
if ~strcmp(uq_cline{4}, 'false')
    plotErrorEvolution_flag = uq_cline{4};
else
    plotErrorEvolution_flag = false;
end

% 'plotGraph' plots the graph
if ~strcmp(uq_cline{5}, 'false')
    plotGraph_flag = true;
    plotGraphRef = uq_cline{5};
else
    plotGraph_flag = false;
end

%% Loop over outputs and create the plots
for ii = 1:length(outArray)
      % get current output
      oo = outArray(ii);
      currSSE = SSEModel.SSE(oo);
      
      %% plot partition quantile
      if plotPartitionQuantile_flag
          if nDim == 2
              H{end + 1} = uq_figure('Name','Partition quantile space');
              uq_SSE_display_partition_quantile2D(currSSE, plotPartitionQuantileRef, varargin);
              % title
              title('Partition quantile space','Interpreter','latex','FontSize',fs)
          else
              warning('''partitionQuantile'' is only supported for 2D surrogate models.')
          end
      end
      
      %% plot partition physical
      if plotPartitionPhysical_flag
          H{end + 1} = uq_figure('Name','Partition physical space');
          if nDim == 1
              uq_SSE_display_partition_physical1D(currSSE, plotPartitionPhysicalRef, varargin);
          elseif nDim == 2
              uq_SSE_display_partition_physical2D(currSSE, plotPartitionPhysicalRef, varargin);
          else
              warning('''partitionPhysical'' is only supported for 1D or 2D surrogate models.')
          end
          % title
          title('Partition physical space','Interpreter','latex','FontSize',fs)
      end
      
      %% plot refinement score domain-wise
      if plotRefineScore_flag
          % init
          % verify input
          if  plotRefineScoreRef > max(currSSE.Graph.Nodes.ref)
              plotRefineScoreRef = max(currSSE.Graph.Nodes.ref);
          end
          
          % get data
          termDomsIdx = currSSE.Runtime.termDomEvolution{plotRefineScoreRef + 1};
          refineScore = currSSE.Graph.Nodes.refineScore(termDomsIdx);
          % normalize
          relRefineScore = refineScore/sum(refineScore);
          
          % prepare labels
          domLabels = {};
          for tt = termDomsIdx'
              currLevel = currSSE.Graph.Nodes.level(tt);
              currIdx = currSSE.Graph.Nodes.idx(tt);
              domLabels{end+1} =  sprintf('$\\mathcal{D}_{\\mathbf{X}}^{%i,%i}$',currLevel,currIdx);
          end
          
          % combine domains with a score below a certain threshold
          threshComb = 0.01;
          isRelev = relRefineScore > threshComb;
          relevDoms = termDomsIdx(isRelev);
          refineScore_trunc = refineScore(isRelev);
          domLabels_trunc = domLabels(isRelev);
          
          % sort according to size
          [refineScore_trunc, sortIdx] = sort(refineScore_trunc,'descend');
          domLabels_trunc = domLabels_trunc(sortIdx);
          
          if any(isRelev)
              % add truncated domains
              refineScore_trunc = [refineScore_trunc; sum(refineScore(~isRelev))];
              domLabels_trunc{end+1} = 'Others';
          end
                    
          % plot
          H{end + 1} = uq_figure('Name','Refinement scores');
          barPlot = uq_bar(categorical(domLabels_trunc,domLabels_trunc),refineScore_trunc);
          
          % title
          title('Refinement scores in $\mathcal{T}$','Interpreter','latex','FontSize',fs)
      end
      
      %% plot error evolution
      if plotErrorEvolution_flag
          if ~isempty(currSSE.Runtime.relWREEvolution)
              ISRELATIVEERROR = true;
              errorEvolution = currSSE.Runtime.relWREEvolution;
          else
              ISRELATIVEERROR = false;
              errorEvolution = currSSE.Runtime.absWREEvolution;
          end
          
          % init
          maxRef = currSSE.currRef;
          sampleRef = currSSE.ExpDesign.ref; 
          ref = 0:maxRef;
          NED = nan(maxRef,1);
          for rr = ref
              currNED = sum(sampleRef==rr);
              if rr == 0
                  NED(rr+1) = currNED;
              else
                  NED(rr+1) = NED(rr)+currNED;
              end
          end
          
          H{end + 1} = uq_figure('Name','WRE evolution');
          ax(1) = subplot(3,1,1:2);
          hold on
          grid on

          % plot
          ssePlot = uq_plot(ref,errorEvolution);

          % beautify
          uq_legend(ssePlot,{'SSE'},'Interpreter','latex','location','best')
          if ISRELATIVEERROR
              title('Relative weighted residual expansion error','Interpreter','latex')
              ylabel('$\epsilon_{\mathrm{WRE}}$','Interpreter','latex')
          else
              title('Absolute weighted residual expansion error','Interpreter','latex')
              ylabel('$E_{\mathrm{WRE}}$','Interpreter','latex')
          end

          % eperimental design size
          ax(2) = subplot(3,1,3);
          grid on
          uq_plot(ref,NED)

          % beautify
          set(ax(1),'YScale','log')
          uq_SSE_formatDoubleAxes(ax, ref)
      end
      
      %% plot graph
      if plotGraph_flag
          % init
          termDomColor = [1.0000    0.6471    0.1882];
          maxDomNamesPerLevel = 4;
          % get terminal domain indices
          termDomIdx = currSSE.Runtime.termDomEvolution{end};
          % determine which domains get a label
          Nlevel = currSSE.Graph.Nodes.level;
          domainNamesBool = cell(1,max(Nlevel)+1);
          for ll = 0:max(Nlevel)
              NDomsCurrLevel = sum(currSSE.Graph.Nodes.level == ll);
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
          
          % extract graph
          myGraph = currSSE.Graph;
          if plotGraphRef < currSSE.currRef
              % prune the graph by removing all nodes before plotGraphRef
              relevIdx = find(myGraph.Nodes.ref <= plotGraphRef);
              myGraph = subgraph(myGraph, relevIdx);
              % get terminal domain indices
              termDomIdx = currSSE.Runtime.termDomEvolution{plotGraphRef+1};
          else
              plotGraphRef = currSSE.currRef;
          end
                    
          % plot
          H{end + 1} = uq_figure('Name','Subdomain graph');
          graphPlot = plot(myGraph);
          
          % beautify
          layout(graphPlot,'layered','Direction','up')
          
          nodesColor = zeros(0,3);
          % loop over all nodes
          domNamesLaTeX = cell(1,numnodes(myGraph));
          domNames = cell(1,numnodes(myGraph));
          for dd = 1:numnodes(myGraph)
            currLevel = myGraph.Nodes.level(dd);
            currIdx = myGraph.Nodes.idx(dd);
            domNamesLaTeX{dd} = sprintf('$\\mathcal{D}_{\\mathbf{X}}^{%i,%i}$',currLevel,currIdx);
            domNames{dd} = sprintf('D(%i,%i)',currLevel,currIdx);
            nodesColor = [nodesColor; 0 0 0];
            if any(dd == termDomIdx)
                nodesColor(end,:) = termDomColor;
            end
            if isempty(myGraph.Nodes.expansions(dd))
                % no exapanson in current node, put tilde on domain name
                domNamesLaTeX{dd} = ['\widetilde{',domNamesLaTeX{dd},'}'];
            end
            % remove domain name, if it does not get a label
            if ~domainNamesBool{currLevel+1}(currIdx)
                domNamesLaTeX{dd} = '';
                domNames{dd} = '';
            end
          end
          set(graphPlot,'NodeLabel',domNames,'LineWidth',1,'EdgeColor','k',...
              'NodeColor',nodesColor)
          
          % for 2018b and later
          if uq_checkMATLAB('r2018b')
              set(graphPlot,'NodeFontSize',fs-10,'Interpreter','latex',...
                  'NodeLabelColor',nodesColor,'NodeLabel',domNamesLaTeX)
          end
          
          % legend
          hold on
          set(graphPlot.Parent, 'visible', 'off')
          dummyPlot_nonTerminal = uq_plot(nan,nan,'ko');
          dummyPlot_terminal = uq_plot(nan,nan,'o','Color',termDomColor);
          uq_legend([dummyPlot_nonTerminal, dummyPlot_terminal],{'$\mathcal{K}\setminus\mathcal{T}$','$\mathcal{T}$'},'interpreter','latex')
          
          % title
          title(sprintf('SSE graph at refinement step %d',plotGraphRef),'Interpreter','latex','FontSize',fs)
          set(graphPlot.Parent.Title,'visible','on')
      end
end
