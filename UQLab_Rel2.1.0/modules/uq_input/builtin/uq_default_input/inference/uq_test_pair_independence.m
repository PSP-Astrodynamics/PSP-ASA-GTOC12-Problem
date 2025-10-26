function [pVal, isIndep, threshold, testStat] = uq_test_pair_independence(...
    X, alpha, stat, correction)
% [pVal, result, threshold, testStat] = uq_test_pair_independence(...
%         X, alpha, stat, correction)
%     test statistical independence of all pairs of observation sets in the
%     multivariate sample X. Different statistical corrections for the 
%     number of tests can be specified.
%
% INPUT:
% X : array n-by-M
%     n observations from an M-variate random vector 
% (alpha : float, optional)
%     the test's significance threshold (before statistical correction)
%     Default: 0.05
% (stat : char, optional)
%     the test statistic to be used. Either 'Kendall' (default), 
%     'Spearman', or 'Pearson' correlation coefficient.
%     Default: 'Kendall'
% (correction : char, optional)
%     Statistical correction to use for multiple testing (when M>1). 
%     Either 'none', 'Bonferroni', 'fdr', or 'auto' (default):
%     * 'Bonferroni': sets the significance threshold to alpha/K, where 
%        K = M*(M-1)/2 is the number of statistical tests to perform
%     * 'FDR' : Benjamini-Hochberg's false discovery rate correction.
%       Order the K p-values in increasing order P1...PK, find the largest
%       integer k in {1,...,K} such that Pk<=alpha*k/K, and set the 
%       statistical threshold to alpha*k/K;
%     * 'auto' : uses Bonferroni correction if K<30, FDR otherwise
%
% OUTPUT:
% pVal : array M-by-M
%     the "row" p-values (without statistical correction)
% isIndep : array M-by-M
%     the test results: result(ii,jj)=1 if X(:,ii), X(:,jj) are classified 
%     as independent (null hypothesis accepted), otherwise result(ii,jj)=0
% threshold : double
%     Effective threshold of the test after statistical correction. For K
%     tests (pairs being tested), it is:
%     * alpha if correction is 'none'
%     * alpha/K if correction is 'Bonferroni'
%     * alpha*k/K if correction is 'fdr', where k is the largest integer i
%       such that, ordered all test p-values in ascending order, the i-th
%       p-value is smaller than alpha*i/K.
%       

if nargin < 2, alpha = 0.05; end
if nargin < 3, stat = 'Kendall'; end
if nargin < 4 || isempty(correction), correction = 'auto'; end
    
if alpha<0 || alpha>1
    error('alpha must take value in [0,1]')
end

if ~any(strcmpi(stat, {'Pearson', 'Spearman', 'Kendall'}))
    error('stat must be ''Pearson'', ''Spearman'', or ''Kendall''')
end

[testStat, pVal] = corr(X, 'type', stat, 'tail', 'both');
pVal = pVal - diag(diag(pVal));

[n, M] = size(X);
nTests = M*(M-1)/2;

% Set the effective statistical threshold of the test depending on the
% statistical correction used
if strcmpi(correction, 'none') || ...
        (strcmpi(correction, 'auto') && nTests < 30)
    % no correction: set the significance threshold to alpha
    threshold = alpha;
elseif strcmpi(correction, 'Bonferroni') 
    % Bonferroni correction: set the significance threshold to alpha/nTests
    threshold = alpha/nTests;
elseif strcmpi(correction, 'fdr') || ...
        (strcmpi(correction, 'auto') && nTests >= 30)
    % Collect the test p-values of all pairs in a vector, and sort them
    pValVector = [];
    for ii=1:M-1
        pValVector = [pValVector, pVal(ii,ii+1:end)];
    end
    pValSorted = sort(pValVector);
    % Find the largest k such that pk <= alpha*k/nTests
    thresholdVector = alpha*(1:nTests)/nTests;
    k = max([0, find(pValSorted <= thresholdVector)]);
    % FDR correction: set the significance threshold to alpha*k/nTests
    threshold = alpha*max(k,1)/nTests;
else
    error(['correction must be one of: ''none'', ''Bonferroni'',' ...
           ' ''fdr'', or ''auto'''])
end

isIndep = (pVal > threshold);
