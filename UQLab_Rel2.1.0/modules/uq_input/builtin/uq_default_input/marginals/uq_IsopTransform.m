function Y = uq_IsopTransform(X, X_marginals, Y_marginals)
% Y = UQ_ISOPTRANSFORM(X, X_marginals, Y_marginals):
%     Performs an isoprobabilistic transformation of samples from X to Y,
%     where their corresponding marginal distributions are specified in the 
%     structure arrays X_marginals and Y_marginals. The transform does not 
%     change the copula of the observations. 
%
%     To change the copula as well, check uq_GeneralIsopTransform.
%
% See also: UQ_GENERALISOPTRANSFORM

% Raise error if input vector contains nans
if any(isnan(X(:)))
    error('attempting to perform Isoprobabilistic transform of data X with nans.')
end

% Check whether X and Y have the same marginal distributions. First check
% only the first element to avoid the full comparison if they are different
if strcmpi(X_marginals(1).Type,Y_marginals(1).Type) 
    M = length(X_marginals);
    [Xtypes{1:M}] = deal(X_marginals.Type);
    [Ytypes{1:M}] = deal(Y_marginals.Type);
    if all(strcmpi(Xtypes,Ytypes))
        % All the types are the same, check moments
        Xmoments = cell(1,M);
        [Xmoments{:}] = deal(X_marginals(:).Parameters);
        Ymoments = cell(1,M);
        [Ymoments{:}] = deal(Y_marginals(:).Parameters);
        % Handle cases where X or Y is bounded
        Xbounds = cell(1,M);
        Ybounds = cell(1,M);
        if isfield(X_marginals, 'Bounds') 
            [Xbounds{:}] = deal(X_marginals(:).Bounds);
        else
            [Xbounds{:}] = deal([-inf inf]);
        end
        if isfield(Y_marginals, 'Bounds') 
            [Ybounds{:}] = deal(Y_marginals(:).Bounds);
        else
            [Ybounds{:}] = deal([-inf inf]);
        end
        if isequal(Xmoments,Ymoments) && isequal(Xbounds,Ybounds)
            Y = X;
            return;
        end
    end
end

%% Do the isoprobabilistic transformation
cdfx = nan(size(X));
Y = nan(size(X));
for ii = 1 : length(X_marginals)
    % if possible and there are no bounds defined, use a linear transform between Gaussians
    if ~isfield(X_marginals(ii), 'Bounds') && ~isfield(Y_marginals(ii), 'Bounds') && ...
            strcmpi(X_marginals(ii).Type, 'Gaussian') && strcmpi(Y_marginals(ii).Type, 'Gaussian')
        XPar = X_marginals(ii).Parameters;
        YPar = Y_marginals(ii).Parameters;
        Y(:,ii) = YPar(1) + YPar(2)/XPar(2)*(X(:,ii) - XPar(1));
    elseif ~isfield(X_marginals(ii), 'Bounds') && ~isfield(Y_marginals(ii), 'Bounds') && ...
            strcmpi(X_marginals(ii).Type, 'Gamma') && strcmpi(Y_marginals(ii).Type, 'Gamma') && ...
            X_marginals(ii).Parameters(2)==Y_marginals(ii).Parameters(2)
        XPar = X_marginals(ii).Parameters;
        YPar = Y_marginals(ii).Parameters;
        Y(:,ii) = X(:,ii)*XPar(1)/YPar(1);
    else
        % this is the general case (no shortcuts to take)
        if isempty(X_marginals(ii).Type) 
            error('X_marginals(%d).Type is empty!', ii)
        elseif isempty(Y_marginals(ii).Type)
            error('Y_marginals(%d).Type is empty!', ii)
        end
            
        %% Mapping from X to uniform space via X's CDF
        switch lower(X_marginals(ii).Type)
            case 'data'
                % The case 'data' makes sense when *both* X and Y are of
                % type 'data'
                mu = X_marginals(ii).Moments(1); %mean
                stDev = X_marginals(ii).Moments(2); %std. deviation
                cdfx(:,ii) = (X(:,ii) - mu) ./ stDev ;
                % in case of 'data' it is not really a CDF but just a
                % scaled version of the samples in X
            case 'constant'
                %do nothing
            otherwise
                cdfx(:,ii) =  uq_all_cdf(X(:,ii), X_marginals(ii));
        end
                
        %% Mapping from uniform space to Y via Y's inverse CDF
         switch lower(Y_marginals(ii).Type)
            case 'data'
                mu = Y_marginals(ii).Moments(1); %mean
                stDev = Y_marginals(ii).Moments(2); %std. deviation
                Y(:,ii) = stDev.* cdfx(:,ii) + mu ;
            case 'constant'
                Y(:,ii) = Y_marginals(ii).Parameters(1) * ones(size(Y(:,ii))) ;
            otherwise
                Y(:,ii) = uq_all_invcdf(cdfx(:,ii), Y_marginals(ii));
        end
    end
end



