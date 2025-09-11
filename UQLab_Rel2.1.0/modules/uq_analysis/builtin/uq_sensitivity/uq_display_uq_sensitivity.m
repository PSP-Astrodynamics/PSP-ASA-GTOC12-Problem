function H = uq_display_uq_sensitivity(module, idx,varargin)
% UQ_DISPLAY_UQ_SENSITIVITY(SENSANALYSIS,OUTIDX,VARARGIN): graphically
%     display a summary of the sensitivity results in the SENSANALYSIS
%     object for the output variables specified in OUTIDX (default: OUTIDX=1).
%
% See also: UQ_PRINT_UQ_SENSITIVITY

%% CONSISTENCY CHECKS
if ~strcmp(module.Type, 'uq_sensitivity')
   fprintf('uq_display_uq_sensitivity only operates on objects of type ''Sensitivity''') 
end
outidx = 1;

%% Check for input arguments
if nargin > 1
    if exist('idx','var') % the output components are specified
        outidx = idx;
    end
    
end

%% check the residual command line for cobweb

parse_keys = {'cobweb'};
parse_types = {'f'};

[uq_cline, varargin_cob] = uq_simple_parser(varargin, parse_keys, parse_types);
if strcmpi(uq_cline{1},'true')
    cobweb_flag = true;
else
    cobweb_flag = false;
end

%% Execute the relevant display function depending on the argument

Method = module.Internal.Method;
if cobweb_flag
    H = display_cobweb(module, outidx, varargin_cob);
else
    switch lower(Method)
        case 'correlation'
            H = display_correlation(module, outidx, varargin{:});
        case 'perturbation'
            H = display_perturbation(module, outidx, varargin{:});
        case 'cotter'
            H = display_cotter(module, outidx, varargin{:});
        case 'src'
            H = display_src(module, outidx, varargin{:});
        case 'morris'
            H = display_morris(module, outidx, varargin{:});
        case 'sobol'
            H = display_sobol(module, outidx, varargin{:});
        case 'borgonovo'
            H = display_borgonovo(module, outidx, varargin{:});
        case 'ancova'
            H = display_ancova(module, outidx, varargin{:});
        case 'kucherenko'
            H = display_kucherenko(module, outidx, varargin{:});
        case 'shapley'
            H = display_shapley(module, outidx, varargin{:});
        otherwise
            try eval(sprintf('uq_sensitivity_display_%s(module, outidx, varargin{:});', lower(Method)));
            catch me
                fprintf('The current sensitivity method ''%s'' is not recognized as a printable one.\n', lower(Method));
                display(module);
            end
    end % of    switch lower(Method)
end % of flag checking

%% Correlation method
function H = display_correlation(module, outidx, varargin)
% Collect the relevant information
CorrIDX = module.Results(end).CorrIndices;
RankCorrIDX = module.Results(end).RankCorrIndices;
if isfield(module.Results(end),'VariableNames')
    VarNames = module.Results(end).VariableNames;
else
    for ii = 1:size(CorrIDX,2)
        VarNames{ii} = sprintf('X%d',ii);
    end
end
Cost = module.Results(end).Cost;
% Nice colors
% CMap = [0.9804    0.4863    0.0275; 0.1804    0.2471    0.9804];
M = size(CorrIDX,1);

% initialize figure handle container
H = {};



for oo = outidx
    % Plot the sensitivity
    if length(outidx) > 1
        filename = sprintf('SensitivityCorrelationOutput%d.fig',oo);
        figTitle = sprintf('Sensitivity: Correlation-based indices, output #%d', oo);
    else
        filename = 'SensitivityCorrelation.fig';
        figTitle = 'Sensitivity: Correlation-based indices';
    end
    H{end+1} = uq_figure('filename', filename, 'Name', figTitle);
    uq_bar(1:M, [CorrIDX(:,oo) RankCorrIDX(:,oo)], 1)
    % Create legend
    uq_legend({'linear','rank'})
    % Set labels and title
    set(gca, 'XTick', 1:length(VarNames), 'XTickLabel', VarNames)
    ylabel('$\mathrm{\rho}$')
    if length(outidx) > 1
        title(sprintf('Correlation indices, output #%d',oo))
    else
        title(sprintf('Correlation-based indices'))
    end

