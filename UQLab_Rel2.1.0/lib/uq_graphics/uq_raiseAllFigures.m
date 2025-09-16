function uq_raiseAllFigures(varargin)
% UQ_RAISEALLFIGURES: raise all the figures in the Matlab desktop

%% Defaults
XYSpacing = [10, 120];
EnableGrow = true;
EnableShrink = true;

%% Command line parsing
% 'XYSpacing' option
sidx = find(strcmpi(varargin,'XYSpacing'),1);
if ~isempty(sidx)
    XYSpacing = varargin{sidx+1};
end

% Only allow figures to shrink
sidx = find(strcmpi(varargin,'Shrink'),1);
if ~isempty(sidx)
    EnableGrow = false;
    EnableShrink = true;
end

% Only allow figures to grow
sidx = find(strcmpi(varargin,'Grow'),1);
if ~isempty(sidx)
    EnableGrow = true;
    EnableShrink = false;
end

% Make figures optimally fill the available screen space
sidx = find(strcmpi(varargin,'Optimize'),1);
if ~isempty(sidx)
    EnableGrow = true;
    EnableShrink = true;
end

%% Retrieve the existing figures
FF = findobj('Type', 'Figure');
% Sort the figures (they are often in descending order)
FF = FF(end:-1:1);
NF = length(FF);
% Return if there are no figures
if ~NF
    return;
end

%% Place the figures smartly if possible
% Retrieve the figure positions in a 2D matrix
Positions = get(FF, 'Position');
if ~iscell(Positions)
    Positions = {Positions};
end
Positions = vertcat(Positions{:});
% Get the widths and heights (the only important quantities)
W = Positions(:,3);
H = Positions(:,4);

% Get the screen resolution
Res = (get(0,'ScreenSize'));
Res = Res([3 4]);

% Now calculate the new coordinates starting from top-left to bottom-right
if EnableGrow
    OF = 0; % overflow: figures are too large w.r.t. the screen
    % Gradually reduce the W and H dimensions (preserving the aspect ratio)
    % until they don't overflow anymore
    while ~OF % keep shrinking until they fit!
        % Try to fit them to the screen
        [NewPos, OF] = uq_NewFigPos(W,H,Res,XYSpacing);

        % Reduce their width and heights if they don't fit
        if ~OF
            W = ceil(W/0.95);
            H = ceil(H/0.95);
        end
    end
end

if EnableShrink
    OF = 1; % overflow: figures are too large w.r.t. the screen
    % Gradually reduce the W and H dimensions (preserving the aspect ratio)
    % until they don't overflow anymore
    while OF % keep shrinking until they fit!
        % Try to fit them to the screen
        [NewPos, OF] = uq_NewFigPos(W,H,Res,XYSpacing);

        % Reduce their width and heights if they don't fit
        if OF
            W = ceil(0.95*W);
            H = ceil(0.95*H);
        end
    end
end

% Now set the newly defined position
for kk = 1:NF
    set(FF(kk), 'Position', NewPos(kk,:));
end

%% Give focus to all the available figures
for kk = 1:NF
    figure(FF(kk))
end


function [NewPos, OF] = uq_NewFigPos(W,H,Res,XYSpacing)
% Initialize arguments
if ~exist('XYSpacing','var')
   XYSpacing = [10 120]; 
end
% Number of figures:
NF = size(W,1);
% Initialize the outputs
NewPos = zeros(NF,4);
OF = 0; % No overflow (initially assume that all figures fit on screen)

% Figure offsets (initialize to top left corner)
XOff = XYSpacing(1);
YOff = Res(2);
CurRow = 1;
% Top left Figure position
NewPos(1,1) = XOff;
NewPos(1,2) = YOff;
NewPos(:,3) = W;
NewPos(:,4) = H;

% Loop over the figures and try to identify the figure rows
for kk = 1:NF
    if NF >1 && XOff+W(kk) > Res(1)
        % Specify which row you are using
        CurRow = CurRow + 1;
        XOff = XYSpacing(1);
    end
    RowIdx(kk) = CurRow;
    NewPos(kk,1) = XOff;
    XOff = XOff + W(kk) + XYSpacing(1);
end

% Now loop over the rows and try to figure the vertical sizes
for kk = 1:CurRow
    CurFigs = RowIdx == kk;
    RowHeight(kk) = max(H(CurFigs));
    YOff = YOff - RowHeight(kk) - XYSpacing(2);
    NewPos(CurFigs,2) = YOff;
    if YOff < 0 % if the Y offset is negative, we are overflowing
        OF = 1;
    end
end
