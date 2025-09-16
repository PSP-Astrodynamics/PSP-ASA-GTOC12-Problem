function H = uq_LRA_display(LRAModel, outArray, varargin)
% H = uq_LRA_display(LRAModel, outArray, varargin)
% 
% This is implemented in the same manner as uq_PCE_display.
%
% Plot the log of the basis coefficients as a function of the number in the
% enumerated Psi_basis multiplied by the normalization factors for
% different ranks.
% 
% Colors and size of the circles correspond to the total degree of the
% corresponding polynomials

if ~LRAModel.Internal.Runtime.isCalculated
    fprintf('LRA module %s is not yet initialized!\nGiven Configuration Options:', LRAModel.Name);
    LRAModel.Options
    return;
end

%% Create the plots
% initialize figure handle container
H = {};

%% Simply plot the true vs reconstructed experimental design
for ii = 1:length(outArray)
    oo = outArray(ii);
    X = LRAModel.ExpDesign.X;
    Y = LRAModel.ExpDesign.Y;
    YLRA = uq_evalModel(LRAModel, X);
    H{end+1} = uq_figure('name', sprintf('Output #%i', oo));
    uq_plot(Y(:,oo),YLRA(:,oo),'+')
    axis equal tight
    hold on
    % plot a diagonal dashed line on top of the scatter plot
    XL = xlim;
    YL = ylim;
    minXY = min([XL(:); YL(:)]);
    maxXY = max([XL(:); YL(:)]);
    uq_plot([minXY maxXY],[minXY maxXY], '--','Color', [0.5 0.5 0.5])
    % Set title and label
    title(sprintf('LRA: ED fit for output %d',oo))
    xlabel('$\mathrm{Y_{ED}}$')
    ylabel('$\mathrm{Y_{LRA}}$')
end
