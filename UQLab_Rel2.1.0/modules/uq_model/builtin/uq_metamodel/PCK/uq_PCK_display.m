function H = uq_PCK_display(PCKRGModel, outArray, varargin)
%Plots the mean and variance of a PC-Kriging predictor. Only works for 1- and 
% 2-D inputs.

% number of discretization points for the figures
N1d = 500;
N2d = 80;

% check whether the PC-Kriging model has been calculated
if ~PCKRGModel.Internal.Runtime.isCalculated
    fprintf('PC-Kriging object %s is not yet initialized!\nGiven Configuration Options:', PCKRGModel.Name);
    PCKRGModel.Options
    return;
end

%% parsing the residual command line
% initialization
if nargin > 2
    parse_keys = {'R','nolegend'};
    parse_types = {'f','f'};
    [uq_cline, varargin] = uq_simple_parser(varargin, parse_keys, parse_types);
    
    % 'R' option additionally prints R matrix
    R_flag = strcmp(uq_cline{1}, 'true');
    noLegend_flag = strcmp(uq_cline{2}, 'true');
        
    flagWasSet = R_flag;
else
    flagWasSet = false;
    noLegend_flag = false;
end

%% Create the plots
% initialize figure handle container
H = {};

%% Produce non-default plots if any flag  was set
if flagWasSet
    if R_flag
        for ii = 1:length(outArray)
            current_output = outArray(ii);
            H{end+1} = uq_figure('name',sprintf('Output #%i', current_output));
            imagesc(PCKRGModel.Internal.Kriging(current_output).Internal.Kriging.GP.R );
            xlabel('Column index','FontSize', 14,'Interpreter','latex');
            ylabel('Row index','FontSize', 14,'Interpreter','latex');
            title('R matrix values','Interpreter','latex')
        end
    end
    return
end


%% Produce plot

% Get input dimension
M = PCKRGModel.Internal.Runtime.M;  % Number of inputs
nonConstIdx = PCKRGModel.Internal.Input.nonConst;  % Non-constant indices
constIdx = setdiff(1:M,nonConstIdx);               % Constant indices
nonConst = numel(nonConstIdx);                     % Number of non-constant

