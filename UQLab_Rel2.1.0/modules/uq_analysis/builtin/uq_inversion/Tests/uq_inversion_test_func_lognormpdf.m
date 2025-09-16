function success = uq_inversion_test_func_lognormpdf(level)
% UQ_INVERSION_TEST_FUNC_LOGNORMPDF verifies the computation of the
%   logarithm of Gaussian (normal) PDF.

%% Start UQLab
uqlab('-nosplash')

if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| ',mfilename,'...\n']);

success = false;

%% Validation test values
x = [-2.0453 0.1221; -1.8727 1.6894; -0.8199 2.9823; 0.0226 -0.7565;...
    -0.5328 -0.1234; 1.6894 0.1221; -0.8199 0.0226; 2.9823 -2.0453;...
     0 0; 1.0000 1.0000];
mu = [0 1; 2 1; 3 2; -0.5 -1; -1 0.85];
covScalar = 2;
covRow = [1 2];
covMatrix = [1 0.75; 0.75 1];

%% Compute Normal PDF values
try
  logPDFValScalarRef = logNormPDF(x, mu, covScalar, 'scalar');
  logPDFValRowRef = logNormPDF(x, mu, covRow, 'row');
  logPDFValMatrixRef = logNormPDF(x, mu, covMatrix, 'matrix');
  logPDFValScalar = uq_inversion_lognormpdf(x, mu, covScalar, 'scalar');
  logPDFValRow = uq_inversion_lognormpdf(x, mu, covRow, 'row');
  logPDFValMatrix = uq_inversion_lognormpdf(x, mu, covMatrix, 'matrix');
catch
  return;
end

%% Verify computed values
if all(abs(logPDFValScalar - logPDFValScalarRef) < 1e-6) &&...
    all(abs(logPDFValRow - logPDFValRowRef) < 1e-6) &&...
    all(abs(logPDFValMatrix - logPDFValMatrixRef) < 1e-6)
    success = true;
else
    success = false;
end

function logPDF = logNormPDF(x, mu, cov, discrepancyType)
% LOGNORMPDF returns the logarithm of multivariate Gaussian pdf.
%   The function distinguishes between different discrepancy types. 

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
        if SRow==1; cov = ones(XRow,XCol)*cov; end
        % evaluate pdf
        logPDF = zeros(XRow,1);
        for ii = 1:MuRow
            % adapt size of vectors
            muCurr = ones(XRow,1)*mu(ii,:);
            logPDF = logPDF + sum(log(normpdf(x,muCurr,sqrt(cov))),2);
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
        logPDF = zeros(XRow,1);
        for ii = 1:MuRow
            % adapt size of vectors
            muCurr = mu(ii,:);
            for jj = 1:XRow
                logPDF(jj) = logPDF(jj) + sum(log(normpdf(x(jj,:),muCurr,sqrt(cov(jj,:)))));
            end
        end
    case 'matrix'
        % make sure the dimensions are correct
        if ~((SCol == SRow) && (SCol==XCol))
            error('Wrong dimensions in input!')
        end
        % evaluate pdf
        logPDF = zeros(XRow,1);
        for ii = 1:MuRow
            % adapt size of vectors
            muCurr = mu(ii,:);
            logPDF = logPDF + log(mvnpdf(x,muCurr,cov));
        end
end

end

end