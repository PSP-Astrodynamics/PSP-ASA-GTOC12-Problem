function pdf = uq_inversion_normpdf(x,mu,cov,discrepancyType)
% UQ_INVERSION_NORMPDF returns the multivariate Gaussian pdf. The function 
%   distinguishes between different discrepancy types. 
%
%   LOGPDF = UQ_INVERSION_NORMPDF(X, MU, COV, DISCREPANCYTYPE) returns the
%   log of the pdf at X for a normal distribution with mean MU and 
%   covariance matrix COV. DISCREPANCYTYPE defines which model discrepancy
%   type to use.
%   
%   See also: UQ_INVERSION_LOGNORMPDF

% Initialize
[MuRow,~] = size(mu); % get number of realizations and dimension of mean /Data
[XRow,XCol] = size(x); % get number of realizations and dimension of query /modelEvals
[SRow,SCol] = size(cov); % get dimension of sigma

% switch between discrepancy types
switch lower(discrepancyType)
    case 'scalar'
        % make sure the dimensions are correct
        if SCol~=1
            error('Wrong dimensions in input!')
        end
        % replicate for single value sigma
        if SRow==1
            cov = ones(XRow,XCol)*cov;
        else
            cov = bsxfun(@times, ones(XRow,XCol), cov);
        end
        % evaluate pdf
        pdf = ones(XRow,1);
        for ii = 1:MuRow
            % adapt size of vectors
            muCurr = ones(XRow,1)*mu(ii,:);
            pdf = pdf.*prod(normpdf(x,muCurr,sqrt(cov)),2);
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
        pdf = ones(XRow,1);
        for ii = 1:MuRow
            % adapt size of vectors
            muCurr = mu(ii,:);
            for jj = 1:XRow
                pdf(jj) = pdf(jj).*prod(normpdf(x(jj,:),muCurr,sqrt(cov(jj,:))));
            end
        end
    case 'matrix'
        % make sure the dimensions are correct
        if ~((SCol == SRow) && (SCol==XCol))
            error('Wrong dimensions in input!')
        end
        % evaluate pdf
        pdf = ones(XRow,1);
        for ii = 1:MuRow
            % adapt size of vectors
            muCurr = mu(ii,:);
            pdf = pdf.*mvnpdf(x,muCurr,cov);
        end
end    