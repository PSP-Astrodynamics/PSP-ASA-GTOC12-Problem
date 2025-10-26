function cobfig = uq_display_cobweb(X, Y, varargin)
% disphand = UQ_DISPLAY_COBWEB(X, Y, varargin) Accepts a set of raw data
% and a set of conditions and produces a 'cobweb' plot. X is an NxM array
% and Y is an Nx1 array. In order to bring different sets of lines to the
% front, use the scroll wheel on the plot.
%
% varargin can consist of the following Name-Value pairs:
%   'YEdge', YEDGES  : YEDGES sets the values of Y where the cobweb lines
%   change color. By default, the color changes at the mean.
%
%   'DataTags', TAGS : TAGS sets the names of the plotted data that will be
%   shown on the X-axis. By default it's X1,X2,...,Y.
%
%
%
% Minimal working example:
% uqlab
% % Data
% N_samp = 150;
% X1 = randn(N_samp,1);
% X2 = randn(N_samp,1);
% X3 = 2.*X2;
% X = [X1 X2 X3];
% Y = X1+X2.^2-3.*X2;
% Mean value to set edges
% Ys = sort(Y);
% Plot
% uq_display_cobweb(X,Y,'YEdge',[Ys(floor(1/4*N_samp)),Ys(N_samp/2),Ys(ceil(3/4*N_samp))])
%


%% Parse varargin

parse_keys = {'DataTags', 'YEdge'};
parse_types = {'p','p'};

[uq_cline, ~] = uq_simple_parser(varargin, parse_keys, parse_types);

% check for data tags
if ~strcmpi(uq_cline{1},'false')
    dataTag_flag = true;
    data_tags = uq_cline{1};
else
    dataTag_flag = false;
end

% check for provided Y edges
if ~strcmpi(uq_cline{2},'false')
    yEdge_flag = true;
    yEdges = uq_cline{2};
else
    yEdge_flag = false;
end



%% Preparation
%%
% Concatenate data
Xall = horzcat(X,Y);

%%
% Assign data_tags if not provided

if ~dataTag_flag
    data_tags = cell(1,size(Xall,2));
    for kk = 1:size(Xall,2)
        data_tags{kk} = sprintf('X_%i',kk);
    end
    data_tags{end} = 'Y';
elseif dataTag_flag && length(data_tags)==size(Xall,2)-1
    data_tagstmp = cell(1,size(Xall,2));
    [data_tagstmp{1:end-1}] = deal(data_tags{:});
    data_tagstmp{end} = 'Y';
    data_tags = data_tagstmp;
elseif dataTag_flag
    fprintf('\n\nError: There are not enough or too many provided DataTags!\n');
    error('While initializing the cobweb plot');
end

%%
% Condition tags...

% if ~exist('cond_tags','var')
%     cond_tags{1} = 'all';
%     for kk = 1:length(cond_fhands)
%         cond_tags{kk+1} = sprintf('c%i',kk);
%     end
% end


%%
% Color scheme
% a nice diverging color scheme from color-brewer:
c1 = ...
 [118,42,131;
  153,112,171;
  194,165,207;
  231,212,232;
  247,247,247;
  217,240,211;
  166,219,160;
  90,174,97;
  27,120,55]/255;

  % another:
c2 = ...
 [251,180,174;
  179,205,227;
  204,235,197;
  222,203,228;
  254,217,166;
  255,255,204;
  229,216,189;
  253,218,236;
  242,242,242]/255;

  % and another addition:
c3 = ...
    [228,26,28
    55,126,184
    77,175,74
    152,78,163
    255,127,0
    255,255,51
    166,86,40
    247,129,191
    153,153,153]/255;

%% Divide data into groups based on conditions

if yEdge_flag && isnumeric(yEdges)
    
    % Add a lower and upper border to the edges
    yBorders = zeros(length(yEdges)+2,1);
    
    switch sign(max(Y))
        case {1 0 -1}
            yBorders(1) = min(Y)-.01*abs(min(Y));
            yBorders(end) = max(Y)+.01*abs(max(Y));
            yBorders(2:end-1) = yEdges;
        otherwise
            fprintf('\n\nError: The output samples might contain complex numbers!\n')
            fprintf('Cobweb plots are only available for real numbers.\n')
            error('While initializing the cobweb plot')
    end
    
    % Create the groups by choosing the indices of fitting samples in Y
    ngroups = length(yEdges)+1;
    ygroup_idx = cell(1,ngroups);
    for gg = 1:ngroups
        ygroup_idx{gg} = Y(:,1)>yBorders(gg) & Y(:,1)<yBorders(gg+1);
    end
    
