function H = uq_sser_display(module, outidx, varargin)
% UQ_SSER_DISPLAY graphically displays the results of an SSER-based
%    reliability analysis.
%
%    UQ_SSER_DISPLAY(MODULE, OUTIDX, NAME, VALUE) allows to choose
%    more advanced plot functions by specifying Name/Value pairs:
%
%       Name               VALUE
%       'history'          Plots the history of the failure probability
%                          and beta for the supplied reliability analysis
%                          - Logical
%                          default : true
%
%       'limitState'       Shows the limit state function approximation.
%                          (For 2D problems only)
%                          - Logical
%                          default : true (if 2D)
%                                    false (otherwise)
%
%       'displaysse'       Runs the SSE-specific display function on the 
%                          present SSER study
%                          - Logical
%                          default : true
%
%    H = UQ_SSER_DISPLAY(...) returns an array of figure handles
%                          
% See also: UQ_DISPLAY_UQ_RELIABILITY

%% CONSISTENCY CHECKS
%check if SSER Solver
if or(~strcmp(module.Options.Method, 'SSER'),isempty(module.Results))
    error('Only works on SSER-based results')
end

% currently only single outidx is supported for SSER
if ~(outidx==1)
    error('SSER currently only supports single outputs')
end

%% Initialize
% extract SSE
mySSE = module.Results.SSER;

%% Default behavior
% history plot
Default.history_flag = true;
% call SSE display function
if length(module.Internal.Input.nonConst) == 2
    Default.displayLimitState_flag = true;
else
    Default.displayLimitState_flag = false;
end

% call SSE display function
Default.displaySSE_flag = true;

%% Check for input arguments
%set optional arguments
if nargin > 1
    % vargin given
    parse_keys = {'history','limitstate','displaysse'};
    parse_types = {'p','p','p'};
    % make NAME lower case
    varargin(1:2:end) = lower(varargin(1:2:end));
    [uq_cline, ~] = uq_simple_parser(varargin, parse_keys, parse_types);
else
    % no varargin, use default options
    uq_cline{1} = Default.history_flag;
    uq_cline{2} = Default.displayLimitState_flag;
    uq_cline{3} = Default.displaySSE_flag;
end

% 'densityplot' plots an mDim parameter density plot
if ~strcmp(uq_cline{1}, 'false')
    history_flag = uq_cline{1};
else
    history_flag = Default.history_flag;
end

% 'limitstate' displays the limit-state function approximation
if ~strcmp(uq_cline{2}, 'false')
    displayLimitState_flag = uq_cline{2};
else
    displayLimitState_flag = Default.displayLimitState_flag;
end
if displayLimitState_flag && length(module.Internal.Input.nonConst) ~= 2
    error('Limit states can only be displayed for 2D analysis.')
end

% 'displaysse' forward the SSLE object to the SSE display function
if ~strcmp(uq_cline{3}, 'false')
    displaySSE_flag = uq_cline{3};
else
    displaySSE_flag = Default.displaySSE_flag;
end

%% Create the plots
% initialize figure handle container
H = {};

