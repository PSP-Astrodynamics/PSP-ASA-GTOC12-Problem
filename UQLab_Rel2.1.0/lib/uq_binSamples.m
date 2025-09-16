function binEdges = uq_binSamples(X, nBins, strategy, hOverlap)
%UQ_BINSAMPLES bins the a provided 1D-sample according to a certain strategy
%   The provided 1D-sample is binned into a provided number of bins and the
%   bin edges are provided as function output. The bins can have constant
%   width or be quantile based. Additionally, it is possible to have
%   overlap between neighboring bins.
%
%   See also: UQ_BORGONOVO_INDEX, UQ_CONDMOMENTS

%% Initialization

if ~exist('hOverlap','var')
    hOverlap = 0;
end

if ~exist('strategy','var')
    strategy = 'quantile';
end

%% Do the binning

nEdges = nBins+1;

switch strategy
    case 'quantile'
        % All bins get the same number of sample points.
        % This is achieved by using quantiles.
        % The number of quantiles equals the number of bin edges (nBins+1)
        quantiles = linspace(0,1,nEdges);
        
        if hOverlap == 0 %%% for no overlap
            % Get the bin edges with quantiles
            binEdges = quantile(X,quantiles);
            % Ensure all sample points are included with the last edges
            binEdges(end) = binEdges(end) * 1.01;
            
        else %%% there is an overlap between bins
            % Calculate the shift of the edges on each side through overlap
            classWidth = 1/nBins;
            edgeShift = classWidth * 0.5 * hOverlap;
            
            % Define the lower and upper bin edges
            quantilesLow = [0 quantiles(2:(end-1))-edgeShift];
            quantilesUpp = [quantiles(2:(end-1))+edgeShift 1];
            
            binEdges(:,1) = quantile(X,quantilesLow);
            binEdges(:,2) = quantile(X,quantilesUpp);
        end
            
    case 'constant'
        % All bins have the same, constant width.
        % go a bit over the last values to make sure they're included
        constEdges = linspace(min(X)*0.99, max(X)*1.01, nEdges);
        
        if hOverlap == 0 %%% for no overlap
            binEdges = constEdges;
            
        else %%% in case we have overlap between classes (default)
            % Calculate the shift of the egdes on each side through overlap
            classWidth = constEdges(2) - constEdges(1);
            edgeShift = classWidth * 0.5 * hOverlap;
            
            % Define the lower and upper bin edges using the shift
            binEdges(:,1) = [0 constEdges(2:(end-1))-edgeShift];
            binEdges(:,2) = [constEdges(2:(end-1))+edgeShift 1];
        end
        
end

end