end

%% Perturbation method
function H = display_perturbation(module, outidx, varargin)
% Collect the relevant information
Sensitivity = module.Results(end).Sensitivity;
VarNames = module.Results(end).VariableNames;
Cost = module.Results(end).Cost;

% initialize figure handle container
H = {};

for oo = outidx
    if length(outidx) > 1
        filename = sprintf('SensitivityPerturbationOutput%d.fig',oo);
        figTitle = sprintf('Sensitivity: Perturbation-based indices, output #%d', oo);
    else
        filename = 'SensitivityPerturbation.fig';
        figTitle = 'Sensitivity: Perturbation-based indices';
    end
    % Plot the sensitivity
    H{end+1} =  uq_figure('filename', filename, 'Name', figTitle);
    uq_bar(Sensitivity(:,oo))
    % Set axes limits
    ylim([0 1])
    % Set labels and title
    set(gca, 'XTick', 1:length(VarNames), 'XTickLabel', VarNames)
    ylabel('Sensitivity')
    if length(outidx) > 1 
        title(sprintf('Perturbation indices, output #%d',oo))
    else
        title(sprintf('Perturbation-based indices'))
    end
end

%% Cotter method
function H = display_cotter(module, outidx, varargin)
% collect the relevant information
CotterIndices = module.Results(end).CotterIndices;
VarNames = module.Results(end).VariableNames;

% initialize figure handle container
H = {};

for oo = outidx
    if length(outidx) > 1
        filename = sprintf('SensitivityCotterOutput%d.fig',oo);
        figTitle = sprintf('Sensitivity: Cotter indices, output #%d', oo);
    else
        filename = 'SensitivityCotter.fig';
        figTitle = 'Sensitivity: Cotter indices';
    end
    % Plot the sensitivity
    H{end+1} = uq_figure('filename', filename, 'Name', figTitle);
    uq_bar(CotterIndices(:,oo))
    % Set labels and title
    set(gca, 'XTick', 1:length(VarNames), 'XTickLabel', VarNames);
    ylabel('Cotter Index')
    if length(outidx) > 1
        title(sprintf('Cotter indices, ouput #%d',oo))
    else
        title(sprintf('Cotter indices'))
    end
end

%% Standard Regression Coefficients
function H = display_src(module, outidx, varargin)
% collect the relevant information
SRCIDX = module.Results(end).SRCIndices;
SRRCIDX = module.Results(end).SRRCIndices;
VarNames = module.Results(end).VariableNames;
M = size(SRCIDX, 1);

% initialize figure handle container
H = {};

for oo = outidx
    if length(outidx) > 1
        filename = sprintf('SensitivitySRC%d.fig',oo);
        figTitle = sprintf('Sensitivity: SRC, output #%d', oo);
    else
        filename = 'SensitivitySRC.fig';
        figTitle = 'Sensitivity: SRC';
    end    
    % Plot the sensitivity
    H{end+1} = uq_figure('filename', filename, 'Name', figTitle);
    uq_bar(1:M, [SRCIDX(:,oo) SRRCIDX(:,oo)], 1)
    % Set legend
    uq_legend({'SRC', 'SRRC'})
    % Set labels and title
    set(gca, 'XTick', 1:length(VarNames), 'XTickLabel', VarNames)
    ylabel('Sensitivity')
    if length(outidx) > 1
        title(sprintf('SRC results, output #%d',oo))
    else
        title(sprintf('SRC results'))
    end
end

%% Morris method
function H = display_morris(module, outidx, varargin)
% Collect the relevant information
MU = module.Results(end).Mu;
MUStar = module.Results(end).MuStar;
MSTD = module.Results(end).Std;
VarNames = module.Results(end).VariableNames;

