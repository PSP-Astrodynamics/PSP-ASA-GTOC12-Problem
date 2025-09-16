function H = uq_SPCE_display(SPCEModel, outArray, varargin)
%UQ_GLAM_DISPLAY plots the mean and standard deviation of a SPCE predictor.
%
%   UQ_SPCE_DISPLAY(GLaModel) plots the mean and the the area plus/minus 2
%   standard deviation (for 1-dimensional input) 
%   or the mean and standard deviation (in 2-dimensional input) of
%   a SPCE predictor specified by GLaModel. If there
%   is more than one outputs, only the first output component is plotted.
%   This display function only works for SPCE model with 1- and
%   2-dimensional inputs.
%
%   UQ_SPCE_DISPLAY(GLaModel,OUTARRAY) creates the plots of a SPCE
%   predictor with multiple outputs for the selected output components 
%   given in OUTARRAY.
%
%   See also UQ_DISPLAY_UQ_METAMODEL.

%% Consistency checks and command line parsing
if ~SPCEModel.Internal.Runtime.isCalculated
    fprintf(...
        ['SPCE object %s is not yet initialized!\n',...
        'Given Configuration Options:'],...
        SPCEModel.Name);
    SPCEModel.Options
    return
end

Nout = SPCEModel.Internal.Runtime.Nout;
if ~exist('outArray','var')
    outArray = 1;  % By default, the first output component is plotted
    if Nout > 1
        msg = ['The selected SPCE metamodel has more than 1 output.',...
            ' Only the 1st output will be printed'];
        warning(msg)
        fprintf(...
            ['You can specify the outputs to be ',...
            'displayed with the syntax:\n'])
        fprintf(...
            ['uq_display(SPCEModel,OUTARRAY)\n',...
            'where OUTARRAY is the index of desired outputs, ',...
            'e.g. 1:3 for the first three\n\n'])
    end
end

if max(outArray) > Nout
    error('Requested output range is too large!')
end

%% Parse the residual input arguments
if nargin > 2
    parse_keys = {'noLegend'};
    parse_types = {'f'};
    [uq_cline,~] = uq_simple_parser(varargin, parse_keys, parse_types);
    
    noLegend =  strcmp(uq_cline{1},'true');
else
    noLegend = false;
end

%% Create the plot
nonConst = SPCEModel.Internal.Runtime.MnonConst;
switch nonConst
    case 1
        H=plot_1D(SPCEModel,outArray,noLegend);
    case 2
        H=plot_2D(SPCEModel,outArray,noLegend);
    otherwise
        error("Only 1 and 2 dimensional X's are supported!");
end

end
%% --------------------------- One-dimensional case ---------------------------
function H = plot_1D(SPCEModel,outArray,noLegend)
% initialize figure handle container
H = {};
% Number of points to plot in one-dimension
N1d = 500;  

% Compute points to plot
X = SPCEModel.ExpDesign.X;
Y = SPCEModel.ExpDesign.Y;
R = size(Y,3);

% Get Const and nonConst indices
M = SPCEModel.Internal.Runtime.M;
nonConstIdx = SPCEModel.Internal.Runtime.nonConstIdx;
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
[~,Ymu,Ystd]= uq_evalModel(SPCEModel,Xval);

% plot

legendTxt = {'Mean',...
    '$\mu\pm 2\sigma$',...
    'Observations'};
for oo = 1:length(outArray)
    currentOutput = outArray(oo);
    H{end+1} = uq_figure('name',sprintf('Output #%i',currentOutput));
    
    % Create a confidence plot (mean + confidence interval)
    h=uq_plotConfidence(Xval(:,nonConstIdx), Ymu(:,oo), Ymu(:,oo)+[-2*Ystd(:,oo),2*Ystd(:,oo)]);
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


%% --------------------------- Two-dimensional case ---------------------------
function H = plot_2D(SPCEModel,outArray,noLegend)
% initialize figure handle container
H = {};
% Number of points to plot in two-dimension
N2d = 80;   

% Get Const and nonConst indices
M = SPCEModel.Internal.Runtime.M;
nonConstIdx = SPCEModel.Internal.Runtime.nonConstIdx;
constIdx = 1:M;
constIdx(nonConstIdx)=[];

% Create an input grid
X = SPCEModel.ExpDesign.X;
X1min = min(X(:,nonConstIdx(1)));
X1max = max(X(:,nonConstIdx(1)));
X2min = min(X(:,nonConstIdx(2)));
X2max = max(X(:,nonConstIdx(2)));
[X1val,X2val] = meshgrid(linspace(X1min, X1max, N2d), linspace(X2min, X2max, N2d));
% Flatten the grid for SPCE evaluation
X1val_v = reshape(X1val, [], 1);
X2val_v = reshape(X2val, [], 1);
Xval = zeros(size(X1val_v,1),M);
Xval(:,nonConstIdx(1)) = X1val_v;
Xval(:,nonConstIdx(2)) = X2val_v;
Xval(:,constIdx) = repmat(X(1,constIdx),size(X1val_v,1),1);
% Evaluate SPCE model at the (flattened) grid
[~,Ymu,Ystd]= uq_evalModel(SPCEModel,Xval);

for oo = 1:length(outArray)
    % Draw the figure
    currentOutput = outArray(oo);
      
    H{end+1} = uq_figure('name',sprintf('Output #%i', currentOutput));
    % Subplot for the prediction mean value
    subplot(1, 2, 1)
    h = pcolor(X1val, X2val, reshape(Ymu(:,oo),size(X1val)));
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
    h = pcolor(X1val, X2val, reshape(Ystd(:,oo),size(X1val)));
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

