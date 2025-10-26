function H = uq_GLaM_display(GLaModel, outArray, varargin)
%UQ_GLAM_DISPLAY plots the median, mean and standard deviation of a GLaM predictor.
%
%   UQ_GLAM_DISPLAY(GLaModel) plots the median and the 2.5%-97.5% quantile
%   (for 1-dimensional input) or the mean and variance (in 2-dimensional input) of
%   a GLaM predictor specified by GLaModel. If there
%   is more than one outputs, only the first output component is plotted.
%   This display function only works for GLaM model with 1- and
%   2-dimensional inputs.
%
%   UQ_GLAM_DISPLAY(KRGMODEL,OUTARRAY) creates the plots of a GLaM
%   predictor with multiple outputs for the selected output components 
%   given in OUTARRAY.
%
%   UQ_GLAM_DISPLAY(KRGMODEL,OUTARRAY,'lambda') plots the lambda's
%   for the selected output components.
%
%   See also UQ_DISPLAY_UQ_METAMODEL.

%% Consistency checks and command line parsing
if ~GLaModel.Internal.Runtime.isCalculated
    fprintf(...
        ['GLaM object %s is not yet initialized!\n',...
        'Given Configuration Options:'],...
        GLaModel.Name);
    GLaModel.Options
    return
end

Nout = GLaModel.Internal.Runtime.Nout;
if ~exist('outArray','var')
    outArray = 1;  % By default, the first output component is plotted
    if Nout > 1
        msg = ['The selected GLaM metamodel has more than 1 output.',...
            ' Only the 1st output will be printed'];
        warning(msg)
        fprintf(...
            ['You can specify the outputs to be ',...
            'displayed with the syntax:\n'])
        fprintf(...
            ['uq_display(GLaModel,OUTARRAY)\n',...
            'where OUTARRAY is the index of desired outputs, ',...
            'e.g. 1:3 for the first three\n\n'])
    end
end

if max(outArray) > Nout
    error('Requested output range is too large!')
end

%% Parse the residual input arguments
if nargin > 2
    parse_keys = {'lambda','noLegend'};
    parse_types = {'f','f'};
    [uq_cline,~] = uq_simple_parser(varargin, parse_keys, parse_types);
    
    plotLam =  strcmp(uq_cline{1},'true');
    noLegend =  strcmp(uq_cline{2},'true');
else
    plotLam = false;
    noLegend = false;
end

%% Create the plot
nonConst = GLaModel.Internal.Runtime.MnonConst;
switch nonConst
    case 1
        H=plot_1D(GLaModel,outArray,plotLam,noLegend);
    case 2
        H=plot_2D(GLaModel,outArray,plotLam,noLegend);
    otherwise
        error("Only 1 and 2 dimensional X's are supported!");
end

end
%% --------------------------- One-dimensional case ---------------------------
function H = plot_1D(GLaModel,outArray,plotLam,noLegend)
% initialize figure handle container
H = {};
% Number of points to plot in one-dimension
N1d = 500;  

% Compute points to plot
X = GLaModel.ExpDesign.X;
Y = GLaModel.ExpDesign.Y;
R = size(Y,3);

% Get Const and nonConst indices
M = GLaModel.Internal.Runtime.M;
nonConstIdx = GLaModel.Internal.Runtime.nonConstIdx;
constIdx = 1:M;
constIdx(nonConstIdx)=[];

% Create new evaluation points only on the non-constant inputs
Xmin = min(X(:,nonConstIdx));
Xmax = max(X(:,nonConstIdx));
Xval = zeros(N1d,M);
Xval(:,constIdx) = repmat(X(1,constIdx),N1d,1);
Xval(:,nonConstIdx) = linspace(Xmin, Xmax, N1d)';

% Make sure that experimental design points belong to the evaluation
Xval = sort([Xval; X]);
lambda = uq_GLaM_evalLambda(GLaModel,Xval);

% plot
if plotLam
    for oo = 1:length(outArray)
        currentOutput = outArray(oo);
        lamoo =  permute(lambda(:,currentOutput,:),[1,3,2]);
        H{end+1} = uq_figure('name',sprintf('Output #%i',currentOutput));
        for ilam = 1:4
            subplot(1,4,ilam);
            h = uq_plot(Xval(:,nonConstIdx),lamoo(:,ilam),'Color', uq_colorOrder(1), 'LineWidth', 2);
            uq_formatDefaultAxes(gca);            
            xlim([Xmin Xmax]);
            
            xlabel(['$\mathrm{X_',num2str(nonConstIdx(1)),'}$'])
            ylabel(['$\mathrm{\lambda_',num2str(ilam),'}$'])
            set(gca, 'Box' , 'on', 'Layer', 'top', 'FontSize', 14)
        end
        set(gcf,'Position', [0 150 1700 400])
    end
else
    legendTxt = {'Median',...
    '$2.5\%-97.5\%$ quantiles',...
    'Observations'};
    for oo = 1:length(outArray)
        currentOutput = outArray(oo);
        H{end+1} = uq_figure('name',sprintf('Output #%i',currentOutput));
        lamoo =  permute(lambda(:,currentOutput,:),[1,3,2]);
        q025 = uq_GLD_quantile(0.025,lamoo);
        median = uq_GLD_quantile(0.5,lamoo);
        q975 = uq_GLD_quantile(0.975,lamoo);
        % Create a confidence plot (mean + confidence interval)
        h=uq_plotConfidence(Xval(:,nonConstIdx), median, [q025,q975]);
        legendHandles = h(:);
        
        % Put the observation points
        xx = X(:,nonConstIdx);
        xx = kron(xx,ones(R,1));
        yy = Y(:,currentOutput,:);
        yy = permute(yy,[3,1,2]);
        yy = yy(:);
        hold on
        h = uq_plot(xx, yy,...
            'ko', 'MarkerFaceColor', 'k','MarkerSize',3);
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
end
end


