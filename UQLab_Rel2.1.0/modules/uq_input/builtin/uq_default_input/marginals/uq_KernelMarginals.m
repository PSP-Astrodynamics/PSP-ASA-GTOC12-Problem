function Marginals = uq_KernelMarginals(X, bounds, bandwidth)
% Marginals = uq_KernelMarginals(X, bounds, bandwidth)
%     Create a structure that describes the marginal distributions of the
%     data points in X as kernel density estimates. 
%
% INPUT:
% X : matrix of input data. 
%     Each column Xj:=X(:,jj) represents data from input jj, jj=1,...,M.
% (bounds): positive float or M-by-2 array, optional
%     If specified, the marginals are bounded. Can be:
%     * a positive float: called dXj=max(Xj)-min(Xj), each marginal 
%       jj is bounded in [min(Xj) - bounds*dXj, max(Xj)+bounds*dXj].
%     * an M-by-2 array: marginal jj is bounded in bounds(jj,:);
%     * an cell of M elements: marginal jj is bounded in bounds{jj}; 
% (bandwidth): float, cell, or array, optional
%     The Gaussian kernel bandwidth. Can be: 
%     * a positive float: the kernel bandwidth for each dimension
%     * an array/cell of M positive floats: the bandwiths of each dimension
%
% OUTPUT:
% Marginals: struct
%     Structure that describes M marginals obtained by kernel smoothing.
%
% SEE ALSO: uq_StdUniformMarginals, uq_StdNormalMarginals

if nargin <= 2, bandwidth = {}; end;
if nargin == 1, bounds = {}; end;

setBounds = not(isempty(bounds));
setBandwidth = not(isempty(bandwidth));

% Build an array Mx2 with the bounds of each variable, if specified
M = size(X, 2);
if length(bounds) == 1 && bounds >= 0
    deltaX = range(X);
    minData = min(X)-bounds*deltaX;
    maxData = max(X)+bounds*deltaX;
    Bounds = [minData', maxData'];
elseif (isa(bounds, 'float') && all(size(bounds) == [M 2])) || isa(bounds, 'cell')
    Bounds = bounds;
elseif not(isempty(bounds))
    error('bounds must be a positive number, an array Mx2, or a cell')
end
    
% Build an array Mx1 with the kernel bandwidth for each variable, if wanted
if length(bandwidth) == 1 && bandwidth >= 0
    Bandwidth = bandwidth * ones(M, 1);
elseif length(bandwidth) == M
    Bandwidth = bandwidth;
elseif not(isempty(bandwidth)) 
    error(['input variable bandwidth must be a positive number or an' ...
           'array/cell of positive numbers'])
end

for jj = 1:M
    Marginals(jj).Type = 'ks';
    Marginals(jj).Parameters = X(:,jj);
    Marginals(jj).Options.Kernel = 'Normal';
    if setBounds
        if isa(Bounds, 'double') 
            Marginals(jj).Bounds = Bounds(jj, :);
        elseif isa(Bounds, 'cell')
            bd = Bounds{jj};
            if all(size(bd)==[1,2])
                Marginals(jj).Bounds = bd;
            else
                error('uq_KernelInput: bounds{%d} must be a 1x2 array', jj)
            end
        end
    end
    if setBandwidth 
        if isa(Bandwidth, 'double') 
            Marginals(jj).Options.Bandwidth = Bandwidth(jj);
        elseif isa(Bandwidth, 'cell') && all(size(Bandwidth{jj})==1)
            Marginals(jj).Options.Bandwidth = Bandwidth{jj};
        end
    end
end

