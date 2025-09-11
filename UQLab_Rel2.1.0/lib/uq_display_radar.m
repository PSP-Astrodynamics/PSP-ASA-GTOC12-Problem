function radfig = uq_display_radar(S, varargin)
% disphand = UQ_DISPLAY_RADAR(S, varargin) Accepts set of values and a
% set of conditions and produces a 'radar' plot. S is an (MxP)-array where
% the values in each row correspond to the same variable and each row
% contains one set of values for each variable. (For Sobol' indices that
% would be [S_i S_i^T], where S_i & S_i^T are (Mx1)-arrays each.)
%
%
% varargin can consist of the following Name-Value pairs:
%   'VariableTags', VTAGS : VTAGS is an (Mx1)-array with the variable names
%   'MeasureTags',  MTAGS : MTAGS is an (1xP)-array with the measure names
%   'noZeros', L          : L is a logical deciding if Values smaller than
%                           10% of the maxmimum value in S should be
%                           ignored. This can improve the readability.
%                           Default: L=1.
%
%
%
% Minimal working example:
% % Data (Sobol' indices of borehole function)
% uqlab
% s1 = [0.6691 0.0046 0.0046 0.0925 0.0046 0.0901 0.0961 0.0282];
% st = [0.6890 0.0000 0.0000 0.1025 0.0000 0.0989 0.0994 0.0245];
% S1andt = [s1' st'];
% % Plot
% uq_display_radar(S1andt,'MeasureTags',{'S_1','S^T'})
%


%% Setup and parse varargin

M = size(S,1);
P = size(S,2);
margin = 0.1*max(max(S));

parse_keys = {'VariableTags','MeasureTags','noZeros'};
parse_types = {'p','p','p'};

[uq_cline, ~] = uq_simple_parser(varargin, parse_keys, parse_types);

% check for variable tags
if ~strcmpi(uq_cline{1},'false')
    vTag_flag = true;
    vTags = uq_cline{1};
else
    vTag_flag = false;
end
% check for measure tags
if ~strcmpi(uq_cline{2},'false')
    mTag_flag = true;
    mTags = uq_cline{2};
else
    mTag_flag = false;
end
% check for noZeros
if ~strcmpi(uq_cline{3},'false')
    n0_flag = uq_cline{3};
else
    n0_flag = false;
end

%% Preparation

%% Do stuff based on the flags
% Assign variable tags if not provided
if ~vTag_flag
    vTags = cell(1,M);
    for ii = 1:M
        vTags{ii} = sprintf('X%i',ii);
    end
elseif vTag_flag && length(vTags)~=M
    fprintf('\n\nError: There are not enough or too many provided variable tags!\n');
    error('While initializing the radar plot');
end

% Assign measure tags if not provided
if ~mTag_flag
    mTags = cell(1,P);
    for pp = 1:P
        mTags{pp} = sprintf('Measure %d',pp);
    end
elseif mTag_flag && length(mTags)~=P
    fprintf('\n\nError: There are not enough or too many provided measure tags!\n');
    error('While initializing the radar plot');
end

% Do not display values smaller than the margin (10% of max value)
if n0_flag
    % only look at the minimal values per row
    minS = min(S,[],2);
    % search for small values
    zero_idx = minS<margin;
    % find the rows
    % take those rows out
    S(zero_idx,:) = [];
else
    zero_idx = zeros(M,1);
end
% Amount of displayed variables
Mdisp = sum(~zero_idx);

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


%% Plotting
% set the color schemes:
c = c3;
fs = 16;
lwidth = 1.5;
thick_deg = linspace(0,360,Mdisp+1);
thick = deg2rad(thick_deg);

labels = cell(Mdisp,1);
lp = 1;
for ii = 1:M
    if ~zero_idx(ii)
        labels{lp} = vTags{ii};
        lp = lp+1;
    end
end

% Create a polar plot
radfig = uq_figure('Name','Radar plot','Position',[50 50 500 400]);
pax = polaraxes;
polaraxes(pax)
% Some setting
set(pax,'ThetaDir','clockwise','ThetaZeroLocation','top');
set(pax,'ThetaTick',thick_deg,'ThetaTickLabel',labels);
% set(pax,'RLim',[0 1]);
set(pax,'Fontsize',fs);
hold on
% Now plot the different measures
h = cell(1,P);
for pp = 1:P
    h{pp} = polarplot(thick,[S(:,pp);S(1,pp)],'Color',c(pp,:));
end
end