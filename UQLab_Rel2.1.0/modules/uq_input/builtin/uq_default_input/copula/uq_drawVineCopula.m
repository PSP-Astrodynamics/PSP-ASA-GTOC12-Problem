function fig = uq_drawVineCopula(Vine, varargin)
% Draw a CVine, either given as a Vine object or as an integer (number of
% nodes. Edges of the vine are drawn as dashed lines if the associated
% copula is the independent one, and as solid lines in all other cases.
%
% UQ_DRAWVINECOPULA(Vine, ...)
% *or*
% UQ_DRAWVINECOPULA(VineType, Structure, ...)
%     Draws a graphical representation of a given vine copula, OR of a vine
%     copula of the given type (e.g. 'DVine' or 'CVine') and structure.
%
%     The drawing consists of one graph per vine tree (conditioning order).
%     Each graph connects the variables coupled by the vine tree with edges
%     representing the pair copulas in the tree.
%
% INPUT:
% Vine : CVine object or integer
%       the vine to draw
% *or* 
% VineType: char
%     the vine type (C- or D-vine) to draw
% Structure: array of doubles
%     the order of the vine nodes. Can be any permutation of [1,2,...,M],
%     where M is the vine dimension (M>=3).
%
% ADDITIONAL OPTIONAL INPUTS:
% uq_drawVineCopula(..., Vararg1, value1, Vararg2, value2, ...) sets
%     additional optional arguments Vararg1, Vararg2, etc. The following
%     optional arguments (case-insensitive) are accepted:
%     'Trees' : int <=20 (Default:20). Number of top trees of the vine to plot 
%     'Detailed':  false (default) or true. If true, writes more information 
%         next to the vine edges, if available
%     'Shape' : '' (Default), 'v', or 'h'. Arrangement of vine trees:
%         square-most, vertical, or horizontal, respectively.
%     'FigSize' : 'auto' (default) or [h, v], figure size in pixels 
%     'FontSize' : int, the font size for axis' text
%     'FontWeight': 'normal' (default) or 'bold'. The font weight
% 
% OUTPUT:
% fig : figure representing the trees of the vine
%
% EXAMPLES:
%
% % Define a 5-dimensional C-vine
% myCVine = uq_VineCopula('CVine', [5 2 3 4 1], ... % vine type and structure
%     {'Gaussian', 'Gaussian', 'Gumbel', 'Gumbel'}, % pair copula families
%     {.5, .6, 1.2, 1}, ...                         % pair copula parameters
%     [0, 90, 270, 180],                            % pair copula rotations
%     1);                                           % vine truncation
%
% % Draw the vine 
% uq_drawVineCopula(myCVine)                        % Default plot
% uq_drawVineCopula(myCVine, 'trees', 1)            % plot only the first tree
% uq_drawVineCopula(myCVine, 'detailed', true)      % add more information
% uq_drawVineCopula(myCVine, 'shape', 'h')          % arrange horizontally

% Interpret mandatory input argument(s): either a structure describing a
% vine copula, or a character (vine type) and an array (order of vine nodes) 
if isa(Vine, 'struct')
    if length(Vine) > 1
       error('Unsupported input vine: Vines cannot be defined as structure arrays with length greater than 1.')  
    end
    VineType = Vine.Type;
    VineStruct = Vine.Structure;
    PCfamilies = Vine.Families;
    PCrots = Vine.Rotations;
    PCparams = Vine.Parameters;
    M = length(VineStruct);
elseif isa(Vine, 'char')
    VineType = Vine;
    if isempty(varargin)
        error('Only vine copula type provided. Please specify the vine structure too')
    end
    VineStruct = varargin{1};
    M = length(VineStruct);
    NrPCs = M*(M-1); % nr. of pair copulas
    PCfamilies = repelem({'na'}, NrPCs);
    PCrots = zeros(1, NrPCs);
    PCparams = nan(1, NrPCs);
    varargin = varargin(2:end);
end

% Define the colors of the edges for the various trees
Colors = [204  153  255;  % violet
        255  178  102;  % light orange
         60  180  113;  % medium sea green
        255  100  100;  % dark pink
        153  204  255;  % light blue
        200  200  200;  % light gray
        100  100  255;  % purple
        100  255  100;  % green-pea green
        150  100   70;  % brown
        255  100  255;  % flash pink
        100  255  255;  % light blue
        200  200  100;  % gold
        255    0    0;  % red
        255    0  127;  % fucsia
        255  128    0;  % dark orange
        153  153  255;  % lilla
          0  110  110;  % dark aquamarine
        255  204  204;  % skin pink
        102  204    0;  % pastel green
        70    70   70]/255;  % dark gray

MaxTrees = size(Colors, 1);

% Define additional optional arguments and assign defaults
DefArgs.detailed = 0;
DefArgs.shape = '';
DefArgs.fontsize = 10;
DefArgs.fontweight = 'normal';
DefArgs.figsize = 'auto';
DefArgs.trees = MaxTrees;

if ~isempty(varargin)
    % Overwrite default argument values with speicifed ones
    VarArgNames = lower(varargin(1:2:end));
    VarArgValues = varargin(2:2:end);
    VarArgs = cell2struct(VarArgValues, VarArgNames, 2);
    VarArgs = uq_overwrite_fields(VarArgs, DefArgs);
else
    % Use default argument values
    VarArgs = DefArgs;
end
    
detailed = VarArgs.detailed;
shape = VarArgs.shape;
fs = VarArgs.fontsize;
fw = VarArgs.fontweight;
figsize = VarArgs.figsize;
NrTrees = min(M-1, VarArgs.trees);

% Extract edges of the vine and reshape into a cell of length M-1 (one 
% element per vine's tree). Each element is an array of egdes (one per row)
RemainingEdges = uq_vine_copula_edges(VineType, VineStruct);
edges = cell(1, M-1);
for ii = 1:M-1
    edges{ii} = reshape([RemainingEdges{1:(M-ii)}], 2, [])'; % edges of tree ii 
    RemainingEdges = RemainingEdges(M-ii+1:end);
end

% Create new figure
%  Prepare the figure title
if strcmpi(VineType, 'cvine') 
    VineTypeStr = 'C-Vine';
elseif strcmpi(VineType, 'dvine') 
    VineTypeStr = 'D-Vine';
else
   % This case is added for completeness. We should never reach this. 
    VineTypeStr = 'Unknown';
end
 
fig_title = sprintf('%s copula visualization, Marginals: %s',...
    VineTypeStr, num2str(Vine.Variables));
if isa(figsize, 'char') && strcmpi(figsize, 'auto')
    fig = uq_figure('Name', fig_title);
else
    fig = uq_figure('Name', fig_title, 'Position', [100*rand(1,2), figsize]);
end
ax = gca(); 
hold on

if strcmpi(VineType, 'cvine')

    xpos = @(x) sin(2*pi*(find(ismember(VineStruct, x)==1)-1)/M); 
    ypos = @(x) cos(2*pi*(find(ismember(VineStruct, x)==1)-1)/M);
    
    % Set the number p of rows/ q of columns for the panels of the plot
    if isequal(shape, '')
        s = floor(sqrt(NrTrees));
        if s*s == M-1
            p = s; q=s;
        elseif s*(s+1) >= NrTrees
            p=s; q=s+1;
        elseif s*(s+2) >= NrTrees
            p=s; q=s+2;
        else
            p=s+1; q=s+2;
        end
    elseif isequal(shape, 'v') || isequal(shape, 'vertical')
        p = M-1;
        q = 1;
    elseif isequal(shape, 'h') || isequal(shape, 'horizontal')
        p = 1;
        q = M-1;
    end
    % Draw all trees
    for tree = 1:NrTrees %M-1
        % Draw the edges of the current tree
        ax = subplot(p, q, tree);
        color = Colors(int32(mod((tree-1), size(Colors, 1)))+1, :);
        w = 1 - .2 * (tree<M) * (M>12); %(tree>10)*
        for ii = 1:size(edges{tree}, 1)
            edge = edges{tree}(ii, :);
            e1 = edge(1); e2=edge(2);
            PCidx = ii+M*(M-1)/2-(M-tree)*(M-tree+1)/2;
            PCfam = PCfamilies{PCidx};
            if strcmpi(PCfam , 'independent')
                linestyle = '-.';
                lw = 1;
            else
                linestyle = '-';
                lw = 2;
            end
            xx = xpos([e1, e2]).*[w, 1];
            yy = ypos([e1, e2]).*[w, 1];
            plot(xx, yy, linestyle, 'LineWidth', lw, 'Color', color);
            if detailed
                str = sprintf('c_{%d,%d}', e1, e2);
                angle = atand(diff(yy)/diff(xx));
                if tree == 2
                    str = [str sprintf('{}_{|%d}', VineStruct(1))];
                elseif tree == 3
                    str = [str sprintf('{}_{|%d,%d}', VineStruct(1:2))];
                elseif tree == 4
                    str = [str sprintf('{}_{|%d,%d,%d}', VineStruct(1:3))];
                elseif tree >= 5
                    str = [str sprintf('{}_{|%d...%d}', VineStruct([1,end]))];
                end

                % Add pair copula name, if available (if not 'na')
                if ~strcmpi(PCfam, 'na') && ~strcmpi(PCfam, 'independent')
                    MaxLetters = 3 + (length(PCfam) == 4);
                    str = [str, ':', PCfam(1:min(length(PCfam), MaxLetters))];
                    % Add pair copula rotation, if not 0
                    if PCrots(PCidx) ~= 0 
                        str = [str, sprintf('%d', PCrots(PCidx))];
                    end
                    % Add parameters
                    PCpars = PCparams{PCidx};
                    PCpar = sprintf('%.2f', PCpars(1));
                    if strcmpi(PCpar(1), '0'), PCpar = PCpar(2:end); end 
                    if strcmpi(PCpar(end), '0'), PCpar = PCpar(1:end-1); end
                    str = [str '(' PCpar];
                    for jj = 2:length(PCpars)             
                        if strcmpi(PCpar(1), '0'), PCpar = PCpar(2:end); end 
                        if strcmpi(PCpar(end), '0'), PCpar = PCpar(1:end-1); end 
                        PCpar = sprintf(',%.2f', PCpars(jj));
                        str = [str PCpar];
                    end
                    str = [str ')'];
                end
                text(mean(xx), mean(yy), str, 'Rotation', angle,...
                     'Color', color, 'HorizontalAlignment', 'center', ...
                     'VerticalAlignment', 'top', 'FontSize', fs, ...
                     'FontWeight', fw);
            end
            hold on
        end
        % Draw the nodes of the current tree
        for ii = 1:M    
            node = VineStruct(ii);
            w = 1 - .2 * (ii==tree) * (tree<M) * (M>12); % (tree>10) * 
            xx = xpos(node) * w; 
            yy = ypos(node) * w;
            % define color2 (dots) and color1 (number inside each dot)
            if ii < tree
                color2=[.4, .4, .4];  % dark gray
            elseif ii == tree
                color2=color;
            else
                color2 = 'k';
            end
            plot(xx, yy, '.', 'Color', color2, ...
                 'MarkerSize', 48); % plot edges                
            text(xx, yy, sprintf('%d', node), 'Color', ...
                 [.99,.99,.99], 'HorizontalAlignment', 'center', ...
                 'FontWeight', 'bold');
        end

        set(ax, 'XLim', [-1.1, 1.1]);
        set(ax, 'YLim', [-1.1, 1.1]);
        set(ax, 'XTick', []);
        set(ax, 'YTick', []);
        set(ax, 'Box', 'off');
        set(gca, 'Visible', 'off');
        h=text(-1.3, 1, sprintf('T_{%d}', tree));
        set(h, 'FontName', 'Arial');
        hold on
    end

    fpos = get(gcf, 'Position');
    dx = .5 + .5 * (q>1); 
    dy = .25; py= 1+.25*(M<6);
    set(gcf, 'Position', [fpos(1), fpos(2), fpos(3)*(dx+max(0, (q-3))/2), ...
        fpos(4)*1.2*py*(dy+max(p-1, 0)/2)]);

elseif strcmpi(VineType, 'dvine')
        % Draw all trees
    for tree = 1 : NrTrees %(M-1)

        if strcmp(shape, '')
            ncol = 1 + (M>=5);
            nrow = ceil((M-1)/ncol);
        elseif strcmp(shape, 'v')
            ncol = 1;
            nrow = M-1;
        elseif strcmp(shape, 'h')
            ncol = M-1;
            nrow = 1;
        end
        y = min(nrow, M-1)-mod(tree-1, nrow);
        x0 = 0 + (M+2)*floor((tree-1)/nrow); 

        % plot edges
        for ii = 1: size(edges{tree}, 1)
            edge = edges{tree}(ii, :);
            e1 = edge(1); e2=edge(2);            % the nodes indices
            nodes_between = VineStruct(e1+1 : e2-1);
            if tree == 0
                X = x0 + [e1+.1, e2-.1];
                Y = [y, y];
                dy = .15;
            else
                dy = (.25+.05*floor((mod(e1, M/2)-1)/2)*(tree>2)) * (-1)^ii;
                X = x0 + [e1 e1+.05 e2-.05 e2];
                Y = y + [0 dy dy 0]; 
            end

            PCidx = ii+M*(M-1)/2-(M-tree)*(M-tree+1)/2;
            PCfam = PCfamilies{PCidx};
            if strcmpi(PCfam , 'independent')
                linestyle = '-.';
                lw = 1;
            else
                linestyle = '-';
                lw = 2;
            end
            color = Colors(tree,:);
            plot(X, Y, linestyle,  'LineWidth', lw, 'Color', color);
            if detailed 
                str = sprintf('c_{%d,%d}', VineStruct(e1), VineStruct(e2));
                if size(nodes_between, 2) == 1
                    str = [str sprintf('{}_{|%d}', nodes_between)];
                elseif size(nodes_between, 2) == 2
                    str = [str sprintf('{}_{|%d,%d}', nodes_between(1), nodes_between(2))];
                elseif size(nodes_between, 2) == 3
                    str = [str sprintf('{}_{|%d,%d,%d}', nodes_between)];
                elseif size(nodes_between, 2) >= 4
                    str = [str sprintf('{}_{|%d...%d}', nodes_between([1,end]))];
                end
                
                % Add pair copula name, if available (if not 'na')
                if ~strcmpi(PCfam, 'na') && ~strcmpi(PCfam, 'independent')
                    MaxLetters = 3 + (length(PCfam) == 4);
                    str = [str, ':', PCfam(1:min(length(PCfam), MaxLetters))];
                    % Add pair copula rotation, if not 0
                    if PCrots(PCidx) ~= 0 
                        str = [str, sprintf('%d', PCrots(PCidx))];
                    end
                    % Add parameters
                    PCpars = PCparams{PCidx};
                    PCpar = sprintf('%.2f', PCpars(1));
                    if strcmpi(PCpar(1), '0'), PCpar = PCpar(2:end); end 
                    if strcmpi(PCpar(end), '0'), PCpar = PCpar(1:end-1); end
                    str = [str '(' PCpar];
                    for jj = 2:length(PCpars)             
                        if strcmpi(PCpar(1), '0'), PCpar = PCpar(2:end); end 
                        if strcmpi(PCpar(end), '0'), PCpar = PCpar(1:end-1); end 
                        PCpar = sprintf(',%.2f', PCpars(jj));
                        str = [str PCpar];
                    end
                    str = [str ')'];
                end

                text(mean(X), mean(Y)+1.1*dy, str, 'Color', color, ...
                     'HorizontalAlignment', 'center', 'VerticalAlignment', ...
                     'middle', 'FontWeight', fw, 'FontSize', fs);
            end
        end
        % plot nodes
        plot(x0+(1:M), ones(M)*y, 'k.', 'MarkerSize', 48); % plot edges
        for ii = 1:M
            text(x0+ii, y, sprintf('%d', VineStruct(ii)), 'Color', .99*ones(1,3), ...
                'HorizontalAlignment', 'center', 'FontWeight', 'bold');
        end
        h = text(x0-.3, y, sprintf('T_{%d}', tree));
        set(h, 'FontName', 'Arial');
    end

    axpos = get(ax, 'Position');
    set(ax, 'Position', [.02, axpos(2)+.0, .96, axpos(4)]);
    set(ax, 'XLim', [.5+1/(M+1), x0+M+.5-1/(M+1)]);
    set(ax, 'YLim', [.5, min(nrow, M-1) + .5]);
    set(ax, 'XTick', []);
    set(ax, 'YTick', []);
    set(ax, 'Box', 'off');
    set(ax, 'Visible', 'off');
    fpos = get(gcf, 'Position');
end