elseif yEdge_flag && ~isnumeric(yEdges)
    fprintf('\n\nError: YEdges must contain numeric values!\n')
    error('While initializing the cobweb plot');
else
    ngroups = 2;
    ygroup_idx{1} = Y(:,1)>mean(Y(:,1));
    ygroup_idx{2} = Y(:,1)<mean(Y(:,1));
end


%% Normalization
Xall_norm = Xall;

% get the extreme values of each variable
minValue = min(Xall_norm,[],1);

% shift so the minimum of each column is at zero
for ii = 1:size(Xall_norm,2)
    Xall_norm(:,ii) = Xall_norm(:,ii) -  minValue(ii);
end
% squeeze or stretch so the maximum is at one
maxValue =  max(Xall_norm,[],1);
for ii = 1:size(Xall_norm,2)
    Xall_norm(:,ii) = Xall_norm(:,ii) ./ maxValue(ii);
end


%% Plotting
% set the color schemes:
c = uq_colorOrder(ngroups);
fs = 16;
lwidth = 1.5;

% Plot the different groups
cobfig = uq_figure('Name','Cobweb plot','Position',[50 50 500 400]);
h = cell(1,ngroups);
for gg = 1:ngroups
    h{gg} = uq_plot(1:size(Xall_norm,2),Xall_norm(ygroup_idx{gg},:),'Color',c(gg,:),'Linewidth',lwidth); hold on
end
xlim([1 size(Xall_norm,2)])
ylim([0 1]);
uq_setInterpreters(gca)
set(cobfig.CurrentAxes,'xtick',1:size(Xall_norm,2),'xticklabel',[],...
    'yticklabel',[],'fontsize', fs)
set(gca,'LineWidth',2)

% Build the variable lines and values
% Remove ticks
set(gca, 'TickLength',[0 0])
for ii = 1:size(Xall_norm,2)
    uq_plot([ii ii],[0 1],'Color','k','LineWidth',2);
    % and build scales
%     buildScale(ii,Xall)
    % write min and max values
    ticksize = 12;
    text(ii,0,sprintf('%.2e',min(Xall(:,ii))),'HorizontalAlignment','center','VerticalAlignment','top','FontSize',ticksize, 'Interpreter', 'Latex');
    text(ii,1,sprintf('%.2e',max(Xall(:,ii))),'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',ticksize, 'Interpreter', 'Latex');
    text(ii,-0.045,sprintf('$\\mathrm{%s}$',data_tags{ii}),'HorizontalAlignment','center','VerticalAlignment','top','FontSize',ticksize+2, 'Interpreter', 'Latex');
end

% Enable scrolling through data
hi = ngroups;
set(gcf,'WindowScrollWheelFcn',@doScroll)
grid off
hold off


%% Special effects
% Scroll wheel function
function doScroll(~,e)
    if e.VerticalScrollCount > 0
        hi = hi+1;
        if hi > ngroups
            hi = ngroups;
        end
        uistack(h{hi},'top');
    elseif e.VerticalScrollCount < 0
        hi = hi-1;
        if hi < 1
            hi = 1;
        end
        uistack(h{hi},'top');
    end
end

% Scales on vertical axes
% function buildScale(ii,allvals)
%     % number of ticks
%     nticks = 5;
%     % variable tick values
%     tickvals = linspace(min(allvals(:,ii)),max(allvals(:,ii)),nticks);
%     % tick heights
%     tickhgt = linspace(0,1,nticks);
%     % tick line length
%     tickl = 0.05;
%     
%     ticksize = 14;
%     for nn = 1:nticks
%         if ii == 1
%             uq_plot([ii ii+tickl],[tickhgt(nn) tickhgt(nn)],'Color','k','LineWidth',2); hold on
%             text(ii,tickhgt(nn),sprintf('%f',tickvals(nn)),'HorizontalAlignment','right','FontSize',ticksize)
%         elseif ii == size(allvals,2)
%             uq_plot([ii-tickl ii],[tickhgt(nn) tickhgt(nn)],'Color','k','LineWidth',2); hold on
%             text(ii,tickhgt(nn),sprintf('%d',tickvals(nn)),'FontSize',ticksize)
%         else
%             uq_plot([ii-tickl ii],[tickhgt(nn) tickhgt(nn)],'Color','k','LineWidth',2); hold on
%             text(ii,tickhgt(nn),sprintf('%d',tickvals(nn)),'HorizontalAlignment','right','FontSize',ticksize)
%         end
%     end
% end

end