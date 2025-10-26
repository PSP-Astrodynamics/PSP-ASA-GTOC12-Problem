function logpdf = uq_inversion_lognormpdf(x,mu,cov,discrepancyType)
% UQ_INVERSION_LOGNORMPDF returns the logarithm of a multivariate gaussian
%   pdf. The function distinguishes between different discrepancy types. 
%
%   LOGPDF = UQ_INVERSION_LOGNORMPDF(X, MU, COV, DISCREPANCYTYPE) returns
%   the log of the pdf at X for a multivariate Gaussian distribution
%   with mean MU and covariance matrix COV. DISCREPANCYTYPE defines which 
%   discrepancy type to use.
%   
%   See also: UQ_INVERSION_NORMPDF

% Initialize
[MuRow,~] = size(mu); % get number of realizations and dimension of mean /Data
[XRow,XCol] = size(x); % get number of realizations and dimension of query /modelEvals
[SRow,SCol] = size(cov); % get dimension of sigma

% switch between discrepancy Types
switch lower(discrepancyType)
    case 'scalar'
        % make sure the dimensions are correct
        if SCol~=1
            error('Wrong dimensions in input!')
        end
        % replicate for single value sigma
        if SRow==1; cov = ones(XRow,1)*cov; end
        % evaluate pdf
        logpdf = zeros(XRow,1);
        for ii = 1:MuRow
            %adapt size of vectors
            muCurr = ones(XRow,1)*mu(ii,:);
            logpdf = logpdf - sum(bsxfun(@plus, log(2*pi*cov)/2,...
                bsxfun(@times, 0.5./cov,(x-muCurr).^2)), 2);
        end
    case 'row'
        % make sure the dimensions are correct
        if xor((SCol~=XCol),SCol==1)
            error('Wrong dimensions in input!')
        end
        % replicate for single column sigma
        if SCol==1; cov = cov*ones(1,XCol); end
        % replicate for single value sigma
        if SRow==1; cov = ones(XRow,1)*cov; end
        % evaluate pdf 
        logpdf = zeros(XRow,1);
        for ii = 1:MuRow
            % adapt size of vectors
            muCurr = mu(ii,:);
            for jj = 1:XRow
                U = sqrt(cov(jj,:));
                constant = -XCol*log(2*pi)/2 - sum(log(U));
                Q = ((muCurr-x(jj,:))./U).';
                logpdf(jj) = logpdf(jj) + constant - dot(Q,Q)/2;
            end
        end
    case 'matrix'
        % make sure the dimensions are correct
        if ~((SCol == SRow) && (SCol==XCol))
            error('Wrong dimensions in input!')
        end
        % evaluate pdf
        U = chol(cov);
        constant = -XCol*log(2*pi)/2 - sum(log(diag(U)));
        
        logpdf = zeros(XRow,1);
        for ii = 1:MuRow
            % adapt size of vectors
            muCurr = mu(ii,:);
            for jj = 1:XRow
                Q = U.'\(muCurr-x(jj,:)).'; % solves linear system
                logpdf(jj) = logpdf(jj) + constant - dot(Q,Q)/2;
            end
        end
end