%% --------------------------- Two-dimensional case ---------------------------
function H = plot_2D(GLaModel,outArray,plotLam,noLegend)
% initialize figure handle container
H = {};
% Number of points to plot in two-dimension
N2d = 80;   

% Get Const and nonConst indices
M = GLaModel.Internal.Runtime.M;
nonConstIdx = GLaModel.Internal.Runtime.nonConstIdx;
constIdx = 1:M;
constIdx(nonConstIdx)=[];

% Create an input grid
X = GLaModel.ExpDesign.X;
X1min = min(X(:,nonConstIdx(1)));
X1max = max(X(:,nonConstIdx(1)));
X2min = min(X(:,nonConstIdx(2)));
X2max = max(X(:,nonConstIdx(2)));
[X1val,X2val] = meshgrid(linspace(X1min, X1max, N2d), linspace(X2min, X2max, N2d));
% Flatten the grid for GLaM evaluation
X1val_v = reshape(X1val, [], 1);
X2val_v = reshape(X2val, [], 1);
Xval = zeros(size(X1val_v,1),M);
Xval(:,nonConstIdx(1)) = X1val_v;
Xval(:,nonConstIdx(2)) = X2val_v;
Xval(:,constIdx) = repmat(X(1,constIdx),size(X1val_v,1),1);
% Evaluate the lambda values at the (flattened) grid
lambda = uq_GLaM_evalLambda(GLaModel,Xval);

if plotLam
    for oo = 1:length(outArray)
        currentOutput = outArray(oo);
        lamoo =  permute(lambda(:,currentOutput,:),[1,3,2]);
        H{end+1} = uq_figure('name',sprintf('Output #%i',currentOutput));
        for ilam = 1:4
            subplot(1,4,ilam);
            YLami = reshape(lamoo(:,ilam), size(X1val));
            h = pcolor(X1val, X2val, YLami);
            set(h, 'EdgeColor', 'none');
            hold on
            uq_formatDefaultAxes(gca);
            uq_plot(X(:,nonConstIdx(1)), X(:,nonConstIdx(2)),...
                'ko', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'none',...
                'MarkerSize',3)
            hold off
            axis([X1min X1max X2min X2max]);
            
            xlabel(['$\mathrm{X_' num2str(nonConstIdx(1)) '}$']);
            ylabel(['$\mathrm{X_' num2str(nonConstIdx(2)) '}$']);
            title(['$\mathrm{\lambda_',num2str(ilam),'}$']);            
            set(gca, 'Box' , 'on', 'Layer', 'top', 'FontSize', 14);
%             caxis([min(lamoo(:,ilam)), max(lamoo(:,ilam))]);
            colorbar;
        end
        set(gcf,'Position', [0 150 1700 400])
    end
else
    for oo = 1:length(outArray)      
        % Draw the figure
        currentOutput = outArray(oo);
        lamoo =  permute(lambda(:,currentOutput,:),[1,3,2]);                
        [Ymu_v,Yvar_v] = uq_GLD_mean_var(lamoo);
        Ysig_v = sqrt(Yvar_v);
        Ymu = reshape(Ymu_v, size(X1val));
        Ysig = reshape(Ysig_v, size(X1val));
        
        H{end+1} = uq_figure('name',sprintf('Output #%i', currentOutput));
        % Subplot for the prediction mean value
        subplot(1, 2, 1)
        h = pcolor(X1val, X2val, Ymu);
        set(h, 'EdgeColor', 'none')
        hold on
        uq_formatDefaultAxes(gca);
        uq_plot(X(:,nonConstIdx(1)), X(:,nonConstIdx(2)),...
            'ko', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'none',...
                'MarkerSize',3)
        hold off
        axis([X1min X1max X2min X2max])
        
        xlabel(['$\mathrm{X_' num2str(nonConstIdx(1)) '}$'])
        ylabel(['$\mathrm{X_' num2str(nonConstIdx(2)) '}$'])
        title('$\mathrm{\widehat{\mu}_{Y_x}}$')        
        set(gca, 'Box' , 'on', 'Layer', 'top', 'FontSize', 14)
%         caxis([min(Ymu_v), max(Ymu_v)])
        colorbar
        
        % Subplot for the prediction variance
        subplot(1, 2, 2)
        h = pcolor(X1val, X2val, Ysig);
        set(h, 'EdgeColor', 'none');
        hold on
        uq_formatDefaultAxes(gca);
        uq_plot(X(:,nonConstIdx(1)),X(:,nonConstIdx(2)),...
            'ko', 'MarkerFaceColor','r',...
            'MarkerEdgeColor','none','MarkerSize',3);
        hold off
        axis([X1min X1max X2min X2max])
        
        xlabel(['$\mathrm{X_' num2str(nonConstIdx(1)) '}$'])
        ylabel(['$\mathrm{X_' num2str(nonConstIdx(2)) '}$'])
        title('$\mathrm{\widehat{\sigma}_{Y_x}}$')
        set(gca, 'Box' , 'on', 'Layer', 'top', 'FontSize', 14)
%         caxis([min(Ysig_v), max(Ysig_v)])
        colorbar
        
        set(gcf,'Position', [50 150 1000 400])
    end
end
end
