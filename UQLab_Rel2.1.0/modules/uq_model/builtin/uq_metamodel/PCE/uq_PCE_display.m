function  H = uq_PCE_display(PCEModel, outArray, varargin)
% UQ_PCE_DISPLAY(PCMODEL,OUTARRAY,VARARGIN): plot the coefficient spectrum
%     of the PCE in PCMODEL for output components specified in OUTARRAY
%     (default OUTARRAY = 1). Colors and sizes of the circles correspond to 
%     the total degree  of the corresponding polynomials
%
%     H = UQ_PCE_DISPLAY(...) returns an array of figure handles. 
% 
% See also: UQ_KRIGING_DISPLAY, UQ_DISPLAY_UQ_METAMODEL

if ~PCEModel.Internal.Runtime.isCalculated
    fprintf('PCE module %s is not yet initialized!\nGiven Configuration Options:', PCEModel.Name);
    PCEModel.Options
    return;
end

%% Initialize
H={};

%% Plot
for ii = 1:length(outArray)
    Coefs = PCEModel.PCE(outArray(ii)).Coefficients;
    Basis = full(PCEModel.PCE(outArray(ii)).Basis.Indices);
    
    %  Get the non zero coefficients from the sparse storage
    [Indices,~,NNZCoefs] = find(Coefs);   % Indices of non zero coefs and values
    PsiDegrees=sum(Basis,2);     % degrees of all polynomial
    PsiDegrees = PsiDegrees(Indices);      % degrees of non zero terms
    logCoefs=log10(abs(NNZCoefs));          % log-scale of the coefs
    
    % Plot the coefficients
    figureName = sprintf('PCE coefficient spectrum: Output %d',outArray(ii));
    H{end+1} = uq_figure('name', figureName, 'filename', 'PCECoeffSpectrum.fig');
    ax = gca;
    
    % NOTE: 'hold on' command in R2014a does not cycle through
    % the color order, so it must be set manually.
    colorOrder = get(ax,'ColorOrder');
    uq_formatDefaultAxes(ax)
    hold on
%     try
%         MyColors = lines(6);
%     catch me
%         MyColors = jet(6);
%     end

    % Specify legend entries
    LegEntries = {'Mean', '$p=1$', '$p=2$', '$p=3$', '$p>3$'};

    pp = [];
    for k=1:4
        Color_k = find(PsiDegrees==(k-1));    % plot the coefs of polynomials of degre k-1
        pp = [pp ...
                uq_plot(...
                    Indices(Color_k), logCoefs(Color_k), 'o',...
                    'MarkerSize', (15-3*k),...
                    'Color', colorOrder(k,:),...
                    'MarkerFaceColor', colorOrder(k,:), ...
                    'DisplayName', LegEntries{k})];
    end
    Color_k = find(PsiDegrees>3);
    pp = [pp ...
            uq_plot(...
                Indices(Color_k), logCoefs(Color_k), 'o',...
                'MarkerSize', 3,...
                'Color', colorOrder(k+1,:),...
                'MarkerFaceColor', colorOrder(k+1,:), ...
                'DisplayName', LegEntries{end})];
    hold off
    
    % layout and legend
    logCoefRange = max(1,max(logCoefs) - min(logCoefs));
    set(ax,'xlim', [-0.05*length(Coefs),1.05*length(Coefs)]);
    set(ax,'ylim',...
        [min(logCoefs)-0.05*logCoefRange, max(logCoefs)+0.05*logCoefRange]);
    set(ax,'YTickMode','manual');
    set(ax, 'YTick', unique(round(linspace(min(logCoefs),1, 5))));
    
    % Set title and axes labels
    title(sprintf('NNZ coefs: %d',length(PsiDegrees)))
    xlabel('$\alpha$')
    ylabel('$\mathrm{\log_{10}\left(\left|y_{\alpha}\right|\right)}$')

    % Add legend
    uq_legend()

    flag = 1;
end
