function isSuccess = uq_formatDefaultAxes(ax,varargin)
%UQ_FORMATDEFAULTAXES formats an Axes object following UQLab defaults.
%
%   UQ_FORMATDEFAULTAXES(AX) formats the Axes object AX according to the 
%   UQLab default formatting style.
%
%   UQ_FORMATDEFAULTAXES(..., NAME, VALUE) uses NAME/VALUE pairs to
%   override the defaults. Check <a
%   href="matlab:help uq_getDefaultAxes">uq_getDefaultAxes</a> and <a
%   href="matlab:help uq_getDefaultText">uq_getDefaultText</a> to see which
%   defaults have been set.
%
%   See also UQ_GETDEFAULTAXES, UQ_GETDEFAULTTEXT, UQ_FORMATGRAPHOBJ.

SUCCESS = 1;
%% execute recursively in case of multiple axes
if numel(ax) > 1
    for ii = 1:numel(ax)
        SUCCESS = SUCCESS && uq_formatDefaultAxes(ax(ii),varargin{:});
    end
    return;
end

%% Default Axes properties
DefaultAxes = uq_getDefaultAxes(ax);  % Axes object

%% Format the axes according to the defaults given
passAxes = uq_formatGraphObj(ax, varargin, DefaultAxes);

%% Default Text properties
DefaultText = uq_getDefaultText(ax);  % Text object

%% Get relevant Text objects from an Axes
xLabel = get(ax,'XLabel');
yLabel = get(ax,'YLabel');
zLabel = get(ax,'ZLabel');
pltTtl = get(ax,'title');

%% Format the text according to the defaults given
% XLabel
passXLabel = uq_formatGraphObj(xLabel, varargin, DefaultText);
% YLabel
passYLabel = uq_formatGraphObj(yLabel, varargin, DefaultText);
% ZLabel
passZLabel = uq_formatGraphObj(zLabel, varargin, DefaultText);
% Title
passTitle = uq_formatGraphObj(pltTtl, varargin, DefaultText);

%% Check if the formatting went well
if nargout > 0
    SUCCESS = all([passAxes passXLabel passYLabel passZLabel passTitle]);
end
%drawnow()
if nargout
    isSuccess = SUCCESS;
end
