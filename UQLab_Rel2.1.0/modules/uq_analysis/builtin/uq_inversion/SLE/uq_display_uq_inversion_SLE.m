function H = uq_display_uq_inversion_SLE(module, varargin)
% UQ_DISPLAY_UQ_INVERSION_SLE graphically displays the results of an 
%    SLE-based inverse analysis carried out with the Bayesian inversion 
%    module of UQLab.
%
%    UQ_DISPLAY_UQ_INVERSION_SLE(MODULE, NAME, VALUE) allows to choose
%    more advanced plot functions by specifying Name/Value pairs:
%
%       Name               VALUE
%       'densityplot'      Plots a multi dimensional parameter density
%                          plot of the prior and posterior densitites 
%                          - Integer or 'all'
%                          default : 'all'
%
%       'displaypce'       Runs the PCE-specific display function on the 
%                          present SLE study
%                          - Logical
%                          default : false
%
%    H = UQ_DISPLAY_UQ_INVERSION_SLE(...) returns an array of figure handles
%                          
% See also: UQ_POSTPROCESSINVERSIONSLE

%% CONSISTENCY CHECKS
if ~strcmp(module.Type, 'uq_inversion')
   fprintf('uq_display_uq_inversion only operates on objects of type ''Inversion''') 
end

%check if SLE Solver
if or(~strcmp(module.Internal.Solver.Type, 'SLE'),isempty(module.Results))
    error('Only works on SLE-based results')
end

%% INITIALIZE
% Check which post processed arrays are available
if isfield(module.Results,'PostProc')
    if isfield(module.Results.PostProc,'Evidence')
        evidence_avail = true;
        evidence = module.Results.PostProc.Evidence(end);
    else
        evidence_avail = false;
    end
    
    if isfield(module.Results.PostProc,'Mean')
        mean_avail = true;
    else
        mean_avail = false;
    end
    
    if isfield(module.Results.PostProc,'Covariance')
        covariance_avail = true;
    else
        covariance_avail = false;
    end
    
    if isfield(module.Results.PostProc,'PointEstimate')
        pointEstimate_avail = true;
        pointEstimate = module.Results.PostProc.PointEstimate;
        if isfield(module.Results.PostProc.PointEstimate,'ForwardRun')
            pointEstimatePred_avail = true;
            pointEstimatePred = module.Results.PostProc.PointEstimate.ForwardRun;
        else
            pointEstimatePred_avail = false;
        end
    else
        pointEstimate_avail = false;
        pointEstimatePred_avail = false;
    end
else
    %nothing is available
    evidence_avail = false;
    mean_avail = false;
    covariance_avail = false;
    pointEstimate_avail = false;
end

% get labels for parameters
for ii = 1:length(module.Internal.FullPrior.Marginals)
    currLabel = module.Internal.FullPrior.Marginals(ii).Name;
    % assign to container
    paramLabels{ii} = currLabel;
end

%% Initialize
% initialize figure handle container
H = {};

% extract PCE
myPCE = module.Results.SLE;

% number of dimensions
NDim = length(myPCE.Internal.Input.Marginals);

%% Default behavior
% density plot
Default.densityPlotParams = 1:NDim; % all
Default.plotDensity_flag = true; 
% call PCE display function
Default.displayPCE_flag = false;

%% Check for input arguments
%set optional arguments
if nargin > 1
    % vargin given
    parse_keys = {'densityplot','displaypce'};
    parse_types = {'p','p'};
    % make NAME lower case
    varargin(1:2:end) = lower(varargin(1:2:end));
    [uq_cline, ~] = uq_simple_parser(varargin, parse_keys, parse_types);
else
    % no varargin, use default options
    uq_cline{1} = Default.densityPlotParams;
    uq_cline{2} = Default.displayPCE_flag;
end

% 'densityplot' plots an mDim parameter density plot
if ~strcmp(uq_cline{1}, 'false')
    plotDensity_flag = true;
    if isnumeric(uq_cline{1})
        densityPlotParams = uq_cline{1};
    elseif strcmp(uq_cline{1}, 'all')
        densityPlotParams = 1:NDim;
    elseif strcmp(uq_cline{1}, 'none')
        plotDensity_flag = false;
    else
        error('Wrong value found in densityplot name value pair')
    end
else
    plotDensity_flag = Default.plotDensity_flag;
    densityPlotParams = Default.densityPlotParams;
end

% 'displaypce' forward the SLE object to the PCE display function
if ~strcmp(uq_cline{2}, 'false')
    displayPCE_flag = uq_cline{2};
else
    displayPCE_flag = Default.displayPCE_flag;
end

%% Create the plots
if plotDensity_flag
    % Define custom colors
    priorColor = [0.5 0.7 1.0];
    postColor  = [0.0 0.2 0.6];
    
    % Update scatterplot labels
    paramLabelsScatter = {paramLabels{densityPlotParams}};
    
    % Compute the posterior and prior PDF values
    % Switch between evidence, and no evidencecheck if evidence is available for normalization,
    if evidence_avail
        [X, YPrior, YPosterior] = uq_PCE_evaluate_density(myPCE,...
        'dimensions', densityPlotParams, 'evidence', evidence);
    else
        [X, YPrior, YPosterior] = uq_PCE_evaluate_density(myPCE,...
        'dimensions', densityPlotParams);
    end 
        
    % Prior plot
    % Open a new figure
    H{end+1} = uq_figure('Name','Prior density');
    % Create the densityplot
    uq_scatterDensity(...
        gca, ...
        X, ...
        YPrior, ...
        'Labels', paramLabelsScatter, ...
        'Color', priorColor, ...
        'Limits', [min(X); max(X)], ...
        'Title', 'Prior density');
    
    % Posterior plot
    % Open a new figure
    H{end+1} = uq_figure('Name','Posterior density');
    % Switch between point estimate and no point estimate
    if pointEstimate_avail
        % extract relevant point estimates
        plotPointEstimates.X = {};
        plotPointEstimates.Type = pointEstimate.Type;
        plotPointCollection = [];
        for pp = 1:length(pointEstimate.X)
            plotPointEstimates.X{pp} = pointEstimate.X{pp}(:, densityPlotParams);
            plotPointCollection = [plotPointCollection; plotPointEstimates.X{pp}];
        end
        % compute plot limits
        allPlotPoints = [X; plotPointCollection];
        plotLimits = [min(allPlotPoints); max(allPlotPoints)];
        
        uq_scatterDensity(...
            gca,...
            X,...
            YPosterior,...
            'Labels', paramLabelsScatter,...
            'Color', postColor,...
            'Limits', plotLimits,...
            'Title', 'Posterior density',...
            'Points', plotPointEstimates);
    else
        uq_scatterDensity(...
            gca,...
            X,...
            YPosterior,...
            'Labels', paramLabelsScatter,...
            'Color', postColor,...
            'Limits', [min(X); max(X)],...
            'Title', 'Posterior density');
    end
end

if displayPCE_flag
    % run the standard PCE display command
    h = uq_display(myPCE);
    H(end+1:end+length(h)) = h;
end

end