% initialize figure handle container
H = {};

for oo = outidx
    
    %% Plot MU
    if length(outidx) > 1
        filename = sprintf('SensitivityMorrisOutput%d.fig',oo);
        figTitle = sprintf('Sensitivity: Morris method, output #%d', oo);
    else
        filename = 'SensitivityMorris.fig';
        figTitle = 'Sensitivity: Morris method';
    end
    H{end+1} = uq_figure('filename', filename, 'Name', figTitle);
    ax = gca;
    uq_formatDefaultAxes(ax)
    cm = uq_colorOrder(length(MU(:,oo))); % use UQLab colormap
    hold on
    for ii = 1:length(MU(:,oo))
        XCoord = MU(ii,oo);
        YCoord = MSTD(ii,oo);
        text(XCoord, YCoord, VarNames{ii},...
            'FontSize', 14,...
            'Color', cm(ii,:),... 
            'FontWeight', 'normal',...
            'Interpreter', 'LaTeX')
    end
    
    minMU = min(MU(:,oo));
    maxMU = max(MU(:,oo));
    minMU = min(minMU - 0.15*abs(maxMU), -0.15*abs(maxMU));
    maxMU = max(maxMU + 0.15*abs(maxMU), 0.15*abs(maxMU));
    
    maxMSTD = max(MSTD(:,oo));
    minMSTD = - 0.15*abs(maxMSTD);
    maxMSTD = maxMSTD + 0.15*abs(maxMSTD);

    % Plot the axes lines
    uq_plot([2*minMU 2*maxMU], [0 0], 'k', 'LineWidth', 2)
    uq_plot([0 0],[2*minMSTD 2*maxMSTD], 'k', 'LineWidth', 2)
    hold off
    
    % Format the axes
    axis([min(minMU, 0-0.1*(minMU)) maxMU minMSTD  maxMSTD])
    
    % Set labels and title
    xlabel('$\mu$')
    ylabel('$\sigma$')
    if length(outidx) > 1
        title(sprintf('Elementary effects, output #%d',oo))
    else
        title(sprintf('Elementary effects'))
    end
    
    %% Plot MU*
    if length(outidx) > 1
        filename = sprintf('SensitivityMorrisMuStarOutput%d.fig',oo);
        figTitle = sprintf('Sensitivity: Morris method, output #%d', oo);
    else
        filename = 'SensitivityMorrisMuStar.fig';
        figTitle = 'Sensitivity: Morris method';
    end
    H{end+1} = uq_figure('filename', filename, 'Name', figTitle);
    ax = gca;
    uq_formatDefaultAxes(ax)
    cm = uq_colorOrder(length(MUStar(:,oo))); % use UQLab colormap
    hold on
    for ii = 1:length(MUStar(:,oo))
        XCoord = MUStar(ii,oo);
        YCoord = MSTD(ii,oo);
        text(XCoord, YCoord, VarNames{ii},...
            'FontSize', 14,...
            'Color', cm(ii,:),...
            'FontWeight', 'normal',...
            'Interpreter', 'LaTeX')
    end
    
    minMUStar = min(MUStar(:,oo));
    maxMUStar = max(MUStar(:,oo));
    minMUStar = min(minMUStar - 0.15*abs(maxMUStar),- 0.15*abs(maxMUStar));
    maxMUStar = max(maxMUStar + 0.15*abs(maxMUStar),0.15*abs(maxMUStar));
    
    maxMSTD = max(MSTD(:,oo));
    minMSTD = -0.15*abs(maxMSTD);
    maxMSTD = maxMSTD + 0.15*abs(maxMSTD);

    % Plot the axis lines
    uq_plot([2*minMUStar 2*maxMUStar], [0 0], 'k', 'LineWidth', 2)
    uq_plot([0 0],[2*minMSTD 2*maxMSTD], 'k', 'LineWidth', 2)
    hold off
    
    % Format the axes
    axis([minMUStar maxMUStar minMSTD  maxMSTD])
    
    % Set labels and title
    xlabel('$\mu^*$')
    ylabel('$\sigma$')
    if length(outidx) > 1
        title(sprintf('Elementary effects, output #%d',oo))
    else
        title(sprintf('Elementary effects'))
    end
