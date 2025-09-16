function Bootstrap = uq_OLS_bootstrap(Psi,Y, options)
% BOOTSTRAP = UQ_OLS_BOOTSTRAP(PSI,Y,OPTIONS): return the bootstrap
%     estimates of the OLS regression problem with regressors PSI and
%     responses Y. OPTIONS. 'Replications' contains the number of Bootstrap
%     replications to calculate.
%
% See also: uq_PCE_OLS_regression

%% Read the options
% Number of bootstrap resaplings
if isfield(options, 'Replications')
    B = options.Replications;
else
    B = 100;
end

% Perform the actual resampling
resIDX = uq_bootstrap(size(Y,1),B);

% Initialize the array of OLS coefficients
BArray = zeros(size(Psi, 2), B);

% Now run the OLS game
for ii = 1:B
    BY = Y(resIDX(ii,:));
    BPsi = Psi(resIDX(ii,:),:);
    ols_results = uq_PCE_OLS_regression(BPsi, BY);
    BArray(:,ii) = ols_results.coefficients;
end

% return the outputs
Bootstrap.resIDX = resIDX;
Bootstrap.BArray = BArray;
Bootstrap.Var = var(BArray, [],2);
Bootstrap.Mean = mean(BArray,2);