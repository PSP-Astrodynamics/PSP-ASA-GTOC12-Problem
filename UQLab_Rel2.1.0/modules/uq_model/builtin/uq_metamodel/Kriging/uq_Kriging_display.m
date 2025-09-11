function H = uq_Kriging_display(KRGModel, outArray, varargin)
%UQ_KRIGING_DISPLAY plots the mean and variance of a Kriging predictor.
%
%   UQ_KRIGING_DISPLAY(KRGMODEL) plots the mean and the standard deviation
%   (for 1-dimensional input) or the variance (in 2-dimensional input) of
%   a Kriging predictor specified by the Kriging model KRGMODEL. If there
%   is more than one outputs, only the first output component is plotted.
%   This display function only works for Kriging model with 1- and
%   2-dimensional inputs.
%
%   UQ_KRIGING_DISPLAY(KRGMODEL,OUTARRAY) creates the plots of a Kriging
%   predictor with multiple outputs for the selected output components 
%   given in OUTARRAY.
%
%   UQ_KRIGING_DISPLAY(KRGMODEL,OUTARRAY,'nolegend') creates the plots
%   without legend.
%
%   UQ_KRIGING_DISPLAY(KRGMODEL,OUTARRAY,'R') creates a correlation matrix
%   plot for the selected output components.
%
%   See also UQ_DISPLAY_UQ_METAMODEL.

%% Consistency checks and command line parsing
if ~KRGModel.Internal.Runtime.isCalculated
    fprintf(...
        ['Kriging object %s is not yet initialized!\n',...
        'Given Configuration Options:'],...
        KRGModel.Name);
    KRGModel.Options
    return
end

%% Parse the residual input arguments
if nargin > 2
    parse_keys = {'R','nolegend'};
    parse_types = {'f','f'};
    [uq_cline,~] = uq_simple_parser(varargin, parse_keys, parse_types);

    plotR = strcmp(uq_cline{1},'true');
    noLegend = strcmp(uq_cline{2},'true');
else
    plotR = false;
    noLegend = false;
end

%% Create the plot

if plotR
    H = plot_R(KRGModel,outArray);
else
    H = plot_default(KRGModel, outArray, noLegend);
end

end

%% Helper functions

%% ------------------------------------------------------------------------
function H = plot_R(KRGModel,outArray)
% initialize figure handle container
H = {};

% Create a plot of correlation matrix (R)
for ii = 1:length(outArray)
    current_output = outArray(ii);
    H{end+1} = uq_figure('name',sprintf('Output #%i', current_output));
    imagesc(KRGModel.Internal.Kriging(current_output).GP.R)
    ax = gca;
    uq_formatDefaultAxes(ax)
    xlabel('Column index')
    ylabel('Row index')
    title('R matrix values')
end

end

%% ------------------------------------------------------------------------
function H = plot_default(KRGModel,outArray,noLegend)
% initialize figure handle container
H = {};
% Create the default plot (the mean +/- std. dev.) of Kriging predictor.

N1d = 500;  % Number of points to plot in one-dimension
N2d = 80;   % Number of points to plot in two-dimension

M = KRGModel.Internal.Runtime.M;  % Number of inputs
if isfield(KRGModel.Internal,'Input') && ~isempty(KRGModel.Internal.Input)
    % Only if INPUT is specified in the Kriging object
    nonConstIdx = KRGModel.Internal.Input.nonConst;  % Indices of non-const
    constIdx = setdiff(1:M,nonConstIdx);             % Indices of constant
    nonConst = numel(nonConstIdx);                   % Number of non-const
else
    nonConstIdx = 1:M;  % Indices of non-constant (all input dimension)
    constIdx = [];      % Indices of constant (none)
    nonConst = M;       % Number of non-constant
end

if nonConst == 1
    %% One-dimensional case

    % Compute points to plot
    X = KRGModel.ExpDesign.X;
    Y = KRGModel.ExpDesign.Y;
    % Create new evaluation points only on the non-constant inputs
    Xmin = min(X(:,nonConstIdx));
    Xmax = max(X(:,nonConstIdx));
    Xval = zeros(N1d,M);
    Xval(:,constIdx) = repmat(X(1,constIdx),N1d,1);
    Xval(:,nonConstIdx) = linspace(Xmin, Xmax, N1d)';
    % Make sure that experimental design points belong to the evaluation
    Xval = sort([Xval; X]);
    [Ymu_KRG,Ysigma_KRG]= uq_evalModel(KRGModel,Xval);

    % Compute upper and lower bounds of the confidence interval
    confLevel = 0.95;  % 95% confidendence level
    confInterval = norminv(1-0.5*(1-confLevel), 0, 1) * sqrt(Ysigma_KRG);  
    
    legendTxt = {'Kriging approximation',...
        '$95\%$ confidence interval',...
        'Observations'};

    for ii = 1:length(outArray)
        currentOutput = outArray(ii);
        H{end+1} = uq_figure('name',sprintf('Output #%i',currentOutput));
        % Create a confidence plot (mean + confidence interval)
        h = uq_plotConfidence(...
            Xval(:,nonConstIdx), Ymu_KRG(:,currentOutput),...
            confInterval(:,currentOutput));
        legendHandles = h(:);
        % Put the observation points
        hold on
        h = uq_plot(X(:,nonConstIdx), Y(:,currentOutput),...
            'ko', 'MarkerFaceColor', 'k');
        legendHandles = [legendHandles; h(:)];
        hold off    
        % Customize the plot
        xlim([Xmin Xmax])   % Set axes limits
        xlabel(['$\mathrm{X_' num2str(nonConstIdx(1)) '}$']) % Set x-axis labels
        ylabel('$\mathrm{Y}$')  % Set y-axis labels
        % Add legend
        if ~noLegend
            uq_legend(legendHandles,legendTxt)
        end
    end
        