end
    
%% Sobol' indices
function H = display_sobol(module, outidx, varargin)
% collect the relevant information
results = module.Results(end);
H = uq_visualizeSobolIndices(results,outidx, varargin{:});

%% Borgonovo indices
function H = display_borgonovo(module, outidx, varargin)
% collect the relevant information
results = module.Results(end);
if isfield(module.Internal.Input,'nonConst') %|| isprop(module.Internal.Input,'nonConst')
    results.VariableNames = results.VariableNames(module.Internal.Input.nonConst);
end
H = uq_visualizeBorgonovoIndices(results,outidx, varargin{:});

%% Shapley indices
function H = display_shapley(module, outidx, varargin)
% collect the relevant information
results = module.Results(end);
H = uq_visualizeShapleyIndices(results,outidx,varargin{:});

%% ANCOVA indices
function H = display_ancova(module, outidx, varargin)
% collect the relevant information
results = module.Results(end);
H = uq_visualizeANCOVAIndices(results,outidx,varargin{:});

%% Kucherenko indices
function H = display_kucherenko(module, outidx, varargin)
% collect the relevant information
results = module.Results(end);
H = uq_visualizeKucherenkoIndices(results,outidx, varargin{:});


%% Cobweb plots
function H = display_cobweb(module, outidx, varargin_cobweb)
% Check if an ExpDesign is given in the Results
AvailableED = isfield(module.Results,'ExpDesign') && ~isempty(module.Results.ExpDesign);
if ~AvailableED
    fprintf('\n\nError: There is no experimental design found in .Results of %s\n',module.Name);
    module
    fprintf('\nIf you have the samples ready you can also directly use the function\n')
    fprintf('UQ_DISPLAY_COBWEB. For more information type "help uq_display_cobweb".\n')
    
    error('Failed while initializing the display function!')
end
% Retrieve the ExpDesign
if strcmpi(module.Internal.Method,'sobol')
    try
        Xsample = module.Results.ExpDesign.Sample1.X;
        Ysample = module.Results.ExpDesign.Sample1.Y(:,outidx);
    catch ME
        fprintf('\n\nError: The experimental design found in .Results of %s\n',module.Name);
        fprintf('is not of the expected format!\n')
        module
        fprintf('\nIf you have the samples ready you can also directly use the function\n')
        fprintf('UQ_DISPLAY_COBWEB. For more information type "help uq_display_cobweb".\n')
        
        error('Failed while initializing the display function!')
    end
else
    try
        Xsample = module.Results.ExpDesign.X;
        Ysample = module.Results.ExpDesign.Y(:,outidx);
    catch ME
        fprintf('\n\nError: The experimental design found in .Results of %s\n',module.Name);
        fprintf('is not of the expected format!\n')
        module
        fprintf('\nIf you have the samples ready you can also directly use the function\n')
        fprintf('UQ_DISPLAY_COBWEB. For more information type "help uq_display_cobweb".\n')
        
        error('Failed while initializing the display function!')
    end
end

% Now that we have the experimental design, let's attempt the plot
try
    H = uq_display_cobweb(Xsample, Ysample, 'DataTags', module.Results.VariableNames, varargin_cobweb{:});
catch ME
    fprintf('\n\nError: Couldn''t produce the cobweb plot! Caught the error:\n')
    ME
    fprintf('\nIf you have the samples ready you can also directly use the function\n')
    fprintf('UQ_DISPLAY_COBWEB. For more information type "help uq_display_cobweb".\n')
    
    error('Failed while initializing the display function!')
end