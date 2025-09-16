function logL = uq_inversion_test_func_CustomLogLikelihood(params,data,A)
% UQ_INVERSION_TEST_FUNC_CUSTOMLOGLIKELIHOOD supplies a custom
%   logLikelihood handle for the Bayesian inversion module self tests.
%
%   See also: UQ_SELFTEST_UQ_INVERSION

%split params into model and error params
modelParams = params(:,1:8);
errorParams = params(:,9:end);

%initialize
sigma = errorParams(:,1); %error standard deviation 
psi = errorParams(:,2); %correlation length
nData = size(data,2);

%number of parameters passed to likelihood function
nChains = size(modelParams,1);

%evaluate model
modelRuns = modelParams*A;

%correlation options
CorrOptions.Type = 'Ellipsoidal';
CorrOptions.Family = 'Matern-5_2';
CorrOptions.Isotropic = false;
CorrOptions.Nugget = 0;

%loop through chains
logL = zeros(nChains,1);
for ii = 1:nChains
    %get the sigma matrix
    sigmaCurr = sigma(ii)*ones(1,nData);
    D = diag(sigmaCurr);
    %get correlation & covariance matrix
    R = uq_eval_Kernel((1:nData).',(1:nData).', psi(ii), CorrOptions);
    logLikeli = 0;
    C = D*R*D;
    L = chol(C,'lower');
    Linv = inv(L);
    
    %compute inverse of covariance matrix and log determinante
    Cinv = Linv.'*Linv;
    logCdet = 2*trace(log(L));
    % evaluate log likelihood
    logLikeli = logLikeli - 1/2*logCdet - 1/2*diag((data...
        -modelRuns(ii,:))*Cinv*(data-modelRuns(ii,:)).');
    %assign to logL vector
    logL(ii) = logLikeli;
end

