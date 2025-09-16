function uq_Reliability_MultiScatter(XX, YY)
% UQ_RELIABILITY_MULTISCATTER Plots reliability results based on their
% signs

% Get dimensionality information
[N,M] = size(XX);
NOut = size(YY,2);


% Get the indices of the plots
idx_F = YY<=0;
idx_S = YY >0;

XS = XX(idx_S,:);
XF = XX(idx_F,:);
YS = YY(idx_S,:);
YF = YY(idx_F,:);

%% Create an MxM 2D matrix of subplots to put all the subplots into
% ratio of the plot area 
AR = 0.95;
AROff = (1-AR)/2;
% width and height of each axis (relative units)
AW = AR/M;
AH = AW;

% now on with the plots, first generate a figure
figure('Position',[100 100 800 800]); 
% now partition it with the axes
AXH = zeros(M);
for ii = 1:M
    for jj = 1:ii
        axpos = [(jj-1)*AW+AROff  1-(ii)*AH-AROff AW AH];
        AXH(ii,jj) = axes('XTick',[],'YTick',[], 'Position',axpos);
        plot(AXH(ii,jj),XS(:,ii),XS(:,jj),'.')
        hold on;
        plot(AXH(ii,jj),XF(:,ii),XF(:,jj),'.r')
        set(AXH(ii,jj),'XTick',[],'YTick',[], 'Position',axpos);
        axis(AXH(ii,jj), 'tight')
    end
end