%% Convergence plots
if history_flag
    % init
    plotcolor = uq_colorOrder(2);
    
    %% compute experimental design sizes
    maxRef = mySSE.SSE.currRef;
    sampleRef = mySSE.SSE.ExpDesign.ref; 
    ref = 0:maxRef-1;
    NED = nan(maxRef,1);
    for rr = ref
        currNED = sum(sampleRef==rr);
        if rr == 0
            NED(rr+1) = currNED;
        else
            NED(rr+1) = NED(rr)+currNED;
        end
    end
    
    %% extract history results
    HistoryContainer = module.Results.History;
    beta = HistoryContainer.Beta(:,1);
    betaCI = HistoryContainer.Beta(:,2:3);
    Pf = HistoryContainer.Pf(:,1);
    PfCI = HistoryContainer.Pf(:,2:3);
    
    %% plot beta history
    H{end+1} = uq_figure('Name', 'SSER: Beta history');
    ax(1) = subplot(3,1,1:2);
    hold on
    grid on
    
    % plot
    fill_between(ref,betaCI(:,1),betaCI(:,2),plotcolor(1,:),plotcolor(1,:),0.5);
    ssePlot = uq_plot(ref,beta,'Color',plotcolor(1,:));

    % beautify
    uq_legend(ssePlot,{'SSER'},'Interpreter','latex','location','best')
    ylabel('$\beta$','Interpreter','latex')

    % eperimental design size
    ax(2) = subplot(3,1,3);
    grid on
    uq_plot(ref,NED,'Color',plotcolor(1,:))

    % beautify
    uq_SSE_formatDoubleAxes(ax, ref)
    
    %% plot Pf history
    H{end+1} = uq_figure('Name', 'SSER: Failure probability history');
    ax(1) = subplot(3,1,1:2);
    hold on
    grid on
    
    % plot
    fill_between(ref,PfCI(:,1),PfCI(:,2),plotcolor(2,:),plotcolor(2,:),0.5);
    ssePlot = uq_plot(ref,Pf,'Color',plotcolor(2,:));
    
    % beautify
    uq_legend(ssePlot,{'SSER'},'Interpreter','latex','location','best')
    ylabel('$P_f$','Interpreter','latex')

    % eperimental design size
    ax(2) = subplot(3,1,3);
    grid on
    uq_plot(ref,NED,'Color',plotcolor(2,:))
    
    % beautify
    set(ax(1),'YScale','log')
    uq_SSE_formatDoubleAxes(ax, ref)
end

%% Limit-state funtion approximation
if displayLimitState_flag
    % run the uq_limitState function
    h = uq_limitState(module, outidx);
    H(end+1:end+length(h)) = h;
end

%% Forward to SSE display function
if displaySSE_flag
    % run the standard SSE display command
    h = uq_display(mySSE);
    H(end+1:end+length(h)) = h;
end
end

function f = fill_between(x, y1, y2, facecolor, edgecolor, alpha)
% Fill area between values y1 and values y2 with color. The edges of the
% filled area can be specified with their own color and transparency
% 
% Usage: fill_between(x, y1, y2, facecolor, edgecolor, alpha)
%
% INPUT:
% x : array of shape 1 by n or n by 1
% y1 : array of shape 1 by n or n by 1
% y2: array of shape 1 by n or n by 1
% facecolor : char or array
%    color of the filled area. Can be a char, or a numeric triplet (r,g,b), 
%    or a quadruplet 
% edgecolor (optional) : color of the area's edge; Default: as facecolor
% alpha (optional): transparency value. Default: 1 (no transparency)
%
%
% OUTPUT:
% f : the output of the fill routine (see fill).
%
% See also: fill
%
% Author: Emiliano Torre, 12 October 2016

if isnumeric(facecolor) 
    if length(facecolor) == 4
        alpha = facecolor(4);
        facecolor = facecolor(1:3);
        if nargin >= 6
            warning('fill_between: transparency specified twice. facecolor(4) used')
        end
    elseif length(facecolor) ~= 3
        error('fill_between: facecolor must be a triplet of a quadruplet')
    end
elseif nargin <= 5
    alpha = 1; 
end

if nargin <= 4 || isempty(edgecolor) 
    edgecolor = facecolor; 
    edgealpha = alpha;
elseif ischar(edgecolor)
    edgealpha = alpha;
elseif isnumeric(edgecolor)
    if length(edgecolor) == 3
        edgealpha = alpha;
    elseif length(edgecolor) == 4
        edgealpha = edgecolor(4);
        edgecolor = edgecolor(1:3);
    else
        error('fill_between: edgecolor must be a triplet of a quadruplet')
    end
end
        

x = reshape(x, 1, []);
y1 = reshape(y1, 1, []);
y2 = reshape(y2, 1, []);
X=[x,fliplr(x)];                
Y=[y1,fliplr(y2)];    
f=fill(X,Y,facecolor);  
set(f, 'facealpha', alpha);
set(f, 'edgealpha', edgealpha);
set(f, 'edgecolor', edgecolor);

end
