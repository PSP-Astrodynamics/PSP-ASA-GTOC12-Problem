function H = uq_SVC_display(SVCModel, outArray, varargin)
% UQ_SVC_DISPLAY(SVCMODEL,OUTARRAY,VARARGIN): plot the classes and
% margins specified by the SVC model
% SVCMODEL. Only works for 2-D inputs.
%
% See also: UQ_SVR_DISPLAY, UQ_DISPLAY_UQ_METAMODEL

%% Some internal parameters
% Granularity of the grid in each direction for the 2D plot
granul = 100 ;

%%
% Check that the model has been computed with success
if ~SVCModel.Internal.Runtime.isCalculated
    fprintf('SVC object %s is not yet calculated!\nGiven Configuration Options:', SVCModel.Name);
    SVCModel.Options
    return;
end


%% parse varargin options
% initialization
legend_flag = false;

if nargin > 2
    parse_keys = {'legend'};
    parse_types = {'f', 'f'};
    [uq_cline, varargin] = uq_simple_parser(varargin, parse_keys, parse_types);
    % 'coefficients' option additionally prints the coefficients
    if strcmp(uq_cline{1}, 'true')
        legend_flag = true;
    end
end

%% Create the plots
% initialize figure handle container
H = {};

%% Produce plot
% Get input dimension
M = SVCModel.Internal.Runtime.M;
nonConstIdx = SVCModel.Internal.Runtime.nonConstIdx ;  % Indices of non-constant (all input dimension)
constIdx = setdiff(1:M,nonConstIdx);

if length(nonConstIdx) == 2
    % Get experimental design input
    Xtrain = SVCModel.ExpDesign.X;
    % Define bounds of the plot area
    Xmin = min(Xtrain(:,nonConstIdx));
    Xmax = max(Xtrain(:,nonConstIdx));
    minX1 = floor(Xmin(1));
    maxX1 = ceil(Xmax(1));
    minX2 = floor(Xmin(2));
    maxX2 = ceil(Xmax(2));
    % Define grid on the plot area
    [X1val,X2val] = meshgrid(linspace(minX1,maxX1,granul),...
        linspace(minX2,maxX2,granul));
    % Flatten the curve for SVR evaluation
    X1val_v = reshape(X1val,[],1);
    X2val_v = reshape(X2val,[],1);
    Xval = zeros(size(X1val_v,1),M);
    Xval(:,nonConstIdx(1)) = X1val_v;
    Xval(:,nonConstIdx(2)) = X2val_v;
    Xval(:,constIdx) = repmat(Xtrain(1,constIdx),size(X1val_v,1),1);
    % Evaluate the SVC model
    [Yclass_all,Yval_all] = uq_evalModel(SVCModel,Xval);
    for ii = 1:length(outArray)
        % Get desired output
        current_output = outArray(ii);
        Isv = SVCModel.SVC(current_output).Coefficients.SVidx;
        % Get experimental design output
        Ytrain = SVCModel.ExpDesign.Y(:,current_output);
        % Get support vectors
        Xsv = Xtrain(Isv,:);
        % Current output prediction
        Yval = Yval_all(:,current_output) ;
        % Create grid
        Yval_grid = reshape(Yval', granul, granul);
        
        %% Start plotting
        H{end+1} = uq_figure('Name', sprintf('Output #%i', current_output));
        % NOTE: 'hold on' command in R2014a does not cycle through
        % the color order, so it must be set manually.
        ax = gca;
        colorOrder = get(ax,'ColorOrder');
        % Plot the training sets - except the support vectors that will be
        % added later
        TrnMarker_1 = 'o';
        TrnMarker_2 = 'square';
        TrnMarkersize = 6; 
        TrnLineWidth = 1;
        % Get support vector (is support vector?)
        isSV = zeros(length(Ytrain),1);
        isSV(Isv) = 1;
        % Non-support vectors of the first class
        isSV_1 = ~isSV .* Ytrain > 0;
        % Non-support vectors of the second class
        isSV_2 = ~isSV .* Ytrain < 0;
        h1 = uq_plot(...
            Xtrain(isSV_1,nonConstIdx(1)), Xtrain(isSV_1,nonConstIdx(2)), TrnMarker_1,...
            'MarkerFaceColor', colorOrder(1,:),...
            'Color', colorOrder(1,:));
        hold on
%         set(h1, 'Markersize', TrnMarkersize, 'LineWidth', TrnLineWidth,...
%             'Color', 'blue', 'MarkerFaceColor', 'blue');
        h2 = uq_plot(...
            Xtrain(isSV_2,nonConstIdx(1)), Xtrain(isSV_2,nonConstIdx(2)), TrnMarker_2,...
            'MarkerFaceColor', colorOrder(2,:),...
            'Color', colorOrder(2,:));
%         set(h2, 'Markersize', TrnMarkersize, 'LineWidth', TrnLineWidth,...
%             'Color', 'red', 'MarkerFaceColor', 'red');
        % Mark the support vectors with green diamonds.
        % (The size of each is not anymore computed relatively
        % w.r.t. the SVC coefficient. - Release 1.1.0)
        h = uq_plot(...
            Xsv(:,nonConstIdx(1)), Xsv(:,nonConstIdx(2)), 'd',...
            'MarkerSize', 7,...
            'MarkerFaceColor', colorOrder(3,:),...
            'Color', colorOrder(3,:));
        set(h, 'Color', 'k')
        % Plot separating line : isoline x \in \Xx : M_{svc}(x) == 0
        [c,hs] = contour(...
            X1val, X2val, Yval_grid, [0 0],...
            'k', 'LineWidth', 4);
        % Plot lower margin : isoline x \in \Xx : M_{svc}(x) == -1
        [c,hr] = contour(...
            X1val, X2val, Yval_grid, [-1 -1],...
            '--', 'Color', 'k', 'LineWidth', 2);
        % Plot upper margin : isoline x \in \Xx : M_{svc}(x) == 1
        [c,hb] = contour(...
            X1val, X2val, Yval_grid, [1 1],...
            '--', 'Color', 'k', 'LineWidth', 2);
        % Draw a legend
        if legend_flag
            set(gcf,'Position', [50 50 700 400])
            lg = uq_legend([h(1) h1 h2 hs hr],...
                {'Support vectors' 'Train. set - Cat.1'...
                'Train. set - Cat.2' 'Classifier' 'Margins'});
            set(lg, 'Location', 'eastoutside')
        end
        % Format the resulting plot
        axis([ minX1 maxX1 minX2 maxX2])
        xlabel('$\mathrm{X_1}$')
        ylabel('$\mathrm{X_2}$')
        hold off
    end
else
    if M ~= 2
    error('Only two-dimensional X''s are supported!')
    else
     fprintf('Only two-dimensional X''s are supported. The number of non-constant variables is different from 2\n');   
    end
end

end