switch nonConst
    case 1
        % Get the experimental design points
        X = PCKRGModel.ExpDesign.X;
        Y = PCKRGModel.ExpDesign.Y;
        
        % Define prediction points
        Xmin = min(X(:,nonConstIdx));
        Xmax = max(X(:,nonConstIdx));
        Xval1d = linspace(Xmin, Xmax, N1d)';
        Xval = zeros(N1d,M);
        Xval(:,constIdx) = repmat(X(1,constIdx),N1d,1);
        Xval(:,nonConstIdx) = Xval1d;
        
        % Evaluate prediction points
        [Ymu_KRG, Ysigma_KRG]= uq_evalModel(PCKRGModel,Xval);
        confInterval = 0.05;
        Conf = norminv(1 - 0.5*confInterval, 0, 1 )* sqrt(Ysigma_KRG) ;
        
        for ii = 1:length(outArray)
            Uval = uq_GeneralIsopTransform(...
                Xval1d,...
                PCKRGModel.Internal.Kriging(ii).Internal.Input.Marginals,...
                PCKRGModel.Internal.Kriging(ii).Internal.Input.Copula,...
                PCKRGModel.Internal.AuxSpace.Marginals,...
                PCKRGModel.Internal.AuxSpace.Copula);
            %determine the response of the trend alone (i.e. the PCE model
            %multiplied with coefficients and finally summed)
            tval = PCKRGModel.Internal.Kriging(ii).Internal.Kriging.Trend.Handle(Uval);
            
            % Only plot the mean value if the trend is constant
            if (size(tval,2))>1 || std(tval)
                Ytrend = sum(ones(N1d,1)*PCKRGModel.PCK(ii).beta' .*tval , 2);
            else
                Ytrend = mean(Y(:,ii))*tval;
            end
            % Draw the figure
            legendHandles = [];
            legendTxt = {};
            current_output = outArray(ii);
            H{end+1} = uq_figure('name', sprintf('Output #%i', current_output));
            % NOTE: 'hold on' command in R2014a does not cycle through
            % the color order, so it must be set manually.
            ax = gca;
            colorOrder = get(ax,'ColorOrder');
            h = uq_plotConfidence(Xval(:,nonConstIdx), Ymu_KRG(:,current_output),...
                Conf(:,current_output));
            hold on
            h2 = uq_plot(Xval(:,nonConstIdx), Ytrend, '--', 'Color', colorOrder(2,:));
            legendHandles = [legendHandles;  h(:); h2(:)];
            legendTxt = [legendTxt 'PC-Kriging approximation'];
            legendTxt = [legendTxt '$95$\% confidence interval'];
            legendTxt = [legendTxt 'PC trend in PC-Kriging'];
            h = uq_plot(X(:,nonConstIdx),Y(:,current_output), 'ko');
            legendHandles = [legendHandles; h(:)];
            legendTxt = [legendTxt 'Observations'];
            hold off
            if ~noLegend_flag
               uq_legend(legendHandles,legendTxt)
            end
            xlabel('$\mathrm{X}$')
            ylabel('$\mathrm{Y}$')
        end
        
    case 2
        % Get the experimental design
        X = PCKRGModel.ExpDesign.X;
        X1min = min(X(:,nonConstIdx(1)));
        X1max = max(X(:,nonConstIdx(1)));
        X2min = min(X(:,nonConstIdx(2)));
        X2max = max(X(:,nonConstIdx(2)));
        
        % Compute a regular mesh
        [X1val, X2val] = meshgrid(linspace(X1min, X1max, N2d), ...
            linspace(X2min, X2max, N2d));
        X1val_v = reshape(X1val,[],1);
        X2val_v = reshape(X2val,[],1);
        
        % Evaluate the PC-Kriging model on the mesh points
        Xval = zeros(size(X1val_v,1),M);
        Xval(:,constIdx) = repmat(X(1,constIdx),size(X1val_v,1),1);
        Xval(:,nonConstIdx) = [X1val_v, X2val_v];
        [Ymu_KRG_v, Ysigma_KRG_v] = uq_evalModel(PCKRGModel,Xval);
        
        for ii = 1:length(outArray)
            % Draw the figure
            current_output = outArray(ii);
            H{end+1} = uq_figure('name',sprintf('Output #%i', current_output));
            
            Ymu_KRG = reshape(Ymu_KRG_v(:,outArray(ii)), size(X1val));
            Ysigma_KRG = reshape(Ysigma_KRG_v(:,outArray(ii)), size(X1val));
            caxisMin = min([Ymu_KRG_v(:);Ysigma_KRG_v(:)]);
            caxisMax = max([Ymu_KRG_v(:);Ysigma_KRG_v(:)]);
            
            % Subplot for the prediction mean value
            subplot(1, 2, 1)
            h = pcolor(X1val, X2val, Ymu_KRG);
            set(h, 'EdgeColor', 'none')
            hold on
            uq_formatDefaultAxes(gca);
            uq_plot(X(:,nonConstIdx(1)), X(:,nonConstIdx(2)),...
                'ko', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'none')
            hold off
            axis([X1min X1max X2min X2max])
            
            xlabel(['$\mathrm{X_' num2str(nonConstIdx(1)) '}$'])
            ylabel(['$\mathrm{X_' num2str(nonConstIdx(2)) '}$'])
            title('$\mathrm{\widehat{\mu}_Y}$')
            clim([caxisMin, caxisMax])
            set(gca, 'Box' , 'on', 'Layer', 'top', 'FontSize', 14)
            set(colorbar, 'Visible', 'off')
            
            % Subplot for the prediction variance
            subplot(1, 2, 2)
            h = pcolor(X1val, X2val, abs(Ysigma_KRG));
            set(h, 'EdgeColor', 'none');
            hold on
            uq_formatDefaultAxes(gca);
            uq_plot(X(:,nonConstIdx(1)),X(:,nonConstIdx(2)),...
                'ko', 'MarkerFaceColor','r',...
                'MarkerEdgeColor','none');
            hold off
            axis([X1min X1max X2min X2max])
            
            xlabel(['$\mathrm{X_' num2str(nonConstIdx(1)) '}$'])
            ylabel(['$\mathrm{X_' num2str(nonConstIdx(2)) '}$'])
            title('$\mathrm{\widehat{\sigma}_Y^2}$')
            set(gca, 'Box' , 'on', 'Layer', 'top', 'FontSize', 14)
            clim([caxisMin, caxisMax])
            colorbar
            
        end
    otherwise
        error('Only 1 and 2 dimensional X''s are supported!')
end