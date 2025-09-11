function [n, edges] = uq_histcounts(X,varargin)
% Backwards compatible (R2014a) version of histcounts function

% Check if the function histcounts is available
if which('histcounts')
    % In this case we can just use the function
    [n, edges] = histcounts(X,varargin{:});
    
else % we cope with the binning ourself
    % What follows is a simplified version of histcounts
    
    % currently used by UQ_BORGONOVO_INDEX are name-value pairs:
    % 'Normalization','probability'   and   'BinLimits',limits
    
    % Parse the input arguments
    [N, M] = size(X);
    
    parse_keys = {'Normalization', 'BinLimits'};
    parse_types = {'p','p'};
    
    [uq_cline, in] = uq_simple_parser(varargin, parse_keys, parse_types);
    if ~isempty(in)
        in = in{1};
    end
    
    % check for Normalization
    if ~strcmpi(uq_cline{1},'false')
        normal_flag = true;
        normaltype = uq_cline{1};
    else
        normal_flag = false;
    end
    % check for BinLimits
    if ~strcmpi(uq_cline{2},'false')
        bLim_flag = true;
        bLim = uq_cline{2};
    else
        bLim_flag = false;
    end
    % check remaining input
    edge_flag = false;
    nbin_flag = false;
    if ~isempty(in) && ~isscalar(in) % given edges
        edge_flag = true;
        if iscolumn(in)
            edges = in.';
        else
            edges = in;
        end
        
    elseif ~isempty(in) && isscalar(in) % given number of bins
        nbin_flag = true;
    else % no info provided
        % no action taken
    end
    
    
    % Set the bin edges
    if ~edge_flag && ~nbin_flag % calculate bin edges with scotts rule
        if bLim_flag
            edges = scottsrule(X,bLim(1),bLim(2));
        else
            edges = scottsrule(X);
        end
        
    elseif nbin_flag % number of bins given
        
        if bLim_flag
            xe = zeros(length(X)+2,1);
            xe(1) = in(1);
            xe(2:end-1) = X;
            xe(end) = in(2);
        else
            xe = X;
        end
        
        span = max(xe) - min(xe);
        binwd = span/in;
        edges = [min(xe) + (0:in-1) * binwd, max(xe)];
        
    end % case of edge_flag needs no treatment, since edges are already set
    
    
    % Now the number of values per bin needs to be determined and possibly
    % normalized
    n = zeros(length(edges)-1,1);
    % count the entries for each bin
    for ii = 1:length(n)
        n(ii) = sum( X > edges(ii) & X <= edges(ii+1) );
    end
    
    % normalize if needed
    if normal_flag % && strcmpi(normaltype,'probability')
        n = n./N;
    end
end

function edges = scottsrule(X,varargin)
    % construct array to be binned
    if nargin > 1
        xc = zeros(length(X)+2,1);
        xc(1) = varargin{1};
        xc(2:end-1) = X;
        xc(end) = varargin{2};
    else
        xc = X;
    end
    % calculate bin width
    binwidth = 3.5*std(xc)/(numel(xc)^(1/3));
    nbins = ceil((max(xc)-min(xc))/binwidth);
    % limit nbins to 2^14;
    if nbins > 65536
        nbins = 65536;
        binwidth = (max(xc)-min(xc))/nbins;
    end
    edges  = [min(xc) + (0:nbins-1) * binwidth, max(xc)];
    
end

end