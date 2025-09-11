function [Blocks, PVs, History] = uq_test_block_independence(...
    X, alpha, stat, correction, verbose)
% [Blocks, PVs, History] = uq_test_block_independence(...
%     X, alpha, stat, correction, verbose)
%
%     Given a multivariate sample X of a random vector (one column per 
%     random variable), group the components of X into mutually independent 
%     blocks, based on the specified test statistic.
%
%     Two blocks Y and Z are mutually independent if and only if (Y_i, Z_j)
%     are independent for all Y_i in Y, Z_j in Z.
%
%     NOTE: this function does not test for multivariate independence.
%
% INPUT:
% X : n-by-M array
%     Sample of n observations (rows) of each of M variables (columns).
% alpha : float in (0, 1)
%     statistical threshold for the independence tests (e.g., 0.05). 
% (stat : char, optional)
%     Test statistic to be used. 'Kendall', 'Spearman' or 'Pearson' 
%     correlation coefficients between each X_i and X_j.
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
% (verbose : float, optional)
%      Amount of messages to display on screen while the routine runs:
%      0: no messages are displayed
%      1: few important messages are displayed 
%      2: all messages are displayed (may be many!)
%      Default: 1
%
% OUTPUT:
% Blocks : cell of integer arrays
%     Family of all sets of mutually independent random variables into
%     which X has been separated. S{i} is the i-th such set (array of int).
% PVs : d x d array of floats
%     matrix of pairwise test p-values, from which block independence is
%     deduced
% History : structure with the following field
%     * .Tested: matrix reporting which groups of variables were tested 
%        for mutual independence at each step. Each row contains 0s, 1s 
%        and -1s. 0s and 1s represent the two groups of variables that 
%        were tested against each other in that test. -1s represent 
%        variables which were clustered into some group in previous tests.
%     * .Independent: Result of each test in History.Tested. 
    
    % Set defaults
    if nargin < 3, stat = 'Kendall'; end
    if nargin < 4, correction = 'auto'; end
    if nargin < 5, verbose = 1; end;

    % Save X
    M = size(X, 2);

    % Test pair independence and collect pairwise p-values
    PVs = uq_test_pair_independence(X, alpha, stat, correction);
    History.Tested = zeros(0, M);
    History.Independent = [];
    
    if verbose
        fprintf('Perform block independence test\n')
        fprintf('--------------------------------------------------------\n')
    end
    % If all pairs (X_i,X_j) are independent, return one block per variable
    if all(PVs(find(triu(PVs,1)>0)) >= alpha)
        if verbose > 0
            disp('all pairs (Xi, Xj) are independent (Kendall''s tau >= alpha)')
        end
        for ii = 1:M, Blocks{ii}=ii; end
        
    % If all pairs (X_i,X_j) are dependent, return a single block
    elseif all(PVs(find(triu(PVs,1)>0)) < alpha)
        if verbose > 0
            disp('all pairs (Xi, Xj) are dependent (Kendall''s tau < alpha)')
        end
        Blocks = {1:M};   
        
    % Is some but not all pairs (X_i,X_j) are dependent, start algorithm
    else  
        
        % Initialize variables that will change as the algorithm proceeds
        d = M;                 % number of variables not grouped yet 
        vars_in = 1:M;         % variables not grouped yet into a block
        vars_out = {};         % variables already grouped into some block
        ii = 1;                % size of tentative groups (increase from 1)
        Max_size = ceil(d/2);  % max group size still possible 

        while ii <= Max_size 
            
            % Find all partitions of X into two groups of ii and d-ii vars.
            % The two groups are identified by 0s and 1s, respectively.
            indexes = [ones(1,ii) zeros(1,d-ii)]; 
            P = uq_permute_coefficients(indexes); 
            if ii == d/2, 
                P = P(1:size(P, 1)/2, :); 
            end
            P = fliplr(P);
            
            % Run test for all groups of variables (rows jj of P)
            some_removed = 0;
            for jj = 1 : size(P, 1)  % for each row of P
                vars1 = find(P(jj,:)==1); 
                vars2 = find(P(jj,:)==0); 
                vars1_orig = vars_in(vars1);
                vars2_orig = vars_in(vars2);

                % Update History: tested groups
                History.Tested = [History.Tested; -ones(1, M)];
                History.Tested(end, vars1_orig) = 0;
                History.Tested(end, vars2_orig) = 1;

                % Check whether the two groups are mutually independent
                pair_pvs = PVs(vars1_orig, vars2_orig);
                if any(pair_pvs(:) < alpha) % if not, do nothing
                    History.Independent = [History.Independent; 0];
                    if verbose >= 2
                        disp(sprintf(...
                            '(test %s indep %s: skip, not all pairs indep)', ...
                            mat2str(vars1_orig), mat2str(vars2_orig)));
                    end
                else          % otherwise, if all pairs are independent
                    vars_out = [vars_out; vars_in(vars1)];  % add removed vars 
                    some_removed = 1;     % to the list of removed ones 
                    History.Independent = [History.Independent; 1];
                    if verbose > 0
                        disp(sprintf(...
                            '%s indep %s because all pairs indep', ...
                            mat2str(vars1_orig), mat2str(vars2_orig)));
                    end
                    break     % and interrupt iteration for the current P
                end
            end

            if some_removed == 0    % if no independent component was found at this step
                if ii == Max_size       % if end of search reached
                    break;              % stop
                elseif ii < Max_size    % otherwise
                    ii = ii+1;          % go on to next step (size of vars1 -> +1)
                end    
            else                    % otherwise
                vars_in = setdiff(1:M, [vars_out{:}]); % update the remaining vars
                d = length(vars_in);
                Max_size = floor(d/2);
            end
        end
        Blocks = [vars_out; vars_in];  % finally add the last variables to S 
    end

    if verbose > 0
        end_msg = sprintf('-> indep. groups: %s', mat2str(Blocks{1}));
        for ii = 2:length(Blocks)
            end_msg = [end_msg, sprintf(', %s', mat2str(Blocks{ii}))];
        end
        disp(end_msg);
    end

end
