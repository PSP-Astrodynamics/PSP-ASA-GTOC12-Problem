function H = uq_visualizeBorgonovoIndices(Results, Outputs, varargin)
%UQ_VISUALIZEBORGONOVOINDICES creates visualizations of the Borgonovo indices.
%
%   UQ_VISUALIZEBORGONOVOINDICES(RESULTS) creates a bar plot of the
%   Borgonovo indices for all the input variables. If the model has
%   multiple outputs, then by default only the Borgonovo indices with
%   respect to the first output is shown.
%
%   uq_VISUALIZEBORGONOVOINDICES(RESULTS,OUTPUTS) creates bar plots of the 
%   Borgonovo indices with respect to the requested output indices given in 
%   the OUTPUTS vector.
%
%   uq_VISUALIZEBORGONOVOINDICES(RESULTS, OUTPUTS, 'Joint PDF', INPUTS)
%   creates a visualization of the estimate of the joint distribution
%   between OUTPUTS and INPUTS.
%
% See also UQ_DISPLAY_UQ_SENSITIVITY.

%% Common options for the Borgonovo Indices Plots
GlobalOptions.NIndices = 10;     % max. number of indices to plot
GlobalOptions.YTicks = 0:0.2:1;  % ticks of y-axis in plots

myColors = uq_colorOrder(1);

%% Parse varargin options

joint_flag = false;

if nargin > 2
    parse_keys = {'Joint PDF'};
    parse_types = {'p'};
    [uq_cline,~] = uq_simple_parser(varargin, parse_keys, parse_types);

    % Check if a visualization of the estimate of the joint distribution
    % is requested:
    if strcmp(uq_cline{1},'false')
        error('Unknown named argument!')
    else
        joint_flag = true;
        joint_to_vis = uq_cline{1};
    end

end

%% Parse Input Arguments

% Default output component (the first)
if ~exist('Outputs','var') || isempty(Outputs)
    Outputs = 1;
end

%% Produce plot(s)
% initialize figure handle container
H = {};

% Check how many outputs are there:
NOuts = length(Outputs);

for oo = Outputs

    % Get the number of indices
    NumOfIndices = length(Results.Delta(:,oo));
    if NOuts > 1
        OutputTag = sprintf(', output #%d',oo);
        figTitle = sprintf('Borgonovo indices%s', OutputTag);
        pltTitle = sprintf('Borgonovo indices (output %d)',oo);
    else
        figTitle = 'Borgonovo indices';
        pltTitle = 'Borgonovo indices';
    end
    
    % Plot the Borgonovo indices
    if ~joint_flag
        H{end+1} = uq_figure('Name', figTitle);
        % Create the bar plot
        x = 1:NumOfIndices;
        uq_bar(x, Results.Delta(:,oo), 'FaceColor', myColors(1,:))
        % Set title and axis labels
        ax = gca;
        title(pltTitle)
        ylabel('$\mathrm{\delta_i}$')
        XTicks = ceil(...
            linspace(...
                1,...
                NumOfIndices, ...
                min(NumOfIndices,GlobalOptions.NIndices)));
        TickNames = Results.VariableNames(XTicks);
        set(...
            ax,...
            'XTick', XTicks,...
            'XTickLabel', TickNames,...
            'YTick', GlobalOptions.YTicks)
        % Set axis limits
        NumOfIndices = length(Results.Delta(:,oo));
        ylim([0 1])
        xlim([0, NumOfIndices + 1]);
    else
        % Creates a visualization of the joint pdf used as it was used in 
        % the computation:
        H = show_conditionalPDFestimates(Results, oo, joint_to_vis);
    end

end

end

%% ------------------------------------------------------------------------
function H = show_conditionalPDFestimates(Results, oo, idx)

if isnumeric(idx) && ...
        max(idx)>length(Results.Delta(:,oo))
    error('The requested variable index does not exist in the model!');
end

if strcmpi(idx,'all')
    idx = 1:length(Results.Delta(:,oo));
end

% initialize figure handle container
H = {};

for ii = idx
    try
        H{end+1} = uq_figure(...
            'Name',...
            sprintf('Joint Pdf Y%d|%s', oo, Results.VariableNames{ii}));
    catch
        H{end+1} = uq_figure();
    end
    pdfplot = pcolor(Results.JointPDF{ii,oo}');
    set(pdfplot, 'EdgeColor', 'none')
    shading flat
    % Format axes
    ax = gca;
    uq_formatDefaultAxes(ax)
    % Set labels
    xlabel(sprintf('%s',Results.VariableNames{ii}))
    ylabel(sprintf('$Y_%d$',oo))
end

end