elseif nonConst == 2
    %% Two-dimensional case

    %% Compute points to plot
    % Create an input grid
    X = KRGModel.ExpDesign.X;
    X1min = min(X(:,nonConstIdx(1)));
    X1max = max(X(:,nonConstIdx(1)));
    X2min = min(X(:,nonConstIdx(2)));
    X2max = max(X(:,nonConstIdx(2)));
    [X1val,X2val] = meshgrid(...
        linspace(X1min, X1max, N2d), linspace(X2min, X2max, N2d));    
    % Flatten the grid for Kriging evaluation
    X1val_v = reshape(X1val, [], 1);
    X2val_v = reshape(X2val, [], 1);
    Xval = zeros(size(X1val_v,1),M);
    Xval(:,nonConstIdx(1)) = X1val_v;
    Xval(:,nonConstIdx(2)) = X2val_v;
    Xval(:,constIdx) = repmat(X(1,constIdx),size(X1val_v,1),1);
    % Evaluate Kriging model at the (flattened) grid
    [Ymu_KRG_v,Ysigma_KRG_v] = uq_evalModel(KRGModel,Xval);
    
    for ii = 1:length(outArray)
        currentOutput = outArray(ii);
        
        % Reshape predictor output for 2D plotting
        Ymu_KRG = reshape(Ymu_KRG_v(:,currentOutput),size(X1val));
        Ysigma_KRG = reshape(Ysigma_KRG_v(:,currentOutput),size(X1val));
        
        %% Plot the Kriging predictor mean in 2D
        H{end+1} = uq_figure('name',sprintf('Output #%i (mean)',currentOutput));
        ax = gca;
        % Format the axes
        uq_formatDefaultAxes(ax)
        hold on
        % Plot Kriging predictor mean (two-dimensional)
        h = pcolor(ax,X1val, X2val, Ymu_KRG);
        set(h, 'EdgeColor', 'none')
        shading interp
        % Put the observation points
        uq_plot(X(:,nonConstIdx(1)), X(:,nonConstIdx(2)), 'ro')
        hold off
        % Customize the plot
        cb = colorbar('Location','eastoutside');  % Add colorbar
        % NOTE: 'TickLabelInterpreter' is only available in R2014b or newer
        if isprop(cb,'TickLabelInterpreter')
            set(cb, 'TickLabelInterpreter', 'latex')
        end
        axis([X1min X1max X2min X2max])           % Set axes
        xlabel(['$\mathrm{X_' num2str(nonConstIdx(1)) '}$']) % Set x-axis labels
        ylabel(['$\mathrm{X_' num2str(nonConstIdx(2)) '}$']) % Set y-axis labels
        title('$\mathrm{\mu_{\widehat{Y}}}$')     % Set title
            
        %% Plot the Kriging predictor variance in 2D
        H{end+1} = uq_figure('name', sprintf('Output #%i (variance)',currentOutput));
        ax = gca;
        % Format the axes
        uq_formatDefaultAxes(ax)
        hold on
        % Plot the predictor variance
        h = pcolor(X1val, X2val, abs(Ysigma_KRG));
        set(h, 'EdgeColor', 'none')
        shading interp
        % Put the observation points
        uq_plot(X(:,nonConstIdx(1)), X(:,nonConstIdx(2)), 'ro')
        hold off
        % Customize the plot
        cb = colorbar('Location','eastoutside');   % Add colorbar
        % NOTE: 'TickLabelInterpreter' is only available in R2014b or newer
        if isprop(cb,'TickLabelInterpreter')
            set(cb, 'TickLabelInterpreter', 'latex')
        end
        axis([X1min X1max X2min X2max])             % Set axis
        xlabel(['$\mathrm{X_' num2str(nonConstIdx(1)) '}$']) % Set x-axis labels
        ylabel(['$\mathrm{X_' num2str(nonConstIdx(2)) '}$']) % Set y-axis labels
        title('$\mathrm{\sigma_{\widehat{Y}}^2}$')  % Add title
    end
else
    error('Only 1 and 2 dimensional X''s are supported!')
end

end
