function lgd = uq_legend(varargin)
%UQ_LEGEND creates a legend following the default formatting of UQLab.
%
%   UQ_LEGEND creates a legend on the current axes following the default
%   formatting of UQLab.
%
%   UQ_LEGEND(...) wraps around the standard MATLAB's <a href="matlab:help
%   legend">legend</a> function
%   and sets the UQLab default formatting styles on the resulting Legend
%   object. The input arguments to UQ_LEGEND conform to the input arguments
%   of the MATLAB function.
%
%   UQ_LEGEND(..., NAME, VALUE) modifies the properties of the legend
%   according to the specified NAME/VALUE pairs. The complete list of the
%   pairs can be found in <a href="matlab:help legend">legend</a> function.
%
%   LGD = UQ_LEGEND(...) returns the Legend object. In MATLAB R2014a or
%   older, the function returns a handle to the legend (which is an Axes
%   object). Use LGD to access and modify the properties of the legend
%   after it has been created.
%
%   See also LEGEND, UQ_FORMATGRAPHOBJ, UQ_GETDEFAULTLEGEND.

%% Get UQLab default properties for legend
DefaultLegend = uq_getDefaultLegend();

%% Create a legend with the specified properties
hh = legend(varargin{:});

%% Get parts of input argument that are Name/Value pairs
if isempty(varargin)
    % legend()
    options = [];
elseif numel(varargin) == 1
    % legend(vsbl), legend(bkgd), legend('off'|'on'),
    % legend({labels}), legend(target)
    options = [];
elseif all(cellfun(@ischar,varargin))
    % legend(label1, label2,..., labelN)
    options = [];
elseif iscell(varargin{1})
    % legend({labels},...)
    options = varargin(2:end);
elseif isobject(varargin{1}) || isnumeric(varargin{1})
    % legend(target,...) NOTE: target might be a numerical value in <R2014b
    if iscell(varargin{2})
        % legend(target, {labels},...)
        options = varargin(3:end);
    elseif numel(varargin{1}) == numel(varargin(2:end))
        % legend(target, label1, label2,..., labelN)
        options = [];
    else
        options = varargin(2:end);
    end
end  

%% Format the legend
% remove varargin arguments from defaults
DefaultFieldNames = fieldnames(DefaultLegend);
for ff = 1:length(DefaultFieldNames)
    idx = strcmpi(DefaultFieldNames{ff},varargin);
    if any(idx)
        % remove from Defaults
        DefaultLegend= rmfield(DefaultLegend, DefaultFieldNames{ff});
    end
end
uq_formatGraphObj(hh, [], DefaultLegend)

%% Return the Legend object handle (if requested)
if nargout > 0
   lgd = hh;
end

end
